import 'dart:math' as math;

class User {
  final String id;
  final String username;
  final String email;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fcmToken: map['fcm_token']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString())
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  double? getDistanceTo(User other) {
    if (latitude == null ||
        longitude == null ||
        other.latitude == null ||
        other.longitude == null) {
      return null;
    }

    var p = math.pi / 180;
    var a = 0.5 -
        math.cos((other.latitude! - latitude!) * p) / 2 +
        math.cos(latitude! * p) *
            math.cos(other.latitude! * p) *
            (1 - math.cos((other.longitude! - longitude!) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  double? getBearingTo(User other) {
    if (latitude == null ||
        longitude == null ||
        other.latitude == null ||
        other.longitude == null) {
      return null;
    }

    var lat1 = latitude! * math.pi / 180;
    var lat2 = other.latitude! * math.pi / 180;
    var dLon = (other.longitude! - longitude!) * math.pi / 180;

    var y = math.sin(dLon) * math.cos(lat2);
    var x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    var bearing = math.atan2(y, x);

    // Convert to degrees
    bearing = bearing * 180 / math.pi;
    // Normalize to 0-360
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, fcmToken: $fcmToken, latitude: $latitude, longitude: $longitude)';
  }
}
