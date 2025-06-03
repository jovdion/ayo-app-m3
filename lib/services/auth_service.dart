import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/api_config.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;

  bool isLoggedIn() {
    return _currentUser != null && _token != null;
  }

  Future<void> loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('token');
      final storedUser = prefs.getString('user');

      if (storedToken != null && storedUser != null) {
        _token = storedToken;
        _currentUser = User.fromMap(json.decode(storedUser));
      }
    } catch (e) {
      print('Error loading stored auth: $e');
      logout();
    }
  }

  Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _currentUser = User.fromMap(data['user']);

        // Store auth data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_currentUser!.toMap()));

        return _currentUser!;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      print('Error in login: $e');
      rethrow;
    }
  }

  Future<User> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _token = data['token'];
        _currentUser = User.fromMap(data['user']);

        // Store auth data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_currentUser!.toMap()));

        return _currentUser!;
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      print('Error in register: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
    } catch (e) {
      print('Error clearing stored auth: $e');
    }
  }
}
