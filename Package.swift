// swift-tools-version:5.9
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "papyrus",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15"),
        .tvOS("13.0")
    ],
    products: [
        .executable(name: "Example", targets: ["Example"]),
        .library(name: "Papyrus", targets: ["Papyrus"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", from: "510.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.1.0"),
    ],
    targets: [

        // MARK: Demo

        .executableTarget(
            name: "Example",
            dependencies: [
                "Papyrus"
            ],
            path: "Example"
        ),

        // MARK: Library

        .target(
            name: "Papyrus",
            dependencies: [
                "PapyrusPlugin"
            ],
            path: "Papyrus/Sources",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PapyrusTests",
            dependencies: [
                "Papyrus"
            ],
            path: "Papyrus/Tests"
        ),

        // MARK: Plugin

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
            path: "PapyrusPlugin/Sources"
        ),
        .testTarget(
            name: "PapyrusPluginTests",
            dependencies: [
                "PapyrusPlugin",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ],
            path: "PapyrusPlugin/Tests"
        ),
    ]
)
