import '../../domain/entities/user_entity.dart';

/// نموذج بيانات المستخدم في طبقة الـ Data
class UserModel extends UserEntity {
  final String? password;

  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.createdAt,
    this.password,
  });

  factory UserModel.fromEntity(UserEntity entity, {String? password}) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      createdAt: entity.createdAt,
      password: password,
    );
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      password: map['password'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      if (password != null) 'password': password,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      password: password ?? this.password,
    );
  }
}
