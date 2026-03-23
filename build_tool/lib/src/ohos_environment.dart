import 'dart:io';

import 'package:path/path.dart' as path;
import 'target.dart';

class OhosEnvironment {
  OhosEnvironment(
      {required this.targetTempDir,
      required this.ohosSdkHome,
      required this.target});

  final String targetTempDir;
  final String ohosSdkHome;
  final Target target;

  Future<Map<String, String>> buildEnvironment() async {
    final exe = Platform.isWindows ? ".exe" : "";
    final clangPath = path.join(ohosSdkHome, 'llvm', 'bin', 'clang$exe');
    final sysroot = path.join(ohosSdkHome, 'sysroot');
    String clangTarget;
    switch (target.ohos) {
      case 'arm64-v8a':
        clangTarget = 'aarch64-linux-ohos';
        break;
      case 'armeabi-v7a':
        clangTarget = 'arm-linux-ohos';
        break;
      case 'x86_64':
        clangTarget = 'x86_64-linux-ohos';
        break;
      default:
        clangTarget = 'aarch64-linux-ohos';
    }
    final targetEnvName = target.rust.toUpperCase().replaceAll('-', '_');
    final linkerEnvVar = 'CARGO_TARGET_${targetEnvName}_LINKER';
    final rustFlagsEnvVar = 'CARGO_TARGET_${targetEnvName}_RUSTFLAGS';
    final rustFlags = '-C link-arg=--target=$clangTarget '
        '-C link-arg=-fuse-ld=lld '
        '-C link-arg=--sysroot=$sysroot '
        '-C link-arg=-D__MUSL__';
    return {
      rustFlagsEnvVar: rustFlags,
      linkerEnvVar: clangPath,
      'CC_${target.rust}': clangPath,
      'AR_${target.rust}': path.join(ohosSdkHome, "llvm", "bin", "llvm-ar$exe")
    };
  }
}
