// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_repo.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class RemoteRepo extends _RemoteRepo {
  RemoteRepo({this.id, this.package, this.url, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final String package;

  @override
  final String url;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  RemoteRepo copyWith(
      {String id,
      String package,
      String url,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new RemoteRepo(
        id: id ?? this.id,
        package: package ?? this.package,
        url: url ?? this.url,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _RemoteRepo &&
        other.id == id &&
        other.package == package &&
        other.url == url &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, package, url, createdAt, updatedAt]);
  }

  @override
  String toString() {
    return "RemoteRepo(id=$id, package=$package, url=$url, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return RemoteRepoSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const RemoteRepoSerializer remoteRepoSerializer = const RemoteRepoSerializer();

class RemoteRepoEncoder extends Converter<RemoteRepo, Map> {
  const RemoteRepoEncoder();

  @override
  Map convert(RemoteRepo model) => RemoteRepoSerializer.toMap(model);
}

class RemoteRepoDecoder extends Converter<Map, RemoteRepo> {
  const RemoteRepoDecoder();

  @override
  RemoteRepo convert(Map map) => RemoteRepoSerializer.fromMap(map);
}

class RemoteRepoSerializer extends Codec<RemoteRepo, Map> {
  const RemoteRepoSerializer();

  @override
  get encoder => const RemoteRepoEncoder();
  @override
  get decoder => const RemoteRepoDecoder();
  static RemoteRepo fromMap(Map map) {
    return new RemoteRepo(
        id: map['id'] as String,
        package: map['package'] as String,
        url: map['url'] as String,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null);
  }

  static Map<String, dynamic> toMap(_RemoteRepo model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'package': model.package,
      'url': model.url,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class RemoteRepoFields {
  static const List<String> allFields = <String>[
    id,
    package,
    url,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String package = 'package';

  static const String url = 'url';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
