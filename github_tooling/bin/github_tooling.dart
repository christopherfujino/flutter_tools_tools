import 'dart:io' as io;
import 'dart:convert';

import 'package:github_tooling/github_tooling.dart' as github_tooling;

import 'package:github/github.dart';
import 'package:http/http.dart';

Future<void> main(List<String> args) async {
  final token = io.Platform.environment['GITHUB_ACCESS_TOKEN'] as String;
  print(token);
  //return _packageHttp();
  return _packageGithub(token);
}

Future<void> _packageHttp() async {
  final Response response = await get(
    Uri.https('api.github.com', 'repos/flutter/flutter/issues'),
  );
  print(response.body);
}

Future<void> _packageGithub(String token) async {
  final GitHub github = GitHub(auth: Authentication.withToken(token));
  const List<String> labels = <String>['team-tool'];
  final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
  final jsonBuilder = <String, dynamic>{};
  await _githubReady(github);
  final Stream<Issue> issueStream =
      github.issues.listByRepo(slug, labels: labels);
  final List<Map<String, dynamic>> issues = <Map<String, dynamic>>[];
  jsonBuilder['issues'] = issues;
  await for (final Issue issue in issueStream) {
    print('got issue #${issue.number}');
    issues.add(<String, dynamic>{
      'number': issue.number,
      'labels': issue.labels,
      'title': issue.title,
      'assignees': issue.assignees,
      'state': issue.state,
    });
    await _githubReady(github);
  }
  print('got ${issues.length} issues.');
  io.File('out.json').writeAsStringSync(jsonEncode(jsonBuilder));
}

Future<void> _githubReady(GitHub github) async {
  print('rl remaining: ${github.rateLimitRemaining}\trl reset: ${github.rateLimitReset}');
  const double maxFraction = 0.95;
  if (github.rateLimitRemaining != null &&
      github.rateLimitRemaining! <
          (github.rateLimitLimit! * (1.0 - maxFraction)).round()) {
    assert(github.rateLimitReset != null);
    await _until(github.rateLimitReset!);
  }
}

Future<void> _until(DateTime target) async {
  final DateTime now = DateTime.timestamp();
  if (!now.isBefore(target)) {
    return Future<void>.value();
  }
  final Duration delta = target.difference(now);
  print('waiting until $target for rate limit reset...');
  await Future<void>.delayed(delta);
  print('finished waiting');
}
