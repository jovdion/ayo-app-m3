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
      final currentUser = _authService.currentUser;
      final token = _authService.token;
      if (currentUser == null || token == null) {
        throw Exception('No user logged in');
      }

      print('Getting users list');
      print('Using token: $token');
      print(
          'Using endpoint: ${ApiConfig.baseUrl}${ApiConfig.getUsersEndpoint}');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getUsersEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get users response status: ${response.statusCode}');
      print('Get users response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> usersData = json.decode(response.body);
        return usersData
            .where((data) => data['id'].toString() != currentUser.id)
            .map((data) {
          print('Processing user data: $data');
          return User.fromMap(data);
        }).toList();
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        throw Exception('Failed to get users: $errorMessage');
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

      print('Getting user profile for ID: $userId');
      final endpoint = ApiConfig.getEndpointWithId(
        ApiConfig.getUserProfileEndpoint,
        userId,
      );
      print('Get profile URL: ${ApiConfig.baseUrl}$endpoint');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get profile response status: ${response.statusCode}');
      print('Get profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return User.fromMap(userData);
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        throw Exception('Failed to get user profile: $errorMessage');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      final currentUser = _authService.currentUser;
      final token = _authService.token;
      if (currentUser == null || token == null) {
        throw Exception('No user logged in');
      }

      print('Updating location for user ${currentUser.id}');
      print('New coordinates: $latitude, $longitude');
      print('Using token: $token');
      print(
          'Using endpoint: ${ApiConfig.baseUrl}${ApiConfig.updateLocationEndpoint}');

      final Map<String, dynamic> requestBody = {
        'latitude': latitude,
        'longitude': longitude,
      };
      print('Update location request body: ${json.encode(requestBody)}');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateLocationEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('Update location response status: ${response.statusCode}');
      print('Update location response body: ${response.body}');

      if (response.statusCode == 200) {
        // Update the current user's location in memory
        final updatedUser = User(
          id: currentUser.id,
          username: currentUser.username,
          email: currentUser.email,
          latitude: latitude,
          longitude: longitude,
          createdAt: currentUser.createdAt,
          updatedAt: DateTime.now(),
        );
        _authService.updateCurrentUser(updatedUser);

        // Update stored user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(updatedUser.toMap()));
        print('Updated user location in memory and storage');
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        throw Exception('Failed to update location: $errorMessage');
      }
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  Future<User> updateProfile({
    String? username,
    String? email,
    String? fcmToken,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      final token = _authService.token;
      if (currentUser == null || token == null) {
        throw Exception('No user logged in');
      }

      print('Updating profile for user ${currentUser.id}');

      final endpoint = ApiConfig.getEndpointWithId(
        ApiConfig.updateProfileEndpoint,
        currentUser.id,
      );
      print('Update profile URL: ${ApiConfig.baseUrl}$endpoint');

      final Map<String, dynamic> requestBody = {
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (fcmToken != null) 'fcm_token': fcmToken,
      };
      print('Update profile request body: ${json.encode(requestBody)}');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return User.fromMap(userData);
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        throw Exception('Failed to update profile: $errorMessage');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}
