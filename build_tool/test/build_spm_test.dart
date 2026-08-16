import 'package:build_tool/src/build_spm.dart';
import 'package:test/test.dart';

void main() {
  test('resolves targets for the current Xcode platform and architectures', () {
    final targets = darwinTargetsForBuild(
      platformName: 'iphonesimulator',
      architectures: ['arm64', 'x86_64'],
    );

    expect(targets.map((target) => target.rust), [
      'aarch64-apple-ios-sim',
      'x86_64-apple-ios',
    ]);
  });

  test('rejects an unsupported Xcode platform and architecture', () {
    expect(
      () => darwinTargetsForBuild(
        platformName: 'iphoneos',
        architectures: ['x86_64'],
      ),
      throwsStateError,
    );
  });

  test('creates lipo arguments for a static archive', () {
    expect(
      createLipoArguments(
        libraries: ['/tmp/arm64.a', '/tmp/x86_64.a'],
        output: '/tmp/libcrate.a',
      ),
      [
        '-create',
        '/tmp/arm64.a',
        '/tmp/x86_64.a',
        '-output',
        '/tmp/libcrate.a',
      ],
    );
  });
}
