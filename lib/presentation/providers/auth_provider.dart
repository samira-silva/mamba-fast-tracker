import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  UserModel? user;
  AuthState state = AuthState.unknown;
  String? errorMessage;

  Future<void> restoreSession() async {
    user = await _repo.restoreSession();
    state = user != null ? AuthState.authenticated : AuthState.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      errorMessage = null;
      user = await _repo.login(email, password);
      state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      errorMessage = null;
      user = await _repo.register(email, password);
      state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    user = null;
    state = AuthState.unauthenticated;
    notifyListeners();
  }
}
