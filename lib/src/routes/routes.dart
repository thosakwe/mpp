library mpp.src.routes;

import 'package:angel_auth/angel_auth.dart';
import 'package:angel_file_service/angel_file_service.dart';
import 'package:angel_framework/angel_framework.dart';
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

    // Throw a 404 if no route matched the request.
    app.fallback((req, res) => throw AngelHttpException.notFound());
  };
}
