import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'api_config.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  User? get currentUser => _currentUser;
  String? _authToken;

  Future<User> register(String name, String email, String password) async {
    print('Attempting registration with email: $email');
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': name,
          'email': email,
          'password': password,
        }),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 201) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromMap(userData['user']);
        _authToken = userData['token'];
        print('Registration successful. User: ${_currentUser?.toMap()}');
        return _currentUser!;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  Future<User> login(String email, String password) async {
    print('Attempting login with email: $email');
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromMap(userData['user']);
        _authToken = userData['token'];
        print('Login successful. User: ${_currentUser?.toMap()}');
        return _currentUser!;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;
  }

  bool isLoggedIn() => _currentUser != null;

  String? get authToken => _authToken;
}
