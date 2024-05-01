import Foundation

import Logging



public struct LogChunk : Hashable, Codable, Sendable {
	
	/* These are “known” labels in Loki. */
	public static let labelKeyLevel = "level"
	public static let labelKeyServiceName = "service_name"
	
	public var labels: [String: String]
	/* Known labels. */
	public var levelStr:    String? {labels[Self.labelKeyLevel]}
	public var serviceName: String? {labels[Self.labelKeyServiceName]}
	/* Convenience to access the level as a Logger.Level. */
	public var level: Logger.Level? {levelStr.flatMap(Logger.Level.init(rawValue:))}
	
	public var messages: [LogMessage]
	
	public init(level: Logger.Level?, serviceName: String?, otherLabels: [String: String] = [:], messages: [LogMessage]) {
		self.messages = messages
		
		self.labels = otherLabels
		if let level       {labels[Self.labelKeyLevel] = level.rawValue}
		if let serviceName {labels[Self.labelKeyServiceName] = serviceName}
	}
	
	private enum CodingKeys : String, CodingKey {
		case labels = "stream"
		case messages = "values"
	}
	
}
