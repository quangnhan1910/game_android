import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';
import '../models/friend_models.dart';

class FriendService {
  String get baseUrl => "${Config_URL.baseUrl}Friend";
  
  // Timeout cho các request
  static const Duration timeoutDuration = Duration(seconds: 10);

  // Lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Tìm kiếm người dùng
  Future<Map<String, dynamic>> searchUsers(String query) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Vui lòng đăng nhập"};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/search?query=$query'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<UserSearchResult> users = data.map((json) => UserSearchResult.fromJson(json)).toList();
        return {"success": true, "data": users};
      } else {
        final errorData = jsonDecode(response.body);
        return {"success": false, "message": errorData['message'] ?? "Lỗi tìm kiếm"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // Gửi lời mời kết bạn
  Future<Map<String, dynamic>> sendFriendRequest(String receiverUsername) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Vui lòng đăng nhập"};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/request'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "ReceiverUsername": receiverUsername,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "message": data['message'] ?? "Đã gửi lời mời kết bạn"};
      } else {
        final errorData = jsonDecode(response.body);
        return {"success": false, "message": errorData['message'] ?? "Lỗi gửi lời mời"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // Lấy danh sách lời mời kết bạn đang chờ (nhận được)
  Future<Map<String, dynamic>> getPendingRequests() async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Vui lòng đăng nhập"};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/requests/pending'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<FriendRequest> requests = data.map((json) => FriendRequest.fromJson(json)).toList();
        return {"success": true, "data": requests};
      } else {
        final errorData = jsonDecode(response.body);
        return {"success": false, "message": errorData['message'] ?? "Lỗi lấy danh sách"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // Lấy danh sách lời mời đã gửi
  Future<Map<String, dynamic>> getSentFriendRequests() async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Vui lòng đăng nhập"};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/requests/sent'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<SentFriendRequest> requests = data.map((json) => SentFriendRequest.fromJson(json)).toList();
        return {"success": true, "data": requests};
      } else {
        final errorData = jsonDecode(response.body);
        return {"success": false, "message": errorData['message'] ?? "Lỗi lấy danh sách"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // Chấp nhận lời mời kết bạn
  Future<Map<String, dynamic>> acceptFriendRequest(int requestId) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Vui lòng đăng nhập"};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/requests/$requestId/accept'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "message": data['message'] ?? "Đã chấp nhận lời mời"};
      } else {
        final errorData = jsonDecode(response.body);
        return {"success": false, "message": errorData['message'] ?? "Lỗi chấp nhận"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // Từ chối lời mời kết bạn
  Future<Map<String, dynamic>> rejectFriendRequest(int requestId) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Vui lòng đăng nhập"};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/requests/$requestId/reject'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "message": data['message'] ?? "Đã từ chối lời mời"};
      } else {
        final errorData = jsonDecode(response.body);
        return {"success": false, "message": errorData['message'] ?? "Lỗi từ chối"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // Hủy lời mời kết bạn đã gửi
  Future<Map<String, dynamic>> cancelFriendRequest(int requestId) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Vui lòng đăng nhập"};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/requests/$requestId/cancel'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "message": data['message'] ?? "Đã hủy lời mời kết bạn"};
      } else {
        final errorData = jsonDecode(response.body);
        return {"success": false, "message": errorData['message'] ?? "Lỗi hủy lời mời"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // Lấy danh sách bạn bè
  Future<Map<String, dynamic>> getFriends() async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Vui lòng đăng nhập"};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/friends'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Friend> friends = data.map((json) => Friend.fromJson(json)).toList();
        return {"success": true, "data": friends};
      } else {
        final errorData = jsonDecode(response.body);
        return {"success": false, "message": errorData['message'] ?? "Lỗi lấy danh sách"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // Hủy kết bạn
  Future<Map<String, dynamic>> unfriend(String friendUsername) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Vui lòng đăng nhập"};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/friends/$friendUsername'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "message": data['message'] ?? "Đã hủy kết bạn"};
      } else {
        final errorData = jsonDecode(response.body);
        return {"success": false, "message": errorData['message'] ?? "Lỗi hủy kết bạn"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }
}

