import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../local/hive_boxes.dart';
import '../models/user_model.dart';

const _sessionKey = 'current_user_id';

class AuthRepository {
  final Box _usersBox = Hive.box(HiveBoxes.users);
  final _uuid = const Uuid();

  String _hash(String password) => sha256.convert(utf8.encode(password)).toString();

  /// Cria conta (email/senha local). Lança exceção se e-mail já existir.
  Future<UserModel> register(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final exists = _usersBox.values
        .map((v) => UserModel.fromMap(v as Map))
        .any((u) => u.email == normalized);
    if (exists) {
      throw Exception('E-mail já cadastrado.');
    }
    final user = UserModel(
      id: _uuid.v4(),
      email: normalized,
      passwordHash: _hash(password),
      createdAt: DateTime.now(),
    );
    await _usersBox.put(user.id, user.toMap());
    await _persistSession(user.id);
    return user;
  }

  Future<UserModel> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final hash = _hash(password);
    final match = _usersBox.values
        .map((v) => UserModel.fromMap(v as Map))
        .where((u) => u.email == normalized && u.passwordHash == hash)
        .toList();
    if (match.isEmpty) {
      throw Exception('E-mail ou senha inválidos.');
    }
    await _persistSession(match.first.id);
    return match.first;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> _persistSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, userId);
  }

  /// Restaura sessão persistida (usado no boot do app / auto-login).
  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_sessionKey);
    if (userId == null) return null;
    final map = _usersBox.get(userId);
    if (map == null) return null;
    return UserModel.fromMap(map as Map);
  }
}
