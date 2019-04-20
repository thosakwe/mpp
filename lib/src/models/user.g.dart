// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class User extends _User {
  User(
      {this.id,
      this.username,
      this.salt,
      this.hashedPassword,
      this.createdAt,
      this.updatedAt});

  @override
  final String id;

  @override
  final String username;

  @override
  final String salt;

  @override
  final String hashedPassword;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  User copyWith(
      {String id,
      String username,
      String salt,
      String hashedPassword,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new User(
        id: id ?? this.id,
        username: username ?? this.username,
        salt: salt ?? this.salt,
        hashedPassword: hashedPassword ?? this.hashedPassword,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _User &&
        other.id == id &&
        other.username == username &&
        other.salt == salt &&
        other.hashedPassword == hashedPassword &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects(
        [id, username, salt, hashedPassword, createdAt, updatedAt]);
  }

  @override
  String toString() {
    return "User(id=$id, username=$username, salt=$salt, hashedPassword=$hashedPassword, createdAt=$createdAt, updatedAt=$updatedAt)";
  }

  Map<String, dynamic> toJson() {
    return UserSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const UserSerializer userSerializer = const UserSerializer();

class UserEncoder extends Converter<User, Map> {
  const UserEncoder();

  @override
  Map convert(User model) => UserSerializer.toMap(model);
}

class UserDecoder extends Converter<Map, User> {
  const UserDecoder();

  @override
  User convert(Map map) => UserSerializer.fromMap(map);
}

class UserSerializer extends Codec<User, Map> {
  const UserSerializer();

  @override
  get encoder => const UserEncoder();
  @override
  get decoder => const UserDecoder();
  static User fromMap(Map map) {
    return new User(
        id: map['id'] as String,
        username: map['username'] as String,
        salt: map['salt'] as String,
        hashedPassword: map['hashed_password'] as String,
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

  static Map<String, dynamic> toMap(_User model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'username': model.username,
      'salt': model.salt,
      'hashed_password': model.hashedPassword,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class UserFields {
  static const List<String> allFields = <String>[
    id,
    username,
    salt,
    hashedPassword,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String username = 'username';

  static const String salt = 'salt';

  static const String hashedPassword = 'hashed_password';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
