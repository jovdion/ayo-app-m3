import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final AuthService _authService = AuthService();

  Future<List<Message>> getMessages(String userId) async {
    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesData = json.decode(response.body);
        return messagesData.map((data) => Message.fromMap(data)).toList();
      } else {
        throw Exception('Failed to get messages: ${response.body}');
      }
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  Future<Message> sendMessage(String receiverId, String text) async {
    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'receiver_id': receiverId,
          'text': text,
        }),
      );

      if (response.statusCode == 201) {
        final messageData = json.decode(response.body);
        return Message.fromMap(messageData);
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}
