class UserModel {
  final String id;
  final String email;
  final String passwordHash;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'passwordHash': passwordHash,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<dynamic, dynamic> map) => UserModel(
        id: map['id'] as String,
        email: map['email'] as String,
        passwordHash: map['passwordHash'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
