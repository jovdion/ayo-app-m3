class Message {
  final int id;
  final int? senderId;
  final int receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    print('Creating Message from map: $map'); // Debug log
    return Message(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      senderId: _parseId(map['sender_id'] ?? map['senderId']),
      receiverId: _parseId(map['receiver_id'] ?? map['receiverId'])!,
      message: map['message'] ??
          map['content'] ??
          '', // Support both message and content
      isRead: map['is_read'] ?? map['isRead'] ?? false,
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : (map['createdAt'] is String
              ? DateTime.parse(map['createdAt'])
              : (map['created_at'] as DateTime? ?? DateTime.now())),
    );
  }

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, receiverId: $receiverId, message: $message, isRead: $isRead, createdAt: $createdAt)';
  }
}
