// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Papyrus",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .library(name: "Papyrus", targets: ["Papyrus"]),
    ],
    targets: [
        .target(name: "Papyrus", dependencies: []),
        .testTarget(name: "PapyrusTests", dependencies: ["Papyrus"]),
    ]
)
