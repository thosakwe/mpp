import 'dart:io';

import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_hot/angel_hot.dart';
import 'package:logging/logging.dart';
import 'package:mpp/mpp.dart';
import 'package:mpp/src/pretty_logging.dart';

main() async {
  // Watch the config/ and web/ directories for changes, and hot-reload the server.
  hierarchicalLoggingEnabled = true;

  var hot = HotReloader(() async {
    var logger = Logger.detached('mpp')..onRecord.listen(prettyLog);
    var app = Angel(logger: logger, reflector: MirrorsReflector());
    await app.configure(configureServer);
    return app;
  }, [
    Directory('config'),
    Directory('lib'),
    File('pubspec.lock'),
  ]);

  var server = await hot.startServer('127.0.0.1', 3000);
  print(
      'mpp server listening at http://${server.address.address}:${server.port}');
}
