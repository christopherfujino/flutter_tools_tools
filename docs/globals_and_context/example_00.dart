void main(List<String> args) {
  return switch (args.first) {
    'foo' => fooCommand(),
    'bar' => barCommand(),
    _ => throw StateError('Usage error'),
  };
}

void fooCommand() {
  Logger.instance.log('running "foo"');
}

void barCommand() {
  Logger.instance.log('running "bar"');
}

/// Our entire app shares the [instance] singleton.
class Logger {
  const Logger._();

  static const Logger instance = Logger._();

  void log(String message) => print(message);
}
