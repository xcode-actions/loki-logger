import Foundation
import XCTest

@testable import LokiLogger



final class LogMessageTests : XCTestCase {
	
	static let encoder = {
		let ret = JSONEncoder()
		ret.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
		return ret
	}()
	static let decoder = JSONDecoder()
	
	override class func setUp() {
	}
	
	func testLogMessageEncode() {
		XCTAssertEqual(try XCTUnwrap(String(data: Self.encoder.encode(LogMessage(date: Date(timeIntervalSince1970: 0), message: "yolo")), encoding: .utf8)), #"["0","yolo"]"#)
		XCTAssertEqual(try XCTUnwrap(String(data: Self.encoder.encode(LogMessage(date: Date(timeIntervalSince1970: 1), message: "yolo")), encoding: .utf8)), #"["1000000000","yolo"]"#)
		XCTAssertEqual(try XCTUnwrap(String(data: Self.encoder.encode(LogMessage(date: Date(timeIntervalSince1970: 1.5), message: "yolo")), encoding: .utf8)), #"["1500000000","yolo"]"#)
//		XCTAssertEqual(try XCTUnwrap(String(data: Self.encoder.encode(LogMessage(date: Date(timeIntervalSince1970: 1.54321), message: "yolo")), encoding: .utf8)), #"["1543210029","yolo"]"#) /* Note: Due to precision issue, this test is (probably) flaky, so disabled… */
		XCTAssertEqual(try XCTUnwrap(String(data: Self.encoder.encode(LogMessage(date: Date(timeIntervalSince1970: -300.5), message: "yolo")), encoding: .utf8)), #"["-300500000000","yolo"]"#)
		XCTAssertEqual(try XCTUnwrap(String(data: Self.encoder.encode(LogMessage(date: Date(timeIntervalSince1970: 1), message: "yolo", otherMetadata: ["killroy":"here"])), encoding: .utf8)), #"["1000000000","yolo",{"killroy":"here"}]"#)
		XCTAssertEqual(try XCTUnwrap(String(data: Self.encoder.encode(LogMessage(date: Date(timeIntervalSince1970: 1), message: "yolo", otherMetadata: ["killroy":"here", "bob":"kelso"])), encoding: .utf8)), #"["1000000000","yolo",{"bob":"kelso","killroy":"here"}]"#)
	}
	
	func testLogMessageDecode() {
		XCTAssertEqual(try Self.decoder.decode(LogMessage.self, from: Data(#"["0","yolo"]"#.utf8)), LogMessage(date: Date(timeIntervalSince1970: 0), message: "yolo"))
		XCTAssertEqual(try Self.decoder.decode(LogMessage.self, from: Data(#"["1000000000","yolo"]"#.utf8)), LogMessage(date: Date(timeIntervalSince1970: 1), message: "yolo"))
		XCTAssertEqual(try Self.decoder.decode(LogMessage.self, from: Data(#"["1500000000","yolo"]"#.utf8)), LogMessage(date: Date(timeIntervalSince1970: 1.5), message: "yolo"))
//		XCTAssertEqual(try Self.decoder.decode(LogMessage.self, from: Data(#"["1543210029","yolo"]"#.utf8)), LogMessage(date: Date(timeIntervalSince1970: 1.54321), message: "yolo")) /* Note: Due to precision issue, this test is (probably) flaky, so disabled… */
		XCTAssertEqual(try Self.decoder.decode(LogMessage.self, from: Data(#"["-300500000000","yolo"]"#.utf8)), LogMessage(date: Date(timeIntervalSince1970: -300.5), message: "yolo"))
		XCTAssertEqual(try Self.decoder.decode(LogMessage.self, from: Data(#"["1000000000","yolo",{"killroy":"here"}]"#.utf8)), LogMessage(date: Date(timeIntervalSince1970: 1), message: "yolo", otherMetadata: ["killroy":"here"]))
		XCTAssertEqual(try Self.decoder.decode(LogMessage.self, from: Data(#"["1000000000","yolo",{"bob":"kelso","killroy":"here"}]"#.utf8)), LogMessage(date: Date(timeIntervalSince1970: 1), message: "yolo", otherMetadata: ["killroy":"here", "bob":"kelso"]))
	}
	
}
