import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_url.dart';

class AuthService {
  // đường dẫn tới API login
  String get apiUrl => "${Config_URL.baseUrl}Authenticate/login";
  
  // đường dẫn tới API register
  String get registerApiUrl => "${Config_URL.baseUrl}Authenticate/register";
  
  // Timeout cho các request
  static const Duration timeoutDuration = Duration(seconds: 15);

  Future<Map<String, dynamic>> login(String emailOrPhone, String password) async {
    try {
      print('\n[AuthService] ===== LOGIN START =====');
      print('[AuthService] API URL: $apiUrl');
      print('[AuthService] Email/Phone: $emailOrPhone');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        //Lấy thông tin email/số điện thoại và password
        body: jsonEncode({
          "EmailOrPhone": emailOrPhone,
          "Password": password,
        }),
      ).timeout(timeoutDuration);

      print('[AuthService] Response Status: ${response.statusCode}');
      print('[AuthService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool status = data['status'];
        if (!status) {
          return {"success": false, "message": data['message']};
        }
        //lấy token trả về
        String token = data['token'];
        // Decode token để lấy các thông tin đăng nhập: tên đăng nhập, role...
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

        // Lưu token vào SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('jwt_token', token);  // Lưu token

        print('[AuthService] Login SUCCESS ✓');
        print('[AuthService] ===== LOGIN END =====\n');
        return {
          "success": true,
          "token": token,
          "decodedToken": decodedToken,
        };
      } else {
        // Xử lý các mã lỗi cụ thể
        print('[AuthService] Login FAILED: Status ${response.statusCode}');
        print('[AuthService] ===== LOGIN END =====\n');
        
        String errorMessage;
        if (response.statusCode == 401) {
          // Unauthorized - Sai tên đăng nhập hoặc mật khẩu
          errorMessage = "Sai tên đăng nhập hoặc mật khẩu.";
        } else if (response.statusCode == 400) {
          // Bad Request - Dữ liệu không hợp lệ
          errorMessage = "Thông tin đăng nhập không hợp lệ.";
        } else if (response.statusCode == 500) {
          // Server Error
          errorMessage = "Lỗi máy chủ. Vui lòng thử lại sau.";
        } else {
          // Các lỗi khác
          errorMessage = "Đăng nhập thất bại. Vui lòng thử lại.";
        }
        
        return {"success": false, "message": errorMessage};
      }
    } catch (e) {
      // Handle network or parsing errors
      print('[AuthService] Login ERROR: $e');
      print('[AuthService] ===== LOGIN END =====\n');
      return {"success": false, "message": "Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn."};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
    required String? initials,
  }) async {
    try {
      print('\n[AuthService] ===== REGISTER START =====');
      print('[AuthService] API URL: $registerApiUrl');
      print('[AuthService] Username: $username');
      print('[AuthService] Email: $email');
      
      final response = await http.post(
        Uri.parse(registerApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Username": username,
          "Email": email,
          "PhoneNumber": phoneNumber,
          "Password": password,
          "Initials": initials,
        }),
      ).timeout(timeoutDuration);

      print('[AuthService] Response Status: ${response.statusCode}');
      print('[AuthService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool status = data['status'] ?? false;
        
        if (status) {
          print('[AuthService] Register SUCCESS ✓');
          print('[AuthService] ===== REGISTER END =====\n');
          return {
            "success": true,
            "message": data['message'] ?? "Đăng ký thành công!"
          };
        } else {
          print('[AuthService] Register FAILED: ${data['message']}');
          print('[AuthService] ===== REGISTER END =====\n');
          return {
            "success": false,
            "message": data['message'] ?? "Đăng ký thất bại"
          };
        }
      } else {
        // Parse error response for more details
        String errorMessage = "Đăng ký thất bại (${response.statusCode})";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['errors'] != null) {
            // Handle validation errors
            errorMessage = errorData['errors'].toString();
          }
        } catch (e) {
          errorMessage = "Đăng ký thất bại: ${response.body}";
        }
        
        print('[AuthService] Register ERROR: $errorMessage');
        print('[AuthService] ===== REGISTER END =====\n');
        return {
          "success": false,
          "message": errorMessage
        };
      }
    } catch (e) {
      print('[AuthService] Register EXCEPTION: $e');
      print('[AuthService] ===== REGISTER END =====\n');
      return {"success": false, "message": "Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn."};
    }
  }

  // Đăng xuất - xóa token khỏi SharedPreferences
  Future<bool> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');  // Xóa token
      return true;
    } catch (e) {
      return false;
    }
  }

  // Lấy token đã lưu từ SharedPreferences
  Future<String?> getStoredToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt_token');
    } catch (e) {
      print('[AuthService] Error getting stored token: $e');
      return null;
    }
  }

  // Kiểm tra token có hợp lệ không (còn hạn sử dụng)
  bool isTokenValid(String token) {
    try {
      // Kiểm tra token có bị hết hạn không
      bool isExpired = JwtDecoder.isExpired(token);
      return !isExpired;
    } catch (e) {
      print('[AuthService] Error checking token validity: $e');
      return false;
    }
  }

  // Tự động đăng nhập với token đã lưu
  Future<Map<String, dynamic>> autoLogin() async {
    try {
      print('\n[AuthService] ===== AUTO LOGIN START =====');
      
      // Lấy token đã lưu
      String? token = await getStoredToken();
      
      if (token == null) {
        print('[AuthService] No stored token found');
        print('[AuthService] ===== AUTO LOGIN END =====\n');
        return {"success": false, "message": "Không tìm thấy token"};
      }

      // Kiểm tra token có còn hạn không
      if (!isTokenValid(token)) {
        print('[AuthService] Token expired');
        // Xóa token hết hạn
        await logout();
        print('[AuthService] ===== AUTO LOGIN END =====\n');
        return {"success": false, "message": "Token đã hết hạn"};
      }

      // Token hợp lệ, decode để lấy thông tin
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      print('[AuthService] Auto login SUCCESS ✓');
      print('[AuthService] ===== AUTO LOGIN END =====\n');
      
      return {
        "success": true,
        "token": token,
        "decodedToken": decodedToken,
      };
    } catch (e) {
      print('[AuthService] Auto login ERROR: $e');
      print('[AuthService] ===== AUTO LOGIN END =====\n');
      return {"success": false, "message": "Lỗi tự động đăng nhập: $e"};
    }
  }
}
