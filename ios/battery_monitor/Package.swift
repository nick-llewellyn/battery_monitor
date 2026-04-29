// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to
// build this package.
//
// SPM manifest for the iOS plugin. Mirrors `ios/battery_monitor.podspec`
// (iOS 13.0, Swift 5.0+); both build paths consume the same sources under
// `Sources/battery_monitor/`. Flutter's SPM integration auto-links the
// Flutter framework, so no explicit FlutterFramework dependency is declared
// here -- declaring it would raise the package's Flutter floor to 3.41.0
// and break the 3.35.0 floor pinned in pubspec.yaml.

import PackageDescription

let package = Package(
    name: "battery_monitor",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        // SPM library names cannot contain `_`; pub package name -> `-`.
        .library(name: "battery-monitor", targets: ["battery_monitor"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "battery_monitor",
            dependencies: [],
            resources: []
        )
    ]
)
