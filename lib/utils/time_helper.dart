import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TimeHelper {
  static bool _initialized = false;

  static void initialize() {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }
  }

  static String formatMessageTime(String timestamp, double longitude) {
    initialize();

    final dateTime = DateTime.parse(timestamp);
    final location = _getIndonesianTimezone(longitude);
    final localTime = tz.TZDateTime.from(dateTime, location);
    final now = tz.TZDateTime.now(location);
    final difference = now.difference(localTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(localTime); // Today's time
    } else if (difference.inDays < 7) {
      return DateFormat('E HH:mm').format(localTime); // Weekday and time
    } else {
      return DateFormat('MMM d, HH:mm').format(localTime); // Full date and time
    }
  }

  static tz.Location _getIndonesianTimezone(double longitude) {
    // Indonesia has 3 main time zones based on longitude
    if (longitude < 107.5) {
      return tz.getLocation('Asia/Jakarta'); // WIB (UTC+7)
    } else if (longitude < 120) {
      return tz.getLocation('Asia/Makassar'); // WITA (UTC+8)
    } else {
      return tz.getLocation('Asia/Jayapura'); // WIT (UTC+9)
    }
  }
}
