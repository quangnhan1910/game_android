import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';

void main() {
  runApp(const ProviderScope(child: RubikApp()));
}

class RubikApp extends StatelessWidget {
  const RubikApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Collection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.home,
    );
  }
}
