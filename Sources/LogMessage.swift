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
		
		var dateSecondsStr = String(date.timeIntervalSince1970)
		/* If the timestamp is exactly at the epoch, we encode 0.
		 * In theory we could check only if the str is exactly "0.0" (even "0"), but  */
		if (dateSecondsStr.filter{ $0 != "0" && $0 != "." }).isEmpty {
			try container.encode("0")
			
		/* Check if we have a decimal in the string representation of the timestamp.
		 * In theory this should _always_ be the case as Swift always put the decimal separator when encoding a Double. */
		} else if let decimalSeparatorIndex = dateSecondsStr.firstIndex(of: ".") {
			let nCharsAfterDecimal = dateSecondsStr.distance(from: decimalSeparatorIndex, to: dateSecondsStr.endIndex) - 1
			dateSecondsStr.remove(at: decimalSeparatorIndex)
			if nCharsAfterDecimal > 9 {
				/* Let’s remove the additional decimals we have. */
				dateSecondsStr.removeLast(nCharsAfterDecimal - 9)
			} else if nCharsAfterDecimal < 9 {
				/* Let’s add some 0s to have the correct number of decimals. */
				dateSecondsStr.append(String(repeating: "0", count: 9 - nCharsAfterDecimal))
			}
			try container.encode(dateSecondsStr)
			
		} else {
			try container.encode(dateSecondsStr + "000000000")
		}
		
		try container.encode(message)
		
		if !metadata.isEmpty {
			try container.encode(metadata)
		}
	}
	
}
