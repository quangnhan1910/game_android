import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tetris_leaderboard_models.dart';
import '../config/config_url.dart';
import 'auth_service.dart';

class TetrisLeaderboardService {
  final String baseUrl;
  final AuthService _authService = AuthService();

  TetrisLeaderboardService({String? baseUrl})
      : baseUrl = baseUrl ?? Config_URL.baseUrl;

  /// Gửi điểm số lên server
  Future<Map<String, dynamic>> submitScore({
    required int score,
    required int level,
  }) async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Bạn cần đăng nhập để gửi điểm',
        };
      }

      print('Gửi điểm Tetris: score=$score, level=$level');

      final response = await http.post(
        Uri.parse('${baseUrl}tetris/leaderboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'score': score,
          'level': level,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Đã gửi điểm thành công!',
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Lỗi khi gửi điểm',
        };
      }
    } catch (e) {
      print('Error submitting score: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  /// Lấy danh sách bảng xếp hạng
  Future<TetrisLeaderboardResponse?> getLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final token = await _authService.getStoredToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${baseUrl}tetris/leaderboard?limit=$limit&offset=$offset'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Backend trả về { success, message, data: [...] }
        final data = responseData['data'] ?? responseData;
        
        return TetrisLeaderboardResponse(
          entries: (data as List)
              .map((entry) => TetrisLeaderboardEntry.fromJson(entry))
              .toList(),
          totalCount: data.length,
        );
      } else {
        print('Error getting leaderboard: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting leaderboard: $e');
      return null;
    }
  }

  /// Lấy điểm số cao nhất của người dùng hiện tại
  Future<TetrisLeaderboardEntry?> getMyBestScore() async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        print('Không có token để lấy điểm của user');
        return null;
      }

      // Kiểm tra token có hợp lệ không
      if (!_authService.isTokenValid(token)) {
        print('Token đã hết hạn, không thể lấy điểm của user');
        return null;
      }

      print('Đang gọi API /tetris/leaderboard/me với token');

      final response = await http.get(
        Uri.parse('${baseUrl}tetris/leaderboard/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status /me: ${response.statusCode}');
      print('Response body /me: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Backend trả về { success, message, data: { bestScore, bestLevel, ... } }
        final data = responseData['data'] ?? responseData;
        return TetrisLeaderboardEntry.fromJson(data);
      } else if (response.statusCode == 404) {
        print('User chưa có điểm số nào');
        return null;
      } else if (response.statusCode == 401) {
        print('Lỗi xác thực khi lấy điểm (401) - Token có thể không đúng hoặc đã hết hạn');
        return null;
      } else {
        print('Error getting my best score: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting my best score: $e');
      return null;
    }
  }
}

