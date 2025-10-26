import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/rubik/rubik_home_screen.dart';
import 'screens/rubik/pick_colors_screen.dart';
import 'screens/rubik/solve_screen.dart';
import 'screens/xep_hinh/tetris_screen.dart';
import 'screens/caro/caro_screen.dart';
import 'providers/sudoku/difficulty_sudoku.dart';

class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const mainMenu = '/main-menu';
  static const rubikHome = '/rubik-home';
  static const pick = '/pick';
  static const solve = '/solve';
  static const tetris = '/tetris';
  static const caro = '/caro';
  static const sudoku = '/sudoku';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const LoginScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    mainMenu: (context) => const MainNavigationScreen(),
    rubikHome: (context) => const rubikHomeScreen(),
    pick: (context) => const PickColorsScreen(),
    solve: (context) => const SolveScreen(),
    tetris: (context) => const TetrisScreen(),
    caro: (context) => const ManHinhGameCaro(),
    sudoku: (context) => const DifficultySudoku(),
  };
}
