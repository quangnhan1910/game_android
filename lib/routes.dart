import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';
import 'screens/rubik_home_screen.dart';
import 'screens/pick_colors_screen.dart';
import 'screens/solve_screen.dart';
import 'screens/tetris_screen.dart';

class AppRoutes {
  static const home = '/';
  static const mainMenu = '/main-menu';
  static const rubikHome = '/rubik-home';
  static const pick = '/pick';
  static const solve = '/solve';
  static const tetris = '/tetris';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const MainMenuScreen(),
    mainMenu: (context) => const MainMenuScreen(),
    rubikHome: (context) => const rubikHomeScreen(),
    pick: (context) => const PickColorsScreen(),
    solve: (context) => const SolveScreen(),
    tetris: (context) => const TetrisScreen(),
  };
}
