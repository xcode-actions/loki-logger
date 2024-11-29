// swift-tools-version:5.3
import PackageDescription


let package = Package(
	name: "loki-logger",
	platforms: [
		.macOS(.v11),
		.tvOS(.v14),
		.iOS(.v14),
		.watchOS(.v7)
	],
	products: [
		.library(name: "LokiLogger", targets: ["LokiLogger"])
	],
	dependencies: {
		var ret = [Package.Dependency]()
		ret.append(.package(url: "https://github.com/apple/swift-log.git",             from: "1.5.1"))
		ret.append(.package(url: "https://github.com/Frizlab/URLRequestOperation.git", from: "2.0.0-alpha.16"))
		return ret
	}(),
	targets: [
		.target(name: "LokiLogger", dependencies: {
			var ret = [Target.Dependency]()
			ret.append(.product(name: "Logging",             package: "swift-log"))
			ret.append(.product(name: "URLRequestOperation", package: "URLRequestOperation"))
			return ret
		}(), path: "Sources"),
		.testTarget(name: "LokiLoggerTests", dependencies: ["LokiLogger"], path: "Tests")
	]
)
