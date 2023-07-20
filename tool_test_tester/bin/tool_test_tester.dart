import 'package:tool_test_tester/tool_test_tester.dart' as tool_test_tester;
import 'package:file/local.dart';
import 'package:path/path.dart';

Future<void> main(List<String> arguments) {
  const fs = LocalFileSystem();
  final packageDir = fs.directory(normalize(arguments.first)).absolute;
  if (!packageDir.existsSync()) {
    throw ArgumentError('${packageDir.path} does not exist on disk');
  }

  return tool_test_tester.run(packageDir);
}
