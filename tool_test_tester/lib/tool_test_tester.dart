//import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
//import 'package:analyzer/error/error.dart';
//import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:file/file.dart';

Future<void> run(Directory root) async {
  final entities = root.listSync();
  for (final entity in entities) {
    if (entity is! File || !entity.path.endsWith('_test.dart')) {
      continue;
    }
    print('visiting ${entity.path}');
    parseFile();
  }
  return;

  //for (final context in collection.contexts) {
  //  print('visiting ${context.contextRoot.root.path}...');

  //  for (final filePath in context.contextRoot.analyzedFiles()) {
  //    if (!filePath.endsWith('_test.dart')) {
  //      continue;
  //    }
  //    print('visiting $filePath');
  //  }
  //}
}
