class Message {
  final int id;
  final int? senderId;
  final int receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      content:
          map['content'] ?? map['message'] ?? '', // Support both field names
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, receiverId: $receiverId, content: $content, isRead: $isRead, createdAt: $createdAt)';
  }
}
