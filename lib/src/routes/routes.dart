library mpp.src.routes;

import 'package:angel_auth/angel_auth.dart';
import 'package:angel_file_service/angel_file_service.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:file/file.dart';
import 'package:mpp/models.dart';

import 'controllers/controllers.dart' as controllers;

/// Put your app routes here!
///
/// See the wiki for information about routing, requests, and responses:
/// * https://github.com/angel-dart/angel/wiki/Basic-Routing
/// * https://github.com/angel-dart/angel/wiki/Requests-&-Responses
AngelConfigurer configureServer(FileSystem fileSystem) {
  return (Angel app) async {
    // Set up some injections.
    var dbCrypt = DBCrypt();
    var users = JsonFileService(fileSystem.file('users.json'))
        .map(UserSerializer.fromMap, UserSerializer.toMap);
    app.container
      ..registerSingleton(dbCrypt)
      ..registerSingleton<Service<String, User>>(users);

    // Set up basic auth.
    var auth = AngelAuth<User>(
      jwtKey: app.configuration['jwt_secret'] as String,
      allowCookie: false,
      serializer: (u) => u.id,
      deserializer: (id) {
        return users.read(id.toString()).catchError((_) => null);
      },
    );

    // Username+password
    auth.strategies['local'] = LocalAuthStrategy((username, password) async {
      var query = {UserFields.username: username};
      var params = {'query': query};
      var user = await users.findOne(params).catchError((_) => null);

      if (user != null) {
        var hashed = dbCrypt.hashpw(password, user.salt);
        if (hashed == user.hashedPassword) return user;
      }

      return null;
    }, forceBasic: true);

    // Force basic auth.
    await app.configure(auth.configureServer);
    app.fallback(auth.authenticate(
        'local', AngelAuthOptions(canRespondWithJson: false)));

    // Typically, you want to mount controllers first, after any global middleware.
    await app.configure(controllers.configureServer);

    // Render `views/hello.jl` when a user visits the application root.
    app.get('/', (req, res) => res.render('hello'));

    // Mount static server at web in development.
    // The `CachingVirtualDirectory` variant of `VirtualDirectory` also sends `Cache-Control` headers.
    //
    // In production, however, prefer serving static files through NGINX or a
    // similar reverse proxy.
    //
    // Read the following two sources for documentation:
    // * https://medium.com/the-angel-framework/serving-static-files-with-the-angel-framework-2ddc7a2b84ae
    // * https://github.com/angel-dart/static
    if (!app.environment.isProduction) {
      var vDir = VirtualDirectory(
        app,
        fileSystem,
        source: fileSystem.directory('web'),
      );
      app.fallback(vDir.handleRequest);
    }

    // Throw a 404 if no route matched the request.
    app.fallback((req, res) => throw AngelHttpException.notFound());

    // Set our application up to handle different errors.
    //
    // Read the following for documentation:
    // * https://github.com/angel-dart/angel/wiki/Error-Handling

    var oldErrorHandler = app.errorHandler;
    app.errorHandler = (e, req, res) async {
      if (req.accepts('text/html', strict: true)) {
        if (e.statusCode == 404 && req.accepts('text/html', strict: true)) {
          await res
              .render('error', {'message': 'No file exists at ${req.uri}.'});
        } else {
          await res.render('error', {'message': e.message});
        }
      } else {
        return await oldErrorHandler(e, req, res);
      }
    };
  };
}
