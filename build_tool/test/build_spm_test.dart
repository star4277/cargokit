import 'package:build_tool/src/artifacts_provider.dart';
import 'package:build_tool/src/build_spm.dart';
import 'package:build_tool/src/target.dart';
import 'package:test/test.dart';

void main() {
  test('groups all Apple targets into XCFramework platform slices', () {
    final groups = Target.darwinXcframeworkTargetGroups();

    expect(groups.keys, ['iphoneos', 'iphonesimulator', 'macosx']);
    expect(groups['iphoneos']!.map((target) => target.rust), [
      'aarch64-apple-ios',
    ]);
    expect(groups['iphonesimulator']!.map((target) => target.rust), [
      'aarch64-apple-ios-sim',
      'x86_64-apple-ios',
    ]);
    expect(groups['macosx']!.map((target) => target.rust), [
      'x86_64-apple-darwin',
      'aarch64-apple-darwin',
    ]);
  });

  test('creates xcodebuild arguments for each platform library', () {
    expect(
      createXcframeworkArguments(
        libraries: ['/tmp/ios.a', '/tmp/simulator.a'],
        output: '/tmp/Rust.xcframework',
      ),
      [
        '-create-xcframework',
        '-library',
        '/tmp/ios.a',
        '-library',
        '/tmp/simulator.a',
        '-output',
        '/tmp/Rust.xcframework',
      ],
    );
  });

  test('uses Cargo library names for packages containing hyphens', () {
    expect(
      getArtifactNames(
        target: Target.forRustTriple('aarch64-apple-ios')!,
        libraryName: 'rust-library',
        remote: false,
      ),
      ['librust_library.a'],
    );
  });
}
