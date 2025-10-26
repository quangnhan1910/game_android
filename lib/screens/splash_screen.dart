import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Delay nhỏ để hiển thị splash screen
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Kiểm tra tự động đăng nhập
    final result = await _authService.autoLogin();

    if (!mounted) return;

    if (result['success'] == true) {
      // Token hợp lệ, chuyển đến màn hình chính
      print('[SplashScreen] Auto login successful, navigating to main menu');
      Navigator.of(context).pushReplacementNamed(AppRoutes.mainMenu);
    } else {
      // Token không hợp lệ hoặc không tồn tại, chuyển đến màn hình đăng nhập
      print('[SplashScreen] Auto login failed: ${result['message']}');
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo hoặc icon của app
            Icon(
              Icons.games,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            // Tên ứng dụng
            const Text(
              'Game Collection',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đang kiểm tra đăng nhập...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

