import 'dart:io';

import 'package:path/path.dart' as path;

import 'artifacts_provider.dart';
import 'builder.dart';
import 'environment.dart';
import 'options.dart';
import 'target.dart';
import 'util.dart';

List<Target> darwinTargetsForBuild({
  required String platformName,
  required Iterable<String> architectures,
}) {
  return architectures.map((architecture) {
    final target = Target.forDarwin(
      platformName: platformName,
      darwinAarch: architecture,
    );
    if (target == null) {
      throw StateError(
        'Unknown Darwin target or platform: $architecture, $platformName',
      );
    }
    return target;
  }).toList(growable: false);
}

List<String> createLipoArguments({
  required Iterable<String> libraries,
  required String output,
}) {
  return ['-create', ...libraries, '-output', output];
}

class BuildSpm {
  BuildSpm({required this.userOptions});

  final CargokitUserOptions userOptions;

  Future<void> build() async {
    if (!Platform.isMacOS) {
      throw UnsupportedError('SwiftPM Apple builds require macOS.');
    }

    final targets = darwinTargetsForBuild(
      platformName: Environment.darwinPlatformName,
      architectures: Environment.darwinArchs,
    );
    final environment = BuildEnvironment.fromEnvironment(isAndroid: false);
    final provider =
        ArtifactProvider(environment: environment, userOptions: userOptions);
    final artifacts = await provider.getArtifacts(
      targets,
      artifactType: AritifactType.staticlib,
    );

    final inputLibraries = targets.map((target) {
      final libraries = (artifacts[target] ?? [])
          .where((artifact) => artifact.type == AritifactType.staticlib)
          .toList(growable: false);
      if (libraries.length != 1) {
        throw StateError(
          'Expected one static library for $target. Swift Package Manager '
          'builds require the Rust crate to declare '
          'crate-type = ["staticlib"].',
        );
      }
      return libraries.single.path;
    }).toList(growable: false);

    final output = Environment.outputFile;
    Directory(path.dirname(output)).createSync(recursive: true);
    final temporaryOutput = '$output.tmp.$pid';
    try {
      runCommand(
        'lipo',
        createLipoArguments(
          libraries: inputLibraries,
          output: temporaryOutput,
        ),
      );
      File(temporaryOutput).renameSync(output);
    } finally {
      final temporaryFile = File(temporaryOutput);
      if (temporaryFile.existsSync()) {
        temporaryFile.deleteSync();
      }
    }
  }
}
