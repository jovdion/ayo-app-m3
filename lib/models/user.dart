class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final double latitude;
  final double longitude;
  final String lastSeen;
  final String hashedPassword; // Hashed password for security

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.latitude,
    required this.longitude,
    required this.lastSeen,
    required this.hashedPassword,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      avatarUrl: map['avatarUrl'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      lastSeen: map['lastSeen'],
      hashedPassword: map['hashedPassword'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': lastSeen,
      'hashedPassword': hashedPassword,
    };
  }
}
