import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../utils/time_helper.dart';
import '../utils/currency_helper.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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
  final _chatService = ChatService();
  final messageController = TextEditingController();
  Position? _currentPosition;
  double? _heading;
  double? distanceKm;
  User? otherUser;
  List<Message> messages = [];
  bool _isLoading = true;
  bool _hasCompass = false;
  StreamSubscription<CompassEvent>? _compassSubscription;
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
    _loadMessages();
    _initializeCompass();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    messageController.dispose();
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCompass() async {
    _hasCompass = await FlutterCompass.events != null;

    if (_hasCompass) {
      _compassSubscription = FlutterCompass.events!.listen((event) {
        if (mounted) {
          setState(() {
            _heading = event.heading;
          });
        }
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _userService.getUserProfile(widget.userId);
      setState(() {
        otherUser = user;
      });
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final loadedMessages = await _chatService.getMessages(widget.userId);
      setState(() {
        messages = loadedMessages;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _updateDistance();
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _updateDistance() {
    if (_currentPosition != null &&
        otherUser?.latitude != null &&
        otherUser?.longitude != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        otherUser!.latitude!,
        otherUser!.longitude!,
      );
      setState(() {
        distanceKm = distance / 1000;
      });
    }
  }

  double _calculateBearing() {
    if (_currentPosition == null ||
        otherUser?.latitude == null ||
        otherUser?.longitude == null) {
      return 0;
    }

    final lat1 = _currentPosition!.latitude * math.pi / 180;
    final lon1 = _currentPosition!.longitude * math.pi / 180;
    final lat2 = otherUser!.latitude! * math.pi / 180;
    final lon2 = otherUser!.longitude! * math.pi / 180;

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  Future<String> formatTimestamp(DateTime timestamp) async {
    final adjustedTime = await TimeHelper.adjustToUserTimezone(timestamp);
    return TimeHelper.formatMessageTimestamp(adjustedTime);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      print('Attempting to send message:');
      print('Receiver ID: ${widget.userId}');
      print('Message content: ${text.trim()}');

      final message =
          await _chatService.sendMessage(widget.userId, text.trim());

      print('Message sent successfully:');
      print('Message ID: ${message.id}');
      print('Content: ${message.content}');

      setState(() {
        messages.add(message);
        messageController.clear();
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
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
        actions: [
          if (_hasCompass && _heading != null && distanceKm != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Transform.rotate(
                    angle: ((_heading! - _calculateBearing()) * math.pi / 180),
                    child: const Icon(Icons.navigation),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
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
                              final isMe = msg.senderId == currentUser.id;
                              final hasCurrencyInMessage =
                                  CurrencyHelper.hasCurrency(msg.content);

                              return FutureBuilder<String>(
                                future: formatTimestamp(msg.createdAt),
                                builder: (context, snapshot) {
                                  final timestamp =
                                      snapshot.data ?? 'Loading...';

                                  return Container(
                                    margin: EdgeInsets.only(
                                      left: msg.senderId == currentUser.id
                                          ? 50
                                          : 8,
                                      right: msg.senderId == currentUser.id
                                          ? 8
                                          : 50,
                                      bottom: 12,
                                    ),
                                    child: Align(
                                      alignment: msg.senderId == currentUser.id
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: msg.senderId == currentUser.id
                                              ? Colors.blue[600]
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft: Radius.circular(
                                                msg.senderId == currentUser.id
                                                    ? 16
                                                    : 0),
                                            bottomRight: Radius.circular(
                                                msg.senderId == currentUser.id
                                                    ? 0
                                                    : 16),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              msg.senderId == currentUser.id
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              msg.content,
                                              style: TextStyle(
                                                color: msg.senderId ==
                                                        currentUser.id
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              timestamp,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: msg.senderId ==
                                                        currentUser.id
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                            ),
                                            if (hasCurrencyInMessage) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: msg.senderId ==
                                                          currentUser.id
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
                                                          Icons
                                                              .currency_exchange,
                                                          size: 14,
                                                          color: msg.senderId ==
                                                                  currentUser.id
                                                              ? Colors.lightBlue
                                                                  .withOpacity(
                                                                      0.7)
                                                              : Colors.grey
                                                                  .withOpacity(
                                                                      0.7),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          'Convert to:',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: msg.senderId ==
                                                                    currentUser
                                                                        .id
                                                                ? Colors
                                                                    .lightBlue
                                                                    .withOpacity(
                                                                        0.7)
                                                                : Colors.grey
                                                                    .withOpacity(
                                                                        0.7),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        DropdownButton<String>(
                                                          value:
                                                              selectedCurrencyPerMessage[
                                                                      index] ??
                                                                  currencies
                                                                      .first,
                                                          items: currencies
                                                              .map((currency) {
                                                            return DropdownMenuItem(
                                                              value: currency,
                                                              child: Text(
                                                                currency,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color: msg.senderId ==
                                                                          currentUser
                                                                              .id
                                                                      ? Colors
                                                                          .lightBlue
                                                                          .shade700
                                                                      : Colors
                                                                          .grey
                                                                          .shade700,
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                          onChanged: (value) {
                                                            if (value != null) {
                                                              setState(() {
                                                                selectedCurrencyPerMessage[
                                                                        index] =
                                                                    value;
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
                                                                    msg.content);
                                                        if (currencies.isEmpty)
                                                          return const SizedBox();

                                                        final amount =
                                                            currencies.first[
                                                                    'amount']
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
                                                            color: msg.senderId ==
                                                                    currentUser
                                                                        .id
                                                                ? Colors
                                                                    .lightBlue
                                                                    .shade700
                                                                : Colors.grey
                                                                    .shade700,
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
