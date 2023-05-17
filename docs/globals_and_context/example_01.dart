import 'package:test/test.dart';

void main() {
  late _TestLogger _testLogger;

  setUp(() {
    _testLogger = _TestLogger();
    Logger.instance = _testLogger;
  });

  test('fooCommand', () {
    fooCommand();
    expect(_testLogger.lines.first, contains('foo'));
  });

  test('barCommand', () {
    barCommand();
    expect(_testLogger.lines.first, contains('bar'));
  });
}

void fooCommand() {
  Logger.instance.log('running "foo"');
}

void barCommand() {
  Logger.instance.log('running "bar"');
}

/// [Logger.instance] is now mutable.
class Logger {
  const Logger._();

  static Logger instance = Logger._();

  void log(String message) => print(message);
}

class _TestLogger implements Logger {
  final List<String> lines = <String>[];

  void log(String message) => lines.add(message);
}
