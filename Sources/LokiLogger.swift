import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


import Logging
import URLRequestOperation



public struct LokiLogger : LogHandler {
	
	public var logLevel: Logger.Level = .info
	
	public let label: String
	public var metadata: Logger.Metadata = [:] {
		didSet {flatMetadataCache = flatMetadataDictionary(metadata)}
	}
	public var metadataProvider: Logger.MetadataProvider?
	
	public let lokiServerIngestionURL: URL
	
	public init(lokiServerURL: URL, label: String, metadataProvider: Logger.MetadataProvider? = LoggingSystem.metadataProvider) {
		self.init(
			lokiServerIngestionURL: lokiServerURL.appendingPathComponent("v1/push"),
			label: label, metadataProvider: metadataProvider
		)
	}
	
	public init(lokiServerIngestionURL: URL, label: String, metadataProvider: Logger.MetadataProvider? = LoggingSystem.metadataProvider) {
		self.lokiServerIngestionURL = lokiServerIngestionURL
		self.label = label
		self.metadataProvider = metadataProvider
	}
	
	public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
		get {metadata[metadataKey]}
		set {metadata[metadataKey] = newValue}
	}
	
	public func log(level: Logger.Level, message: Logger.Message, metadata logMetadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
		let effectiveFlatMetadata: [String: String]
		if let m = mergedMetadata(with: logMetadata) {effectiveFlatMetadata = flatMetadataDictionary(m)}
		else                                         {effectiveFlatMetadata = flatMetadataCache}
		
		/* TODO: Allow some metadata to go in the chunk labels. */
		let chunk = LogChunk(level: level, serviceName: label, otherLabels: [:], messages: [
			.init(message: message.description, label: label, source: source, file: file, function: function, line: line, otherMetadata: effectiveFlatMetadata)
		])
		var urlRequest = URLRequest(url: lokiServerIngestionURL)
		urlRequest.httpMethod = "POST"
		urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
		do    {urlRequest.httpBody = try Self.encoder.encode(["streams": [chunk]])}
		catch {
			urlRequest.httpBody = Data((
				#"{"streams":[{"# +
					#""stream":{"service_name":"\#(label.safifyForJSON())","level":"\#(level.rawValue.safifyForJSON())"},"# +
					#""values":[["# +
						#""\#(Date().lokiTimestamp().safifyForJSON())","# +
						#""MANGLED LOG MESSAGE (see LokiLogger doc) -- \#(message.description.safifyForJSON())","# +
						#"{"# +
							#""LokiLogger_LogInfo":"Original metadata removed (see LokiLogger doc)","# +
							#""LokiLogger_LogError":"\#(String(describing: error).safifyForJSON())""# +
						#"}"# +
					#"]]"# +
				#"}]}"#
			).utf8)
		}
		/* TODO: Merge the chunks that are pending and have the same stream. */
		let op = URLRequestDataOperation.forData(
			urlRequest: urlRequest, session: Self.session,
			acceptableStatusCodes: Set(200..<400),
			retryableStatusCodes: [503],
			retryProviders: [NetworkErrorRetryProvider(
				maximumNumberOfRetries: 13,
				alsoRetryNonIdempotentRequests: true,
				allowOtherSuccessObserver: true, allowReachabilityObserver: false
			)]
		)
		Self.queue.addOperation(op)
	}
	
	private static let queue = {
		let ret = OperationQueue()
		ret.maxConcurrentOperationCount = 7
		return ret
	}()
	private static let encoder = {
		let ret = JSONEncoder()
		ret.outputFormatting = [.withoutEscapingSlashes]
		return ret
	}()
	private static let session = URLSession(configuration: .ephemeral)
	
	private var flatMetadataCache = [String: String]()
	
}


/* Metadata handling. */
private extension LokiLogger {
	
	/**
	 Merge the logger’s metadata, the provider’s metadata and the given explicit metadata and return the new metadata.
	 If the provider’s metadata and the explicit metadata are `nil`, returns `nil` to signify the current `flatMetadataCache` can be used. */
	func mergedMetadata(with explicit: Logger.Metadata?) -> Logger.Metadata? {
		var metadata = metadata
		let provided = metadataProvider?.get() ?? [:]
		
		guard !provided.isEmpty || !((explicit ?? [:]).isEmpty) else {
			/* All per-log-statement values are empty or not set: we return nil. */
			return nil
		}
		
		if !provided.isEmpty {
			metadata.merge(provided, uniquingKeysWith: { _, provided in provided })
		}
		if let explicit = explicit, !explicit.isEmpty {
			metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })
		}
		return metadata
	}
	
	func flatMetadataDictionary(_ metadata: Logger.Metadata) -> [String: String] {
		return metadata.mapValues{ prettyMetadataValue($0, showQuotes: false) }
	}
	
	func flatMetadataArray(_ metadata: Logger.Metadata) -> [String] {
		return metadata.lazy.sorted{ $0.key < $1.key }.map{ keyVal in
			let (key, val) = keyVal
			return (
				key.processForLogging(escapingMode: .escapeScalars(asASCII: true, octothorpLevel: 1), newLineProcessing: .escape).string +
				": " +
				prettyMetadataValue(val, showQuotes: true)
			)
		}
	}
	
	func prettyMetadataValue(_ v: Logger.MetadataValue, showQuotes: Bool) -> String {
		/* We return basically v.description, but dictionary keys are sorted. */
		return switch v {
			case .string(let str):      str.processForLogging(escapingMode: .escapeScalars(asASCII: false, octothorpLevel: nil, showQuotes: showQuotes), newLineProcessing: .escape).string
			case .array(let array):     #"["# + array.map{ prettyMetadataValue($0, showQuotes: true) }.joined(separator: ", ") + #"]"#
			case .dictionary(let dict): #"["# +              flatMetadataArray(dict)                  .joined(separator: ", ") + #"]"#
			case .stringConvertible(let c): prettyMetadataValue(.string(c.description), showQuotes: showQuotes)
		}
	}
	
}
