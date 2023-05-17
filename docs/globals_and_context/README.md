# How the tool uses globals

Consider the following minimal command line application that has two
sub-commands ("foo" and "bar") and a single `Logger` instance shared between
the two:

```dart
// example_00.dart
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

class Logger {
  const Logger._();

  static const Logger instance = Logger._();

  void log(String message) => print(message);
}
```

Note that static variables are global. You have to reference them via a
namespace, which is nice, but they are still global variables. Because `Logger`
has only a single private contructor, if we moved the class definition to its
own library, we could be certain that an instance can only be obtained via
our singleton `Logger.instance` static variable (although it could still be
sub-classed).

Now what happens when we want to unit test our `fooCommand()` and
`barCommand()` functions? We have no mechanism for overriding in a test what
`Logger` is used (let's ignore the `IOOverrides` class in `dart:io` for now, as
it is equivalent to an approach we will look at later).

The simplest solution would be to make `Logger.instance` non-const, and
re-assign it before each test:

```dart
// example_01.dart
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

/// Our entire app shares the [instance] singleton.
class Logger {
  const Logger._();

  static Logger instance = Logger._();

  void log(String message) => print(message);
}

class _TestLogger implements Logger {
  final List<String> lines = <String>[];

  void log(String message) => lines.add(message);
}
```

This is bad however because we now have global mutable state. If we later add
another test library, but forget to add a `setUp()` invocation we will leak
our `_TestLogger` between tests. Also, with large test files with nested
`group()`s, it can be difficult to reason about when a `setUp()` callback is
invoked.

It would be great if there was a way for our business logic code (in this
case, `fooCommand()` and `barCommand()`) to retrieve a different `Logger`
instance based on the context it is running in. Fortunately you can with
[Zones](https://dart.dev/articles/archive/zones)!

```dart
// example_02.dart
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
```

This doesn't look too bad. We've just added a few more lines of code: each
test that wants to override a `Zone.current` access needs to be wrapped and
our `Logger.instance` is now a getter that will first check [Zone.current] for
a `Logger` and fall back to our singleton (here it is a singleton because we
invoke the `const` constructor, we would need some extra typing if we needed
a non-const constructor).

But what the heck is a [Zone](https://dart.dev/articles/archive/zones#zone-basics)
anyway?

> A zone represents the asynchronous dynamic extent of a call. It is the
> computation that is performed as part of a call and, transitively, the
> asynchronous callbacks that have been registered by that code.

Hmm, that's pretty confusing. Zones also complicate debugging, as it is
non-obvious from reading the code where and when a value from `Zone.current`
was constructed.

In addition, how would a future author of a new test that calls `fooCommand()`
know that they have to override the `'logger'` field in `zoneValues`? Since our
`Logger.instance` getter will silently fall back to our desired production
instance, it would be easy for a new test to accidentally use the production
`Logger`. With this particular example, hopefully the author would notice the
stray prints in the test output. But what if global value was an `HttpClient`?
Or a `LocalFileSystem`, and the test is actually deleting files on the
developer's computer?

One solution would be to be strict about never having any fallbacks, and
having any function that checks for a value in the current `Zone` to throw
if one was not provided. This way, any production code that depended on a
global zone value that is invoked by a test that had not set up that override
would fail, and the test author would know they have to provide an appropriate
test object. If there was a test wrapper function (e.g. `testUsingContext()`),
should it allow default fallbacks? Fallbacks would automagically make certain
tests much easier to write at the cost of having some tests pass for the wrong
reason because the test author is unaware their test is silently using a fake
object.

Another solution, which trades ease of writing for ease of understanding, is
dependency injection:

```dart
// example_03.dart
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
```

In this trivial example, I think this is clearly the best solution:

1. It is easy from reading the code to reason about the lifecycle of the
`Logger` that each sub-command uses (the construction of each `Logger` can
easily be found in a debugger by walking up the stack trace).
2. Any new test calling a sub-command would be required by the compiler to
explicitly pass a `Logger` argument, and thus test authors would have a local
reference they can assert on (with `testUsingContext`, imperative set up steps
to an override can be cumbersome).
3. All dependencies of a test are clear at a glance in code review.

The drawbacks are:

1. A deeply nested function requiring a new reference to a global object (such
as a `Logger`) may require updating many other function signatures to pass
that object down the stack.
2. Updating any of those function signatures may require many tests to be
updated, to now pass test overrides.
3. Complex functions (such as sub-command constructors) will now have many
parameters.
