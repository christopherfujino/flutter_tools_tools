import 'dart:io' as io;
import 'dart:convert';
import 'dart:math' as math;

final file = io.File('out.json');

Future<void> main(List<String> args) async {
  await _readFromDisk();
}

Future<void> _readFromDisk() async {
  final contents = file.readAsStringSync();
  final outerBlob = jsonDecode(contents) as Map<String, dynamic>;
  final allIssues = (outerBlob['issues'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((Map<String, dynamic> issue) => _Issue.fromJson(issue))
      .where((issue) => !issue.labels.contains('triaged-tool'))
      .toList()
      ..sort((a, b) => b.number - a.number);
  final unassignedIssues = <_Issue>[];
  final assignedIssues = <_Issue>[];

  for (final issue in allIssues) {
    if (issue.assignees.isEmpty) {
      unassignedIssues.add(issue);
    } else {
      assignedIssues.add(issue);
    }
  }

  final chris = <int>[];
  final andrew = <int>[];
  final elias = <int>[];
  for (int i = 0; i < unassignedIssues.length; i++) {
    final issue = unassignedIssues[i];
    switch (i % 3) {
      case 0:
        chris.add(issue.number);
      case 1:
        andrew.add(issue.number);
      case 2:
        elias.add(issue.number);
      default:
        throw StateError('$i % 3 should not be ${i % 3}');
    }
  }

  final buffer = StringBuffer();
  _updateBufferForMember('@christopherfujino', chris, buffer);
  _updateBufferForMember('@andrewkolos', andrew, buffer);
  _updateBufferForMember('@eliasyishak', elias, buffer);
  print(buffer);
}

void _updateBufferForMember(String name, List<int> issues, StringBuffer buffer) {
  buffer.write('''
<details>
<summary>$name</summary>

''');
  for (final issue in issues) {
    buffer.writeln('- [ ] #$issue');
  }
  buffer.write('''
</details>
''');
}

class _Issue {
  _Issue.fromJson(Map<String, dynamic> blob) {
    labels = (blob['labels'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map<String>((Map<String, dynamic> label) {
      return label['name'] as String;
    }).toList();
    assignees = (blob['assignees'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((Map<String, dynamic> blob) => blob['login'] as String)
        .toList();
    number = blob['number'] as int;
    title = blob['title'] as String;
  }

  late final List<String> labels;
  late final List<String> assignees;
  late final int number;
  late final String title;

  @override
  String toString() =>
      '[$number] ${title.substring(0, math.min(title.length, 75))}';
}

Future<void> _queryGithub() async {
  final result = io.Process.runSync(
    'gh',
    const <String>[
      'issue',
      '--repo=flutter/flutter',
      'list',
      '--label=tool',
      '--state=open',
      '--json=labels,assignees,number,url,title',
      '--limit=2000',
    ],
  );
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    print(result.exitCode);
    io.exit(1);
  }
  final textDump = result.stdout as String;
  final blob = jsonDecode(textDump).cast<Map<String, dynamic>>();
  for (final issue in blob) {
    final assignees =
        (issue['assignees'] as List<dynamic>).cast<Map<String, dynamic>>();
    print(assignees);
    print(issue);
  }
  print(blob.length);
  file.writeAsStringSync(textDump);
}
