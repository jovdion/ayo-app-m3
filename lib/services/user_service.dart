import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'api_config.dart';
import 'auth_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final AuthService _authService = AuthService();

  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getUsersEndpoint}'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersData = jsonDecode(response.body);
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
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.getUserProfileEndpoint}/$userId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
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
          'Authorization': 'Bearer ${_authService.authToken}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final updatedUser = User.fromMap(userData);
        // Update the current user in AuthService
        _authService.updateCurrentUser(updatedUser);
        return updatedUser;
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}
