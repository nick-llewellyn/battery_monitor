// swift-tools-version: 5.9
// The swift-tools-version above declares the minimum SwiftPM toolchain
// required to PARSE this manifest (Swift 5.9, ships with Xcode 15+). It
// is distinct from the Swift LANGUAGE version the sources are written
// in, which is set to 5.0 in `ios/battery_monitor.podspec`
// (`s.swift_version`). The 5.9 floor matches Flutter's own first-party
// plugins (path_provider_foundation, shared_preferences_foundation) and
// is implied by Flutter's SPM integration, which already requires
// Xcode 15+.
//
// SPM manifest for the iOS plugin. Mirrors `ios/battery_monitor.podspec`
// (iOS 13.0); both build paths consume the same sources under
// `Sources/battery_monitor/`. Flutter's SPM integration auto-links the
// Flutter framework, so no explicit FlutterFramework dependency is
// declared here -- declaring it would raise the package's Flutter floor
// to 3.41.0 and break the 3.35.0 floor pinned in pubspec.yaml.

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
