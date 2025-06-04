class Message {
  final String id;
  final String? senderId;
  final String? receiverId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    this.senderId,
    this.receiverId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    print('Creating Message from map: $map');
    return Message(
      id: map['id'].toString(),
      senderId: map['senderId']?.toString(),
      receiverId: map['receiverId']?.toString(),
      content: map['content'] ?? map['text'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, receiverId: $receiverId, content: $content)';
  }
}
