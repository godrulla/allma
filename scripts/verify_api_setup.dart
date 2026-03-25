#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Simple script to verify API setup for Allma
/// Run with: dart scripts/verify_api_setup.dart

void main() async {
  print('🔑 Allma API Setup Verification');
  print('================================\n');

  // Check if .env file exists
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('❌ .env file not found!');
    print('   Create a .env file in the project root with your API keys.');
    exit(1);
  }

  print('✅ .env file found');

  // Read and parse .env file
  final envContent = await envFile.readAsString();
  final envVars = <String, String>{};

  for (final line in envContent.split('\n')) {
    if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
    
    final parts = line.split('=');
    if (parts.length >= 2) {
      final key = parts[0].trim();
      final value = parts.sublist(1).join('=').trim();
      envVars[key] = value;
    }
  }

  // Check required API keys
  await _checkGeminiApiKey(envVars);
  await _checkOptionalConfigs(envVars);
  await _checkPermissions();

  print('\n🎉 Setup verification complete!');
  print('   You can now run: flutter run');
}

Future<void> _checkGeminiApiKey(Map<String, String> envVars) async {
  print('\n📝 Checking Gemini API Key...');
  
  final apiKey = envVars['GEMINI_API_KEY'];
  
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ GEMINI_API_KEY not found in .env file');
    return;
  }

  if (apiKey == 'your_gemini_api_key_here') {
    print('❌ Please replace the placeholder with your actual Gemini API key');
    print('   Get one from: https://makersuite.google.com/app/apikey');
    return;
  }

  if (!apiKey.startsWith('AIza')) {
    print('⚠️  API key format looks unusual (should start with "AIza")');
    print('   Please verify this is a valid Gemini API key');
  } else {
    print('✅ Gemini API key format looks correct');
  }

  // Test API key (simple validation)
  print('🔄 Testing API connection...');
  try {
    final result = await Process.run('curl', [
      '-s',
      '-o', '/dev/null',
      '-w', '%{http_code}',
      'https://generativelanguage.googleapis.com/v1/models?key=$apiKey'
    ]);

    final statusCode = result.stdout.toString().trim();
    if (statusCode == '200') {
      print('✅ API key is valid and working!');
    } else if (statusCode == '403') {
      print('❌ API key is invalid or APIs not enabled');
      print('   Enable APIs at: https://console.cloud.google.com/apis/library');
    } else {
      print('⚠️  API test returned status: $statusCode');
    }
  } catch (e) {
    print('⚠️  Could not test API (curl not available)');
    print('   Test manually in the app');
  }
}

Future<void> _checkOptionalConfigs(Map<String, String> envVars) async {
  print('\n⚙️  Checking optional configurations...');

  final configs = {
    'DEBUG_MODE': envVars['DEBUG_MODE'] ?? 'not set',
    'GEMINI_MODEL': envVars['GEMINI_MODEL'] ?? 'default',
    'IMAGE_MODEL': envVars['IMAGE_MODEL'] ?? 'default',
  };

  for (final entry in configs.entries) {
    print('   ${entry.key}: ${entry.value}');
  }

  print('✅ Optional configs checked');
}

Future<void> _checkPermissions() async {
  print('\n🔐 Checking required permissions...');

  // Check if pubspec.yaml has required permissions
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final pubspecContent = await pubspecFile.readAsString();
    
    final requiredDeps = [
      'speech_to_text',
      'flutter_tts', 
      'record',
      'audioplayers',
      'image_picker',
      'permission_handler'
    ];

    for (final dep in requiredDeps) {
      if (pubspecContent.contains(dep)) {
        print('✅ $dep dependency found');
      } else {
        print('❌ $dep dependency missing');
      }
    }
  }

  // Check platform-specific permission files
  await _checkAndroidPermissions();
  await _checkiOSPermissions();
}

Future<void> _checkAndroidPermissions() async {
  final androidManifest = File('android/app/src/main/AndroidManifest.xml');
  if (await androidManifest.exists()) {
    final content = await androidManifest.readAsString();
    
    final requiredPermissions = [
      'android.permission.RECORD_AUDIO',
      'android.permission.INTERNET',
      'android.permission.CAMERA',
    ];

    print('\n📱 Android permissions:');
    for (final permission in requiredPermissions) {
      if (content.contains(permission)) {
        print('✅ $permission');
      } else {
        print('❌ $permission (add to AndroidManifest.xml)');
      }
    }
  }
}

Future<void> _checkiOSPermissions() async {
  final infoPlist = File('ios/Runner/Info.plist');
  if (await infoPlist.exists()) {
    final content = await infoPlist.readAsString();
    
    final requiredPermissions = [
      'NSMicrophoneUsageDescription',
      'NSCameraUsageDescription',
      'NSPhotoLibraryUsageDescription',
    ];

    print('\n🍎 iOS permissions:');
    for (final permission in requiredPermissions) {
      if (content.contains(permission)) {
        print('✅ $permission');
      } else {
        print('❌ $permission (add to Info.plist)');
      }
    }
  }
}