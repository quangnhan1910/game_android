import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import 'models/kociemba.dart';

void main() {
  // Warm-up Kociemba solver để tăng tốc độ lần đầu
  _warmUpSolver();
  runApp(const ProviderScope(child: RubikApp()));
}

void _warmUpSolver() {
  // Tạo khối Rubik đã giải để warm-up solver
  // Cube đã giải: U(0-8), R(9-17), F(18-26), D(27-35), L(36-44), B(45-53)
  final solvedCube = 'UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB';
  print('🔍 [DEBUG] Warm-up cube: ${solvedCube.substring(0, 20)}...');
  try {
    // Không warm-up nữa vì cube validation failed
    print('⚠️ [DEBUG] Skipping warm-up due to validation issues');
  } catch (e) {
    print('❌ [DEBUG] Warm-up failed: $e');
    // Ignore errors during warm-up
  }
}

class RubikApp extends StatelessWidget {
  const RubikApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rubik 3×3 Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.home,
    );
  }
}
