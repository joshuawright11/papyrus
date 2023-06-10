// swift-tools-version:5.9
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "papyrus",
    platforms: [
      .iOS("13.0"),
      .macOS("10.15")
    ],
    products: [
        .executable(name: "PapyrusDemo", targets: ["PapyrusDemo"]),
        .library(name: "Papyrus", targets: ["Papyrus"]),
    ],
    dependencies: [
      .package(
        url: "https://github.com/apple/swift-syntax.git",
        branch: "main"
      ),
    ],
    targets: [
        .executableTarget(name: "PapyrusDemo", dependencies: ["Papyrus"], path: "PapyrusDemo"),
        .target(name: "Papyrus", dependencies: ["PapyrusPlugin"], path: "Papyrus"),
        .macro(name: "PapyrusPlugin",
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
        .testTarget(name: "PapyrusTests", dependencies: ["Papyrus"], path: "PapyrusTests"),
    ]
)
