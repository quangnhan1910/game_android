import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sudoku/sudoku_leaderboard_models.dart';
import '../config/config_url.dart';
import 'auth_service.dart';

class SudokuLeaderboardService {
  final String baseUrl;
  final AuthService _authService = AuthService();

  SudokuLeaderboardService({String? baseUrl})
      : baseUrl = baseUrl ?? Config_URL.baseUrl;

  /// Gửi thời gian hoàn thành lên server
  Future<Map<String, dynamic>> submitTime({
    required int time,
    required String difficulty,
  }) async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Bạn cần đăng nhập để gửi thời gian',
        };
      }

      print('Gửi thời gian Sudoku: time=$time, difficulty=$difficulty');

      final response = await http.post(
        Uri.parse('${baseUrl}sudoku/leaderboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'time': time,
          'difficulty': difficulty,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Đã gửi thời gian thành công!',
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Lỗi khi gửi thời gian',
        };
      }
    } catch (e) {
      print('Error submitting time: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  /// Lấy danh sách bảng xếp hạng theo độ khó
  Future<SudokuLeaderboardResponse?> getLeaderboard({
    required String difficulty,
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
        Uri.parse(
            '${baseUrl}sudoku/leaderboard?difficulty=$difficulty&limit=$limit&offset=$offset'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Backend trả về { success, message, data: [...] }
        final data = responseData['data'] ?? responseData;
        
        print('Sudoku leaderboard data count: ${(data as List).length}');
        if ((data as List).isNotEmpty) {
          print('First entry sample: ${data[0]}');
        }
        
        return SudokuLeaderboardResponse(
          entries: (data as List)
              .map((entry) => SudokuLeaderboardEntry.fromJson(entry))
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

  /// Lấy thời gian tốt nhất của người dùng hiện tại theo độ khó
  Future<SudokuLeaderboardEntry?> getMyBestTime(String difficulty) async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        print('Không có token để lấy thời gian của user');
        return null;
      }

      // Kiểm tra token có hợp lệ không
      if (!_authService.isTokenValid(token)) {
        print('Token đã hết hạn, không thể lấy thời gian của user');
        return null;
      }

      print('Đang gọi API /sudoku/leaderboard/me với difficulty=$difficulty');

      final response = await http.get(
        Uri.parse('${baseUrl}sudoku/leaderboard/me?difficulty=$difficulty'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status /me: ${response.statusCode}');
      print('Response body /me: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Backend trả về { success, message, data: { bestTime, difficulty, ... } }
        final data = responseData['data'] ?? responseData;
        
        print('Parsed data for Sudoku /me: $data');
        print('Time from data: ${data['time']} or bestTime: ${data['bestTime']}');
        
        return SudokuLeaderboardEntry.fromJson(data);
      } else if (response.statusCode == 404) {
        print('User chưa có thời gian nào cho độ khó $difficulty');
        return null;
      } else if (response.statusCode == 401) {
        print('Lỗi xác thực khi lấy thời gian (401) - Token có thể không đúng hoặc đã hết hạn');
        return null;
      } else {
        print('Error getting my best time: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting my best time: $e');
      return null;
    }
  }
}

