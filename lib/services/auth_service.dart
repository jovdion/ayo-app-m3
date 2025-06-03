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
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final userData = jsonDecode(response.body);
      _currentUser = User.fromMap(userData['user']);
      _authToken = userData['token'];
      return _currentUser!;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      _currentUser = User.fromMap(userData['user']);
      _authToken = userData['token'];
      return _currentUser!;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;
  }

  bool isLoggedIn() => _currentUser != null;

  String? get authToken => _authToken;
}
