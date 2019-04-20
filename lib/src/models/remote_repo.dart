import 'package:angel_serialize/angel_serialize.dart';
part 'remote_repo.g.dart';

@serializable
abstract class _RemoteRepo extends Model {
  String get package;
  String get url;
}
