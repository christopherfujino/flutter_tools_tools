import 'dart:io' as io;

import 'package:yaml/yaml.dart';

Future<void> main(List<String> args) async {
  final led = await io.Process.start(
    'led',
    <String>[],
  );

  final exitCode = await led.exitCode;
  if (exitCode != 0) {
    io.stderr.writeln('led invocation failed with $exitCode');
    io.exit(42);
  }
}

class CiYaml {
  CiYaml._(this.blob);

  final Map<String, Object?> blob;

  factory CiYaml(String path) {
    return CiYaml._(
      loadYaml(path),
    );
  }

  // TODO cache?
  List<Builder> get toBuilders {
    throw 'TODO';
  }
}

class Builder {}
