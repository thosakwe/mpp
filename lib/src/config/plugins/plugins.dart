library mpp.src.config.plugins;

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/file.dart';
import 'repo_manager.dart';

Future configureServer(Angel app, FileSystem fileSystem) async {
  // Include any plugins you have made here.
  app.container.registerSingleton(RepoManager(fileSystem));
}
