import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../main_navigation_screen.dart';
import 'registration_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hiển thị thông báo với UI đẹp hơn
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
      ),
    );
  }


  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(
        _emailOrPhoneController.text.trim(),
        _passwordController.text,
      );

      if (result['success']) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
        }
      } else {
        _showMessage(
          result['message'] ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage(
        'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- HẾT PHẦN LOGIC ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- THAY ĐỔI 4: Điều chỉnh khoảng cách ---
                const SizedBox(height: 40),

                // --- THAY ĐỔI 1: Header/Logo đơn giản và hiện đại hơn ---
                Image.asset(
                  'images/logo.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                ),
                // --- HẾT THAY ĐỔI 1 ---

                const SizedBox(height: 32),

                // Tiêu đề
                Text(
                  'Đăng Nhập',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Chào mừng bạn quay trở lại!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Form đăng nhập
                _buildInputField(
                  controller: _emailOrPhoneController,
                  label: 'Email hoặc Số điện thoại',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email hoặc số điện thoại';
                    }
                    return null;
                  },
                ),

              
                const SizedBox(height: 16),

                _buildInputField(
                  controller: _passwordController,
                  label: 'Mật khẩu', // Đổi 'hint' thành 'label'
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      }
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),

                // --- THAY ĐỔI 4: Điều chỉnh khoảng cách ---
                const SizedBox(height: 32),

                // Nút đăng nhập
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Đăng Nhập',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // --- THAY ĐỔI 3: Loại bỏ nút "Test kết nối" khỏi UI ---
                // Đã xóa TextButton.icon và SizedBox(height: 8) ở đây

                // --- THAY ĐỔI 4: Điều chỉnh khoảng cách ---
                const SizedBox(height: 24),


                // Link đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- THAY ĐỔI 2: Dùng labelText để UI gọn gàng hơn ---
  Widget _buildInputField({
    required TextEditingController controller,
    required String label, // Đổi 'hint' thành 'label' cho rõ nghĩa
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label, // Sử dụng labelText
        // hintText: hint, // Không cần hint nữa vì đã có label
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

}