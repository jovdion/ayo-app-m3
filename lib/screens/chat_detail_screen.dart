import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/currency_helper.dart';
import '../utils/time_helper.dart';
import '../data/dummy_chats.dart';
import '../data/dummy_users.dart';
import '../services/auth_service.dart';
import 'compass_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String user;
  const ChatDetailScreen({super.key, required this.user});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final messageController = TextEditingController();
  final List<String> currencies = [
    "IDR",
    "JPY",
    "EUR",
    "GBP",
    "AUD",
    "KRW",
    "USD"
  ];
  final Map<int, String> selectedCurrencyPerMessage = {};
  List<Map<String, dynamic>> messages = [];
  final _authService = AuthService();

  double? distanceKm;
  Position? _currentPosition;
  Map<String, dynamic>? userData;

  final RegExp currencyPattern = RegExp(
      r'(?:(?:Rp|USD|EUR|GBP|JPY|AUD|KRW|SGD|\$|€|£|¥|₩|S\$)[,.\s]*[0-9]+(?:[,.][0-9]+)*)|(?:[0-9]+(?:[,.][0-9]+)*(?:\s*(?:dollars?|euros?|pounds?|yen|won|rupiah)))',
      caseSensitive: false);

  bool hasCurrency(String text) {
    return currencyPattern.hasMatch(text);
  }

  @override
  void initState() {
    super.initState();
    userData = dummyUsers.firstWhere((u) => u['username'] == widget.user);
    messages = getDummyMessages(widget.user);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);

      if (userData != null) {
        final dist = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              userData!['latitude'],
              userData!['longitude'],
            ) /
            1000;
        setState(() => distanceKm = dist);
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  List<Map<String, dynamic>> getDummyMessages(String user) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return [];

    final userId = dummyUsers.firstWhere((u) => u['username'] == user)['id'];
    return dummyChats
        .where(
          (msg) =>
              (msg['senderId'] == userId &&
                  msg['receiverId'] == currentUser.id) ||
              (msg['senderId'] == currentUser.id &&
                  msg['receiverId'] == userId),
        )
        .toList()
      ..sort(
        (a, b) => DateTime.parse(
          a['timestamp'],
        ).compareTo(DateTime.parse(b['timestamp'])),
      );
  }

  String formatTimestamp(String timestamp) {
    if (userData != null) {
      return TimeHelper.formatMessageTime(timestamp, userData!['longitude']);
    }
    return timestamp;
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final userId = userData!['id'];
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    setState(() {
      messages.add({
        "id": "m${messages.length + 1}",
        "senderId": currentUser.id,
        "receiverId": userId,
        "text": text.trim(),
        "timestamp": now,
      });
      messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.person, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (distanceKm != null)
                        Text(
                          "${distanceKm!.toStringAsFixed(1)} km away",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                if (userData != null)
                  Material(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CompassScreen(
                              userName: widget.user,
                              targetLatitude: userData!['latitude'],
                              targetLongitude: userData!['longitude'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Icon(
                              Icons.explore,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.only(top: 4),
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['senderId'] == currentUser.id;
                  final hasCurrencyInMessage = hasCurrency(msg['text']);

                  return Container(
                    margin: EdgeInsets.only(
                      left: isMe ? 50 : 8,
                      right: isMe ? 8 : 50,
                      bottom: 12,
                    ),
                    child: Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isMe ? Colors.lightBlue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['text'],
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatTimestamp(msg['timestamp']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (hasCurrencyInMessage) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.lightBlue.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.currency_exchange,
                                          size: 14,
                                          color: isMe
                                              ? Colors.lightBlue
                                                  .withOpacity(0.7)
                                              : Colors.grey.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Konversi ke:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isMe
                                                ? Colors.lightBlue
                                                    .withOpacity(0.7)
                                                : Colors.grey.withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        DropdownButton<String>(
                                          value: selectedCurrencyPerMessage[
                                                  index] ??
                                              currencies.first,
                                          items: currencies
                                              .map((e) => DropdownMenuItem(
                                                    value: e,
                                                    child: Text(
                                                      e,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isMe
                                                            ? Colors.lightBlue
                                                                .shade700
                                                            : Colors
                                                                .grey.shade700,
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              selectedCurrencyPerMessage[
                                                  index] = val!;
                                            });
                                          },
                                          underline: const SizedBox(),
                                          isDense: true,
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            size: 16,
                                            color: isMe
                                                ? Colors.lightBlue
                                                    .withOpacity(0.7)
                                                : Colors.grey.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          formatCurrency(
                                            convertCurrency(
                                              extractCurrenciesFromText(
                                                      msg['text'])
                                                  .first['amount'],
                                              extractCurrenciesFromText(
                                                      msg['text'])
                                                  .first['currency'],
                                              selectedCurrencyPerMessage[
                                                      index] ??
                                                  currencies.first,
                                            ),
                                            selectedCurrencyPerMessage[index] ??
                                                currencies.first,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isMe
                                                ? Colors.lightBlue.shade700
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
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
