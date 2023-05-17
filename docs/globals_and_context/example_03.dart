import 'package:test/test.dart';

void main() {
  late _TestLogger _testLogger;

  setUp(() {
    _testLogger = _TestLogger();
  });

  test('fooCommand', () {
    fooCommand(_testLogger);
    expect(_testLogger.lines.first, contains('foo'));
  });

  test('barCommand', () {
    barCommand(_testLogger);
    expect(_testLogger.lines.first, contains('bar'));
  });
}

void fooCommand(Logger logger) {
  logger.log('running "foo"');
}

void barCommand(Logger logger) {
  logger.log('running "bar"');
}

class Logger {
  const Logger._();

  static const Logger instance = Logger._();

  void log(String message) => print(message);
}

class _TestLogger implements Logger {
  final List<String> lines = <String>[];

  void log(String message) => lines.add(message);
}
