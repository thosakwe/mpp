import 'dart:io';

import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:mpp/models.dart';
import 'package:mpp/mpp.dart' as mpp;
import 'package:mpp/src/config/plugins/repo_manager.dart';

main(List<String> args) async {
  var app = Angel(reflector: MirrorsReflector());
  await app.configure(mpp.configureServer);

  var runner = CommandRunner('mpp.dart', 'Controls the `mpp` database.')
    ..addCommand(_AuthCommand(app))
    ..addCommand(_MirrorCommand(app));

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr..writeln(e.message)..writeln()..writeln('usage:')..writeln(e.usage);
  } on ArgParserException catch (e) {
    stderr.writeln(e.message);
  } finally {
    await app.close();
  }
}

class _AuthCommand extends Command {
  final Angel app;
  final DBCrypt dbCrypt;
  final Service<String, User> userService;

  _AuthCommand(this.app)
      : dbCrypt = app.container.make(),
        userService = app.container.make() {
    argParser
      ..addOption('username', abbr: 'u', help: 'The username.')
      ..addOption('password',
          abbr: 'p', help: 'The password. Cannot be recovered if forgotten.');
  }

  @override
  String get name => 'auth';

  @override
  String get description => 'Add a new user to the database.';

  @override
  run() async {
    if (!argResults.wasParsed('username'))
      throw ArgParserException('Missing required `username` option.');
    if (!argResults.wasParsed('password'))
      throw ArgParserException('Missing required `password` option.');

    var username = argResults['username'] as String;
    var password = argResults['password'] as String;
    var salt = dbCrypt.gensalt();
    var user = await userService.create(User(
        username: username,
        salt: salt,
        hashedPassword: dbCrypt.hashpw(password, salt)));
    print('Created user `${user.username}` with ID ${user.id}.');
  }
}

class _MirrorCommand extends Command {
  final Angel app;
  final RepoManager repoManager;

  _MirrorCommand(this.app) : repoManager = app.container.make() {
    argParser
      ..addOption('url', abbr: 'u', help: 'The URL of a remote Git repository.')
      ..addOption('name',
          abbr: 'n',
          help: 'The name of the package, as it will appear in the Pub API.');
  }

  @override
  String get name => 'mirror';

  @override
  String get description =>
      'Adds a Git repository to the list of packages to mirror.';

  @override
  run() async {
    if (!argResults.wasParsed('name'))
      throw ArgParserException('Missing required `name` option.');
    if (!argResults.wasParsed('url'))
      throw ArgParserException('Missing required `url` option.');

    var name = argResults['name'] as String;
    var url = argResults['url'] as String;
    var repo = await repoManager.repoService
        .create(RemoteRepo(package: name, url: url));
    print(
        'Set up package `${repo.package}` to mirror Git repository ${repo.url}.');
  }
}
