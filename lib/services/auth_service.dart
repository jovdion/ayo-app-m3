import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../data/dummy_users.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  User? get currentUser => _currentUser;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<User?> login(String email, String password) async {
    print('Attempting login for email: $email');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final hashedPassword = _hashPassword(password);
    print('Searching for user with hashed password: $hashedPassword');

    final userData = dummyUsers.firstWhere(
      (user) =>
          user['email'] == email && user['hashedPassword'] == hashedPassword,
      orElse: () => {},
    );

    print('Found user data: $userData');

    if (userData.isEmpty) {
      print('Login failed: Invalid credentials');
      throw Exception('Invalid email or password');
    }

    _currentUser = User.fromMap(userData);
    print('Login successful. Current user: ${_currentUser?.toMap()}');
    return _currentUser;
  }

  Future<void> logout() async {
    print('Logging out current user: ${_currentUser?.toMap()}');
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    print('Logout complete. Current user is null: ${_currentUser == null}');
  }

  bool isLoggedIn() {
    final isLoggedIn = _currentUser != null;
    print('Checking login status. Current user: ${_currentUser?.toMap()}');
    print('Is logged in: $isLoggedIn');
    return isLoggedIn;
  }
}
