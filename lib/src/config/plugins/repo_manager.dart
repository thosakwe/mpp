library mpp.src.config.plugins.repo_manager;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Process, ProcessStartMode;

import 'package:angel_file_service/angel_file_service.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/file.dart';
import 'package:mpp/models.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';
import 'package:tuple/tuple.dart';

class RepoManager {
  final Directory packageDir;
  final Service<String, RemoteRepo> repoService;

  RepoManager(FileSystem fs)
      : packageDir = fs.directory('.dart_tool/mpp_packages'),
        repoService = JsonFileService(fs.file('repos.json'))
            .map(RemoteRepoSerializer.fromMap, RemoteRepoSerializer.toMap);

  Future<Directory> getRepoDir(String name, String url) async {
    var repoDir = packageDir.childDirectory('.repo').childDirectory(name);

    if (!await repoDir.exists()) {
      // Clone
      var git = await Process.start(
          'git', ['clone', url, '--depth', '1', repoDir.absolute.path],
          mode: ProcessStartMode.inheritStdio);
      var exit = await git.exitCode;
      if (exit != 0) {
        throw StateError(
            'Git clone for perusing package `$name` failed with exit code ${exit}.');
      }
    }

    return repoDir;
  }

  Future<List<PubSpec>> getVersions(
      String name, String url, Iterable<String> refs) async {
    var repoDir = await getRepoDir(name, url);

    // Fetch.
    var git = await Process.start('git', ['fetch', '--all'],
        mode: ProcessStartMode.inheritStdio,
        workingDirectory: repoDir.absolute.path);
    var exit = await git.exitCode;
    if (exit != 0) {
      throw StateError(
          'Git fetch for perusing package `$name` failed with exit code ${exit}.');
    }

    var out = <PubSpec>[];

    for (var ref in refs) {
//      try {
//        Version.parse(ref);
//      } on FormatException catch (e) {
//        continue;
//      }

      // Read the pubspec.yaml.
      var gitShow = await Process.run('git', ['show', '$ref:pubspec.yaml'],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
          workingDirectory: repoDir.absolute.path);
      if (gitShow.exitCode != 0 && gitShow.exitCode != 128) {
        throw StateError(
            'Git show for perusing $ref on package `$name` failed with exit code ${gitShow.exitCode}:\n${gitShow.stderr}.');
      } else {
        try {
          out.add(PubSpec.fromYamlString(gitShow.stdout as String));
        } on FormatException {
          // Ignore this...
        }
      }
    }

    out.sort((a, b) => b.version.compareTo(a.version));
    return out;
  }

  Future<Directory> createVersionDirectory(String name, String version) async {
    var params = {
      'query': {'package': name}
    };
    var repo = await repoService.findOne(params).catchError((_) => null);
    if (repo == null) {
      throw AngelHttpException.notFound(
          message: 'No such package is registered locally.');
    }

    var vDirTuple = await versionDirectoryTuple(name, version);
    var vDir = vDirTuple.item2;

    // If the Git directory does not exist, clone.
    if (!await vDir.exists()) {
      var git = await Process.start(
          'git',
          [
            'clone',
            repo.url,
            '--single-branch',
            '--depth',
            '1',
            '--branch',
            vDirTuple.item1,
            vDir.absolute.path
          ],
          mode: ProcessStartMode.inheritStdio);
      var exit = await git.exitCode;
      if (exit != 0) {
        throw StateError(
            'Git clone for package `$name`@$version failed with exit code ${exit}.');
      }
    }

    // Next, pull remote changes.
    var git = await Process.start('git', ['pull', 'origin', version],
        workingDirectory: vDir.absolute.path,
        mode: ProcessStartMode.inheritStdio);
    var exit = await git.exitCode;
    if (exit != 0) {
      throw StateError(
          'Git pull for package `$name`@$version failed with exit code ${exit}.');
    }

    return vDir;
  }

  Directory toolDir(Directory d) =>
      d.childDirectory('.dart_tool').childDirectory('mpp');

  File versionPubspecFile(Directory d) {
    return d.childFile('pubspec.yaml');
  }

  Future<Process> tarVersion(Directory d) {
    return Process.start('tar', ['-czf', d.absolute.path]);
  }

  Directory packageDirectory(String name) {
    return packageDir.childDirectory(name);
  }

  Future<Directory> versionDirectory(String name, String version) {
    return versionDirectoryTuple(name, version).then((t) => t.item2);
  }

  Future<Tuple2<String, Directory>> versionDirectoryTuple(
      String name, String version) async {
    var parent = packageDirectory(name);
    var expected = parent.childDirectory(version);
    if (!await expected.exists() && await parent.exists()) {
      // Check non-versions (i.e. HEAD, master, etc)
      await for (var entity in parent.list()) {
        try {
          Version.parse(entity.basename);
        } on FormatException {
          if (entity is Directory) {
            var pubspecFile = entity.childFile('pubspec.yaml');
            if (await pubspecFile.exists()) {
              var text = await pubspecFile.readAsString();
              try {
                var pubspec = PubSpec.fromYamlString(text);
                if (pubspec.version.toString() == version)
                  return Tuple2(entity.basename, entity);
              } catch (_) {
                // Ignore...
              }
            }
          }
        }
      }
    }

    return Tuple2(version, expected);
  }
}
