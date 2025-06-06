import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final AuthService _authService = AuthService();
  final String baseUrl = ApiConfig.baseUrl;

  String _parseErrorMessage(String responseBody) {
    try {
      final data = json.decode(responseBody);
      if (data['message'] != null) {
        return data['message'];
      } else if (data['error'] != null) {
        return data['error'];
      }
    } catch (e) {
      if (responseBody.contains('<!DOCTYPE html>')) {
        final match = RegExp(r'<pre>(.*?)</pre>').firstMatch(responseBody);
        if (match != null && match.groupCount >= 1) {
          return match.group(1) ?? responseBody;
        }
      }
    }
    return responseBody;
  }

  Future<List<User>> getUsers() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.body}');
      }
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }

  Future<User> getUserProfile(int userId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return User.fromMap(json.decode(response.body));
      } else {
        throw Exception('Failed to load user profile: ${response.body}');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<User> updateUserProfile({
    required String username,
    required String email,
    String? password,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token available');

      final Map<String, dynamic> body = {
        'username': username,
        'email': email,
      };
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return User.fromMap(json.decode(response.body));
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token available');

      print('Updating location for user');
      print('New coordinates: $latitude, $longitude');
      print('Using token: $token');
      print('Using endpoint: $baseUrl/api/users/location');

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      print('Update location response status: ${response.statusCode}');
      print('Update location response body: ${response.body}');

      if (response.statusCode == 200) {
        // Save location to SharedPreferences for quick access
        final user = User(
          id: (await _authService.getCurrentUser())?.id ?? 0,
          username: '', // These fields aren't needed for location caching
          email: '',
          latitude: latitude,
          longitude: longitude,
          lastLocationUpdate: DateTime.now(),
        );
        await user.saveLocationToPrefs();
      } else {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  Future<Map<String, double?>> getCachedLocation() async {
    return User.getLocationFromPrefs();
  }
}
