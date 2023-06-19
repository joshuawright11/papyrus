// swift-tools-version:5.9
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "papyrus",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15"),
    ],
    products: [
        .executable(name: "PapyrusDemo", targets: ["PapyrusDemo"]),
        .library(name: "Papyrus", targets: ["Papyrus"]),
        .library(name: "PapyrusCore", targets: ["PapyrusCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "main"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.7.1")),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "PapyrusDemo",
            dependencies: ["Papyrus"],
            path: "Demo"
        ),
        .target(
            name: "PapyrusAsyncHTTPClient",
            dependencies: [
                .byName(name: "PapyrusCore"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ],
            path: "PapyrusAsyncHTTPClient"
        ),
        .target(
            name: "Papyrus",
            dependencies: [
                .byName(name: "PapyrusCore"),
                .product(name: "Alamofire", package: "Alamofire"),
            ],
            path: "Papyrus"
        ),
        .target(
            name: "PapyrusCore",
            dependencies: [
                .byName(name: "PapyrusPlugin"),
            ],
            path: "PapyrusCore"
        ),
        .macro(
            name: "PapyrusPlugin",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "PapyrusPlugin"
        ),
        .testTarget(
            name: "PapyrusTests",
            dependencies: ["Papyrus"],
            path: "PapyrusTests"
        ),
    ]
)
