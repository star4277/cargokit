# Swift Package Manager

CargoKit supports Flutter's Swift Package Manager integration without a
Flutter build hook. Generate the Rust XCFramework before resolving or building
the Swift package, then declare it as a local SwiftPM binary target.

Run this from the Flutter plugin directory on macOS:

```sh
path/to/cargokit/build_spm.sh rust ios/YourPlugin release
```

This writes `ios/YourPlugin/<cargo-library-name>.xcframework`. The Rust crate
must include `cdylib` in its `crate-type`; CargoKit builds the iOS device, iOS
simulator, and macOS dynamic framework slices, fixes each framework's install
name for embedding, and combines them with `xcodebuild -create-xcframework`.
The command replaces an existing XCFramework with the same name. Cargo library
names use underscores when the package name contains hyphens.

Keep the generated XCFramework next to `Package.swift` and use a binary target
in the package manifest. Replace the placeholder names and the XCFramework
file name with the Cargo library name:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourPlugin",
    platforms: [.iOS(.v13)],
    products: [.library(name: "YourPlugin", targets: ["YourPlugin"])],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .binaryTarget(
            name: "RustLibrary",
            path: "your_cargo_package.xcframework"
        ),
        .target(
            name: "YourPlugin",
            dependencies: [
                "RustLibrary",
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ]
        ),
    ]
)
```

Add a source file such as `ios/YourPlugin/Sources/YourPlugin/Empty.swift` so
the Swift target exists:

```swift
// The Rust dynamic framework is linked through the binary target.
```

The XCFramework is an explicit generated input, like the final native artifact
of the CocoaPods build path. SwiftPM does not run CargoKit during package
resolution or Flutter builds.
