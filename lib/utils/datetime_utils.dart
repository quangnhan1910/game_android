import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Utility class để xử lý timezone chuẩn
class DateTimeUtils {

  static DateTime parseUtcFromServer(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return DateTime.now().toUtc();
    }
    
    try {
      // Normalize format: SQL Server trả về dấng "2025-10-26 16:23:46.7383197"
      // cần convert thành ISO 8601: "2025-10-26T16:23:46.7383197"
      String normalized = isoString.trim();
      
      // Nếu có dấu cách giữa ngày và giờ, thay bằng 'T' (SQL Server format)
      if (normalized.contains(' ') && !normalized.contains('T')) {
        normalized = normalized.replaceFirst(' ', 'T');
      }
      
      // DateTime.parse() tự động nhận diện UTC nếu có 'Z' ở cuối
      DateTime dateTime = DateTime.parse(normalized);
      
      // Nếu string từ server không có 'Z' nhưng thực tế là UTC,
      // chúng ta cần tạo DateTime UTC với các giá trị đã parse
      // thay vì convert (vì convert sẽ tính offset sai)
      if (!dateTime.isUtc) {
        // Giả định server luôn trả về UTC, nên ta tạo DateTime UTC
        // với các giá trị thời gian đã parse (không convert)
        dateTime = DateTime.utc(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
          dateTime.microsecond,
        );
      }
      
      return dateTime;
    } catch (e) {
      print('Error parsing datetime: $e, input: $isoString');
      return DateTime.now().toUtc();
    }
  }

  /// Convert DateTime UTC sang local time của thiết bị
  static DateTime toLocal(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  /// Format thời gian để hiển thị trong chat message
  /// 
  /// - Hôm nay: "15:30"
  /// - Hôm qua: "Hôm qua 15:30"
  /// - Khác: "26/10/2024 15:30"
  static String formatMessageTime(DateTime dateTime) {
    // Convert sang local time trước khi format
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTime);
    
    if (difference.inDays == 0) {
      // Hôm nay - chỉ hiển thị giờ
      return DateFormat('HH:mm').format(localTime);
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${DateFormat('HH:mm').format(localTime)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(localTime);
    }
  }

  /// Format thời gian cho conversation list
  /// 
  /// - Hôm nay: "15:30"
  /// - Hôm qua: "Hôm qua"
  /// - Trong tuần: "Thứ Hai", "Thứ Ba", etc.
  /// - Cũ hơn: "26/10/2024"
  static String formatConversationTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    // Convert sang local time trước khi format
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTime);
    
    if (difference.inDays == 0) {
      // Hôm nay - hiển thị giờ
      return DateFormat('HH:mm').format(localTime);
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      // Trong tuần - hiển thị thứ (cần config locale tiếng Việt)
      final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return weekdays[localTime.weekday % 7];
    } else {
      // Cách xa hơn - hiển thị ngày/tháng
      return DateFormat('dd/MM/yyyy').format(localTime);
    }
  }

  /// Format thời gian theo kiểu "time ago" (5 phút trước, 1 giờ trước, etc.)
  /// Sử dụng package timeago với locale tiếng Việt
  static String formatTimeAgo(DateTime dateTime) {
    // Convert sang local time trước khi format
    final localTime = dateTime.toLocal();
    
    // Khởi tạo locale tiếng Việt cho timeago (nếu chưa có)
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    
    return timeago.format(localTime, locale: 'vi');
  }

  /// Format thời gian cho date separator trong chat
  /// 
  /// - Hôm nay: "Hôm nay, 26/10/2024"
  /// - Hôm qua: "Hôm qua, 25/10/2024"
  /// - Khác: "26/10/2024"
  static String formatDateSeparator(DateTime dateTime) {
    // Convert sang local time trước khi format
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTime);
    
    final dateStr = DateFormat('dd/MM/yyyy').format(localTime);
    
    if (difference.inDays == 0) {
      return 'Hôm nay, $dateStr';
    } else if (difference.inDays == 1) {
      return 'Hôm qua, $dateStr';
    } else {
      return dateStr;
    }
  }

  /// Convert DateTime sang ISO 8601 UTC string để gửi lên server
  /// 
  /// Client có thể tạo DateTime local, method này sẽ convert sang UTC
  /// trước khi serialize thành ISO 8601 string
  static String toUtcIsoString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Kiểm tra 2 DateTime có cùng ngày không (so sánh local time)
  static bool isSameDay(DateTime date1, DateTime date2) {
    final local1 = date1.toLocal();
    final local2 = date2.toLocal();
    
    return local1.year == local2.year &&
        local1.month == local2.month &&
        local1.day == local2.day;
  }

  /// Format ngày/tháng/năm đầy đủ
  static String formatFullDate(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('dd/MM/yyyy').format(localTime);
  }

  /// Format giờ:phút
  static String formatTimeOnly(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('HH:mm').format(localTime);
  }

  /// Format ngày giờ đầy đủ
  static String formatFullDateTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(localTime);
  }
}

