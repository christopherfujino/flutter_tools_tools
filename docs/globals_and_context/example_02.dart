import 'dart:async';
import 'package:test/test.dart';

void main() {
  late _TestLogger _testLogger;

  setUp(() {
    _testLogger = _TestLogger();
  });

  test('fooCommand', () {
    runZoned(
      () => fooCommand(),
      zoneValues: {'logger': _testLogger}
    );
    expect(_testLogger.lines.first, contains('foo'));
  });

  test('barCommand', () {
    runZoned(
      () => barCommand(),
      zoneValues: {'logger': _testLogger}
    );
    expect(_testLogger.lines.first, contains('bar'));
  });
}

void fooCommand() {
  Logger.instance.log('running "foo"');
}

void barCommand() {
  Logger.instance.log('running "bar"');
}

/// [Logger.instance] now uses Zones!
class Logger {
  const Logger._();

  static Logger get instance => Zone.current['logger'] ?? const Logger._();

  void log(String message) => print(message);
}

class _TestLogger implements Logger {
  final List<String> lines = <String>[];

  void log(String message) => lines.add(message);
}
