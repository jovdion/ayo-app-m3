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

  // Add method to update current user
  void updateCurrentUser(User user) {
    print('Updating current user: $user');
    _currentUser = user;
  }

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
        print('Loaded stored auth - Token: $_token');
        print('Loaded stored auth - User: ${_currentUser?.toString()}');
      }
    } catch (e) {
      print('Error loading stored auth: $e');
      logout();
    }
  }

  Future<User> login(String email, String password) async {
    try {
      print('Attempting login with email: $email');
      print('Login URL: ${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed response data: $data');

        if (data['token'] == null) {
          throw Exception('Invalid response format: missing token');
        }
        if (data['user'] == null) {
          throw Exception('Invalid response format: missing user data');
        }

        _token = data['token'];
        _currentUser = User.fromMap(data['user']);
        print('Created user object: ${_currentUser?.toString()}');

        // Store auth data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_currentUser!.toMap()));
        print('Stored auth data in SharedPreferences');

        return _currentUser!;
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        throw Exception('Login failed: $errorMessage');
      }
    } catch (e) {
      print('Error in login: $e');
      rethrow;
    }
  }

  Future<User> register(String username, String email, String password) async {
    try {
      print('Attempting registration with email: $email');
      print('Register URL: ${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Parsed response data: $data');

        if (data['token'] == null) {
          throw Exception('Invalid response format: missing token');
        }
        if (data['user'] == null) {
          throw Exception('Invalid response format: missing user data');
        }

        _token = data['token'];
        _currentUser = User.fromMap(data['user']);
        print('Created user object: ${_currentUser?.toString()}');

        // Store auth data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_currentUser!.toMap()));
        print('Stored auth data in SharedPreferences');

        return _currentUser!;
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        throw Exception('Registration failed: $errorMessage');
      }
    } catch (e) {
      print('Error in register: $e');
      rethrow;
    }
  }

  String _parseErrorMessage(String responseBody) {
    try {
      final data = json.decode(responseBody);
      if (data['message'] != null) {
        return data['message'];
      } else if (data['error'] != null) {
        return data['error'];
      }
    } catch (e) {
      // If response is not JSON, return the raw body
      if (responseBody.contains('<!DOCTYPE html>')) {
        // Extract message from HTML error page
        final match = RegExp(r'<pre>(.*?)</pre>').firstMatch(responseBody);
        if (match != null && match.groupCount >= 1) {
          return match.group(1) ?? responseBody;
        }
      }
    }
    return responseBody;
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      print('Cleared stored auth data');
    } catch (e) {
      print('Error clearing stored auth: $e');
    }
  }
}
