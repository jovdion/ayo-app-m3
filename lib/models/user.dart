import 'dart:math' as math;

class User {
  final String id;
  final String username;
  final String email;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    print('Creating User from map: $map'); // Debug log

    // Handle latitude
    double? lat;
    if (map['latitude'] != null) {
      try {
        lat = double.parse(map['latitude'].toString());
        print('Parsed latitude: $lat');
      } catch (e) {
        print('Error parsing latitude: $e');
      }
    } else {
      print('Latitude is null in response');
    }

    // Handle longitude
    double? lng;
    if (map['longitude'] != null) {
      try {
        lng = double.parse(map['longitude'].toString());
        print('Parsed longitude: $lng');
      } catch (e) {
        print('Error parsing longitude: $e');
      }
    } else {
      print('Longitude is null in response');
    }

    final user = User(
      id: map['id'].toString(),
      username: map['username'],
      email: map['email'],
      latitude: lat,
      longitude: lng,
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );

    print('Created user object: $user');
    return user;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
    return 'User(id: $id, username: $username, email: $email, lat: $latitude, lng: $longitude)';
  }
}
