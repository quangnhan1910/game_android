import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_url.dart';
import '../models/message_models.dart';

class MessageService {
  final String baseUrl;

  MessageService({String? baseUrl})
      : baseUrl = baseUrl ?? '${Config_URL.baseUrl}Message';

  // Lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Tạo headers với token
  Future<Map<String, String>> _buildHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Gửi tin nhắn
  Future<Map<String, dynamic>> sendMessage(SendMessageDto dto) async {
    try {
      final headers = await _buildHeaders();
      final url = '$baseUrl/send';
      
      print('===== SEND MESSAGE =====');
      print('URL: $url');
      print('Headers: $headers');
      print('Body: ${jsonEncode(dto.toJson())}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(dto.toJson()),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('========================');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'Server trả về dữ liệu trống',
          };
        }
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': MessageDto.fromJson(data),
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập lại',
        };
      } else {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'Lỗi server (${response.statusCode})',
          };
        }
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? 'Không thể gửi tin nhắn',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Không thể gửi tin nhắn (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Lấy lịch sử chat với một người bạn
  Future<Map<String, dynamic>> getChatHistory({
    required String friendUsername,
    int lastMessageId = 0,
    int pageSize = 50,
  }) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse('$baseUrl/history/$friendUsername')
          .replace(queryParameters: {
        'lastMessageId': lastMessageId.toString(),
        'pageSize': pageSize.toString(),
      });

      print('===== GET CHAT HISTORY =====');
      print('URL: ${uri.toString()}');
      print('Friend Username: $friendUsername');
      print('Last Message ID: $lastMessageId');
      print('Page Size: $pageSize');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('============================');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'Server trả về dữ liệu trống',
          };
        }
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'chatHistory': ChatHistoryDto.fromJson(data),
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập lại',
        };
      } else {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'Lỗi server (${response.statusCode})',
          };
        }
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? 'Không thể tải lịch sử chat',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Không thể tải lịch sử chat (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Lấy danh sách cuộc hội thoại
  Future<Map<String, dynamic>> getConversations() async {
    try {
      final headers = await _buildHeaders();
      final url = '$baseUrl/conversations';
      
      print('===== GET CONVERSATIONS =====');
      print('Base URL: $baseUrl');
      print('Full URL: $url');
      print('Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================');

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == '[]') {
          // Trả về danh sách rỗng nếu không có cuộc hội thoại
          return {
            'success': true,
            'conversations': <ConversationDto>[],
          };
        }
        final data = jsonDecode(response.body) as List;
        final conversations =
            data.map((conv) => ConversationDto.fromJson(conv)).toList();
        return {
          'success': true,
          'conversations': conversations,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập lại',
        };
      } else {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'Lỗi server (${response.statusCode})',
          };
        }
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? 'Không thể tải danh sách hội thoại',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Không thể tải danh sách hội thoại (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Lấy tin nhắn mới
  Future<Map<String, dynamic>> getNewMessages({
    required String friendUsername,
    required int lastMessageId,
  }) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse('$baseUrl/new/$friendUsername')
          .replace(queryParameters: {
        'lastMessageId': lastMessageId.toString(),
      });

      // Chỉ log khi debug (comment out để giảm log spam)
      // print('===== GET NEW MESSAGES =====');
      // print('URL: ${uri.toString()}');
      // print('Friend Username: $friendUsername');
      // print('Last Message ID: $lastMessageId');
      // print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      // Chỉ log khi có lỗi hoặc có tin nhắn mới
      // print('Response Status: ${response.statusCode}');
      // print('Response Body: ${response.body}');
      // print('============================');

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == '[]') {
          // Trả về danh sách rỗng nếu không có tin nhắn mới
          return {
            'success': true,
            'messages': <MessageDto>[],
          };
        }
        final data = jsonDecode(response.body) as List;
        final messages = data.map((msg) => MessageDto.fromJson(msg)).toList();
        return {
          'success': true,
          'messages': messages,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập lại',
        };
      } else {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'Lỗi server (${response.statusCode})',
          };
        }
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? 'Không thể tải tin nhắn mới',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Không thể tải tin nhắn mới (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }
}

