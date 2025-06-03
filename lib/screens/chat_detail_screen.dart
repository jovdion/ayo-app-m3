import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../utils/time_helper.dart';
import '../utils/currency_helper.dart';

class ChatDetailScreen extends StatefulWidget {
  final String username;
  final String userId;

  const ChatDetailScreen({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final messageController = TextEditingController();
  Position? _currentPosition;
  double? distanceKm;
  User? otherUser;
  List<Map<String, dynamic>> messages = [];
  bool _isLoading = true;
  final List<String> currencies = [
    "IDR",
    "USD",
    "EUR",
    "GBP",
    "JPY",
    "AUD",
    "KRW",
    "SGD"
  ];
  final Map<int, String> selectedCurrencyPerMessage = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _userService.getUserProfile(widget.userId);
      setState(() {
        otherUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  String formatTimestamp(String timestamp) {
    return TimeHelper.formatMessageTime(
        timestamp, 0); // Using default timezone for now
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    setState(() {
      messages.add({
        "id": "m${messages.length + 1}",
        "senderId": currentUser.id,
        "receiverId": widget.userId,
        "text": text.trim(),
        "timestamp": now,
      });
      messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      Navigator.pop(context);
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? const Text('Loading...')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.username),
                  if (otherUser != null)
                    Text(
                      otherUser!.email,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.only(top: 4),
                    child: messages.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet.\nStart a conversation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe = msg['senderId'] == currentUser.id;
                              final hasCurrencyInMessage =
                                  CurrencyHelper.hasCurrency(msg['text']);

                              return Container(
                                margin: EdgeInsets.only(
                                  left: isMe ? 50 : 8,
                                  right: isMe ? 8 : 50,
                                  bottom: 12,
                                ),
                                child: Align(
                                  alignment: isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.lightBlue[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft:
                                            Radius.circular(isMe ? 16 : 0),
                                        bottomRight:
                                            Radius.circular(isMe ? 0 : 16),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg['text'],
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.black87
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatTimestamp(msg['timestamp']),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMe
                                                ? Colors.black54
                                                : Colors.black45,
                                          ),
                                        ),
                                        if (hasCurrencyInMessage) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isMe
                                                  ? Colors.lightBlue
                                                      .withOpacity(0.1)
                                                  : Colors.grey
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.currency_exchange,
                                                      size: 14,
                                                      color: isMe
                                                          ? Colors.lightBlue
                                                              .withOpacity(0.7)
                                                          : Colors.grey
                                                              .withOpacity(0.7),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Convert to:',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isMe
                                                            ? Colors.lightBlue
                                                                .withOpacity(
                                                                    0.7)
                                                            : Colors.grey
                                                                .withOpacity(
                                                                    0.7),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    DropdownButton<String>(
                                                      value:
                                                          selectedCurrencyPerMessage[
                                                                  index] ??
                                                              currencies.first,
                                                      items: currencies
                                                          .map((currency) {
                                                        return DropdownMenuItem(
                                                          value: currency,
                                                          child: Text(
                                                            currency,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: isMe
                                                                  ? Colors
                                                                      .lightBlue
                                                                      .shade700
                                                                  : Colors.grey
                                                                      .shade700,
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                      onChanged: (value) {
                                                        if (value != null) {
                                                          setState(() {
                                                            selectedCurrencyPerMessage[
                                                                index] = value;
                                                          });
                                                        }
                                                      },
                                                      underline:
                                                          const SizedBox(),
                                                      isDense: true,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Builder(
                                                  builder: (context) {
                                                    final currencies =
                                                        CurrencyHelper
                                                            .extractCurrenciesFromText(
                                                                msg['text']);
                                                    if (currencies.isEmpty)
                                                      return const SizedBox();

                                                    final amount = currencies
                                                            .first['amount']
                                                        as double;
                                                    final fromCurrency =
                                                        currencies.first[
                                                                'currency']
                                                            as String;
                                                    final toCurrency =
                                                        selectedCurrencyPerMessage[
                                                                index] ??
                                                            this
                                                                .currencies
                                                                .first;

                                                    final convertedAmount =
                                                        CurrencyHelper
                                                            .convertCurrency(
                                                      amount,
                                                      fromCurrency,
                                                      toCurrency,
                                                    );

                                                    return Text(
                                                      CurrencyHelper
                                                          .formatCurrency(
                                                              convertedAmount,
                                                              toCurrency),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: isMe
                                                            ? Colors.lightBlue
                                                                .shade700
                                                            : Colors
                                                                .grey.shade700,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => sendMessage(messageController.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
