import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (handle missing .env gracefully)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    // Set default values for testing
    dotenv.env['GEMINI_API_KEY'] = 'demo_key_for_testing';
    dotenv.env['DEBUG_MODE'] = 'true';
  }
  
  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: AllmaApp(),
    ),
  );
}