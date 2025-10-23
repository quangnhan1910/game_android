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

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        //Lấy thông tin tên đăng nhập và password
        body: jsonEncode({
          "UsernameOrEmail": username,
          "Password": password,
        }),
      );

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

        return {
          "success": true,
          "token": token,
          "decodedToken": decodedToken,
        };
      } else {
        // If status code is not 200, treat it as login failure
        return {"success": false, "message": "Đăng nhập thất bại. Mã lỗi: ${response.statusCode}"};
      }
    } catch (e) {
      // Handle network or parsing errors
      return {"success": false, "message": "Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn."};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String? initials,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(registerApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Username": username,
          "Email": email,
          "Password": password,
          "Initials": initials,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool status = data['status'] ?? false;
        
        if (status) {
          return {
            "success": true,
            "message": data['message'] ?? "Đăng ký thành công!"
          };
        } else {
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
        
        return {
          "success": false,
          "message": errorMessage
        };
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn."};
    }
  }
}
