# Swift Package Manager

CargoKit supports Flutter's Swift Package Manager integration without CocoaPods
or Flutter build hooks. A SwiftPM build-tool plugin invokes CargoKit during the
normal Xcode build and a companion C target links the resulting static archive.

`build_spm.sh` is the plugin entry point. Applications should not run it as a
pre-build step. The plugin calls it with:

```sh
cargokit/build_spm.sh <cargo-manifest-dir> <output-file> <plugin-work-dir>
```

Xcode supplies `PLATFORM_NAME`, `ARCHS`, and `CONFIGURATION`. CargoKit builds
only those Rust targets and combines their `staticlib` artifacts into the
requested output file. The Rust crate must therefore include `staticlib` in its
`crate-type`.

The Swift package should keep CargoKit inside the package root so the plugin can
execute it under SwiftPM's sandbox:

```text
Package.swift
Sources/
Plugins/CargoKitPlugin/plugin.swift
cargokit/build_spm.sh
cargokit/run_build_tool.sh
```

The package manifest adds the build-tool plugin to a C linker target. That
target uses `-force_load` for the archive so Rust's exported C ABI symbols are
retained in the final Flutter application. The generated integration should
give every package and Apple platform a distinct archive path to avoid clashes
between projects and between device and simulator builds.

SwiftPM build-tool plugins cannot embed and sign a dynamic framework in the
application's Frameworks directory. CargoKit therefore uses static linkage for
this automatic build path.
