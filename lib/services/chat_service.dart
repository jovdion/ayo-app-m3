import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final AuthService _authService = AuthService();

  Future<Message> sendMessage(String receiverId, String content) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendMessageEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authService.authToken}',
      },
      body: jsonEncode({
        'receiverId': receiverId,
        'content': content,
      }),
    );

    if (response.statusCode == 201) {
      final messageData = jsonDecode(response.body);
      return Message.fromMap(messageData);
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<List<Message>> getMessages(String otherUserId) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.getMessagesEndpoint}/$otherUserId'),
      headers: {
        'Authorization': 'Bearer ${_authService.authToken}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> messagesData = jsonDecode(response.body);
      return messagesData.map((data) => Message.fromMap(data)).toList();
    } else {
      throw Exception('Failed to get messages: ${response.body}');
    }
  }
}
