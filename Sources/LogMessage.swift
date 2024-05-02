import Foundation



public struct LogMessage : Hashable, Codable, Sendable {
	
	/* These are the keys we use in the structured metadata by default.
	 * These are not “known” keys in general in Loki. */
	public static let metadataKeyLabel    = "_label"
	public static let metadataKeySource   = "_source"
	public static let metadataKeyFile     = "_file"
	public static let metadataKeyFunction = "_function"
	public static let metadataKeyLine     = "_line"
	
	public var date: Date
	public var message: String
	
	public var metadata: [String: String]
	
	/* The values in otherMetadata will be overridden for the label, source, file, function and line metadata. */
	public init(date: Date = Date(), message: String, label: String, source: String, file: String, function: String, line: UInt, otherMetadata: [String: String] = [:]) {
		self.date = date
		self.message = message
		self.metadata = otherMetadata
		metadata[Self.metadataKeyLabel]    = label
		metadata[Self.metadataKeySource]   = source
		metadata[Self.metadataKeyFile]     = file
		metadata[Self.metadataKeyFunction] = function
		metadata[Self.metadataKeyLine]     = String(line)
	}
	
	public init(date: Date = Date(), message: String, otherMetadata: [String: String] = [:]) {
		self.date = date
		self.message = message
		self.metadata = otherMetadata
	}
	
	public init(from decoder: any Decoder) throws {
		var container = try decoder.unkeyedContainer()
		var dateStr = try container.decode(String.self)
		self.message = try container.decode(String.self)
		if !container.isAtEnd {self.metadata = try container.decode([String: String].self)}
		else                  {self.metadata = [:]}
		
		/* Parse the date.
		 * We insert a decimal separator directly in the string to avoid precision errors. */
		let hasSign = (dateStr.first == "+" || dateStr.first == "-")
		let nChars = dateStr.count - (hasSign ? 1 : 0); assert(nChars > 0)
		let nZerosToInsert = max(0, 10 - nChars)
		for _ in 0..<nZerosToInsert {
			dateStr.insert("0", at: dateStr.index(dateStr.startIndex, offsetBy: hasSign ? 1 : 0))
		}
		dateStr.insert(".", at: dateStr.index(dateStr.endIndex, offsetBy: -9))
		guard let epochInNanoseconds = TimeInterval(dateStr) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "First element of the array must be a valid epoch timestamp in nanoseconds encoded as a String.")
		}
		self.date = Date(timeIntervalSince1970: epochInNanoseconds)
	}
	
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.unkeyedContainer()
		
		try container.encode(date.lokiTimestamp())
		try container.encode(message)
		
		if !metadata.isEmpty {
			try container.encode(Dictionary(metadata.map{ ($0.key.sanitizedForLokiKey(), $0.value) }, uniquingKeysWith: { old, new in new }) )
		}
	}
	
}
