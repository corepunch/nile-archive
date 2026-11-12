// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HomescapesMatch3Lab",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "HomescapesLab", targets: ["HomescapesLab"])],
    targets: [
        .target(name: "Match3LabCore"),
        .executableTarget(name: "HomescapesLab", dependencies: ["Match3LabCore"]),
        .testTarget(name: "Match3LabCoreTests", dependencies: ["Match3LabCore"])
    ]
)
