import 'package:flutter/material.dart';
import '../routes.dart';
import '../utils/auth.dart';
import 'auth/login_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  // Hàm xử lý logout
  Future<void> _handleLogout(BuildContext context) async {
    // Hiển thị dialog xác nhận
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.orange),
              SizedBox(width: 10),
              Text('Xác nhận đăng xuất'),
            ],
          ),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Thực hiện logout
      bool success = await Auth.logout();
      
      if (success && context.mounted) {
        // Chuyển về màn hình login và xóa toàn bộ lịch sử navigation
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã đăng xuất thành công'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Collection'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Chọn Game',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),

              // Grid layout cho 4 game
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    // Rubik Game Button
                    _buildGameCard(
                      context,
                      icon: Icons.extension,
                      title: 'Rubik 3×3',
                      subtitle: 'Giải khối Rubik',
                      colors: [Colors.orange.shade300, Colors.red.shade300],
                      route: AppRoutes.rubikHome,
                    ),

                    // Tetris Game Button
                    _buildGameCard(
                      context,
                      icon: Icons.grid_4x4,
                      title: 'Tetris',
                      subtitle: 'Xếp hình cổ điển',
                      colors: [Colors.green.shade300, Colors.blue.shade300],
                      route: AppRoutes.tetris,
                    ),

                    // Sudoku Game Button
                    _buildGameCard(
                      context,
                      icon: Icons.grid_3x3,
                      title: 'Sudoku',
                      subtitle: 'Trò chơi số học',
                      colors: [Colors.indigo.shade300, Colors.teal.shade300],
                      route: AppRoutes.sudoku,
                    ),

                    // Caro Game Button
                    _buildGameCard(
                      context,
                      icon: Icons.grid_on,
                      title: 'Caro vs AI',
                      subtitle: 'Trí tuệ nhân tạo',
                      colors: [Colors.purple.shade300, Colors.pink.shade300],
                      route: AppRoutes.caro,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required String route,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
