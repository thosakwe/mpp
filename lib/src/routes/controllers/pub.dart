import 'dart:async';
import 'dart:convert';
import 'dart:io' show Process;
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:archive/archive.dart';
import 'package:file/file.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mpp/models.dart';
import 'package:mpp/src/config/plugins/repo_manager.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec/pubspec.dart';

FutureOr _authGuard(RequestContext req, ResponseContext res) => requireAuthentication<User>()(req, res);

@Expose('/', middleware: [_authGuard])
class PubController extends Controller {
  final RepoManager repoManager;
  final _ref = RegExp(r'refs/(heads|tags)/');
  final _tarGz = RegExp(r'\.tar\.gz$');

  PubController(this.repoManager);

  @override
  Future configureServer(Angel app) async {
    var pubBaseUri = Uri.parse('https://pub.dartlang.org');
    app.container.registerLazySingleton<Future<RemoteRepo>>((container) async {
      var req = container.make<RequestContext>();
      var res = container.make<ResponseContext>();
      var name = req.params['name'] as String;
      var params = {
        'query': {'package': name}
      };
      var repo =
          await repoManager.repoService.findOne(params).catchError((_) => null);
      if (repo != null) {
        return repo;
      } else {
        var pubUri = pubBaseUri.replace(path: req.uri.path);
        await res.redirect(pubUri);
        return null;
      }
    });
    await super.configureServer(app);
  }

  @Expose('/api/packages/:name')
  Future getPackage(RequestContext req, ResponseContext res,
      {RemoteRepo repo}) async {
    if (repo != null) {
      // Fetch all refs
      // git ls-remote --exit-code -q <url>
      var lsRemote = await Process.run(
          'git', ['ls-remote', '--exit-code', '-q', repo.url],
          stdoutEncoding: utf8, stderrEncoding: utf8);

      if (lsRemote.exitCode != 0) {
        throw StateError(
            'Git ls-remote terminated with exit code ${lsRemote.exitCode}: ${lsRemote.stderr}');
      }

      var lines = LineSplitter().convert(lsRemote.stdout as String);
      var rawRefs = lines.map((l) => l.split('\t')[1].trim());
      var processedRefs = rawRefs.map((r) => r.replaceAll(_ref, ''));

      // Turn these into pubspec versions
      var pubspecs =
          await repoManager.getVersions(repo.package, repo.url, processedRefs);
      var latest = pubspecs.isEmpty ? null : pubspecs[0];
      var apiRoot = p.dirname(p.dirname(req.uri.path));
      Map<String, dynamic> _convert(PubSpec pubspec) {
        return {
          'version': pubspec.version.toString(),
          'archive_url': p.join(apiRoot, 'packages', repo.package, 'versions',
              '${pubspec.version.toString()}.tar.gz'),
          'pubspec': pubspec.toJson(),
        };
      }

      return {
        'name': repo.package,
        'latest': latest == null ? null : _convert(latest),
        'versions': pubspecs.map(_convert).toList(),
      };
    }
  }

  @Expose('/packages/:name/versions/:version')
  Future downloadPackage(ResponseContext res, String version,
      {RemoteRepo repo}) async {
    if (repo == null) return;
    var normalizedVersion = version.replaceAll(_tarGz, '');
    var dir = await repoManager.createVersionDirectory(
        repo.package, normalizedVersion);
    var archive = Archive();

    Future<void> _crawl(FileSystemEntity entity, [bool isRoot = false]) async {
      var relative = p.relative(entity.path, from: dir.path);
      if (isRoot ||
          !const [
            '.',
            '.git',
            '.dart_tool',
            'build',
            '.packages',
            'pubspec.lock'
          ].contains(relative)) {
        if (entity is Directory) {
          await for (var child in entity.list()) {
            await _crawl(child);
          }
        } else if (entity is File) {
          var stat = await entity.stat();
          var file =
              ArchiveFile(relative, stat.size, await entity.readAsBytes())
                ..mode = stat.mode
                ..lastModTime = stat.modified.millisecondsSinceEpoch;
          archive.addFile(file);
        }
      }
    }

    await _crawl(dir, true);

    var asTar = TarEncoder().encode(archive);
    var asGzip = GZipEncoder().encode(asTar);
    res
      ..contentType = MediaType('application', 'gzip')
      ..add(asGzip);
    await res.close();

//    var process = await repoManager.tarVersion(dir);
//    var pipe = process.stdout.pipe(res);
//    await process.exitCode;
//    await process.stderr.drain();
//    await pipe;
  }
}
