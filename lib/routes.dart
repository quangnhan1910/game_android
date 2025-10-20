import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/pick_colors_screen.dart';
import 'screens/solve_screen.dart';

class AppRoutes {
  static const home = '/';
  static const pick = '/pick';
  static const solve = '/solve';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
    pick: (context) => const PickColorsScreen(),
    solve: (context) => const SolveScreen(),
  };
}
