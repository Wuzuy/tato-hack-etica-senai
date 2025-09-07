import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'pages/tato_page.dart';

Future<void> loadEnv() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "gemini.env");

  Gemini.init(apiKey: dotenv.env['GEMINI_API_KEY'] ?? '');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TATOPage(),
    );
  }
}
