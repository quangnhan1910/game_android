import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart' as provider;
import 'routes.dart';
import 'providers/message_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load file .env
  await dotenv.load(fileName: ".env");
  
  runApp(const ProviderScope(child: RubikApp()));
}

class RubikApp extends StatelessWidget {
  const RubikApp({super.key});
  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: MaterialApp(
        title: 'Game Collection',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.home,
      ),
    );
  }
}
