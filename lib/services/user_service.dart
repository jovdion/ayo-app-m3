import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final AuthService _authService = AuthService();

  Future<List<User>> getUsers() async {
    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getUsersEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersData = json.decode(response.body);
        return usersData.map((data) => User.fromMap(data)).toList();
      } else {
        throw Exception('Failed to get users: ${response.body}');
      }
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }

  Future<User> getUserProfile(String userId) async {
    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.getUserProfileEndpoint}/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return User.fromMap(userData);
      } else {
        throw Exception('Failed to get user profile: ${response.body}');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<User> updateProfile({
    required String username,
    required String email,
    String? password,
  }) async {
    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('No authentication token');
      }

      final Map<String, dynamic> body = {
        'username': username,
        'email': email,
      };
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateProfileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return User.fromMap(userData);
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateLocationEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }
}
