import 'package:args/args.dart';

void main(List<String> args) {
  final ArgParser parser = ArgParser()
    ..addOption(
      'repository-path',
      abbr: 'r',
      mandatory: true,
    );
  final ArgResults results = parser.parse(args);
  print('hello, world!');
}
