# Allma Privacy & Security Documentation

## Privacy-First Architecture

Allma is built with privacy as a core principle. All personal data remains on the user's device, and conversations are encrypted end-to-end.

## Data Collection Policy

### What We Collect
- **Nothing Personal**: No names, emails, or personal identifiers
- **Anonymous Usage**: App performance metrics only
- **Local Storage**: All conversations stored locally on device

### What We Don't Collect
- Conversation content
- Personal information
- Location data
- Device identifiers
- Biometric data

## Local Data Storage

### Database Encryption

All local data is encrypted using AES-256-GCM encryption:

```dart
class DatabaseEncryption {
  static const String keyAlias = 'allma_master_key';
  
  // Generate or retrieve master key from Android Keystore / iOS Keychain
  Future<Uint8List> getMasterKey() async {
    final secureStorage = FlutterSecureStorage();
    
    String? keyString = await secureStorage.read(key: keyAlias);
    if (keyString == null) {
      // Generate new key
      final key = Uint8List.fromList(List.generate(32, (i) => Random.secure().nextInt(256)));
      await secureStorage.write(key: keyAlias, value: base64Encode(key));
      return key;
    }
    
    return base64Decode(keyString);
  }
  
  Future<Uint8List> encrypt(String plaintext) async {
    final key = await getMasterKey();
    final iv = Uint8List.fromList(List.generate(12, (i) => Random.secure().nextInt(256)));
    
    final encrypter = Encrypter(AES(Key(key), mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: IV(iv));
    
    // Combine IV + encrypted data
    final result = Uint8List(iv.length + encrypted.bytes.length);
    result.setRange(0, iv.length, iv);
    result.setRange(iv.length, result.length, encrypted.bytes);
    
    return result;
  }
  
  Future<String> decrypt(Uint8List ciphertext) async {
    final key = await getMasterKey();
    final iv = ciphertext.sublist(0, 12);
    final encrypted = ciphertext.sublist(12);
    
    final encrypter = Encrypter(AES(Key(key), mode: AESMode.gcm));
    return encrypter.decrypt(Encrypted(encrypted), iv: IV(iv));
  }
}
```

### Secure Companion Storage

```dart
class SecureCompanionRepository {
  final DatabaseEncryption _encryption = DatabaseEncryption();
  final Database _database;
  
  Future<void> saveCompanion(Companion companion) async {
    final jsonData = json.encode(companion.toJson());
    final encryptedData = await _encryption.encrypt(jsonData);
    
    await _database.insert('companions', {
      'id': companion.id,
      'encrypted_data': encryptedData,
      'created_at': companion.createdAt.millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  Future<Companion?> getCompanion(String id) async {
    final result = await _database.query(
      'companions',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    
    final encryptedData = result.first['encrypted_data'] as Uint8List;
    final decryptedJson = await _encryption.decrypt(encryptedData);
    return Companion.fromJson(json.decode(decryptedJson));
  }
}
```

### Conversation Encryption

```dart
class SecureConversationRepository {
  Future<void> saveMessage({
    required String companionId,
    required String userMessage,
    required String companionResponse,
  }) async {
    final conversation = ConversationEntry(
      id: _generateId(),
      companionId: companionId,
      userMessage: userMessage,
      companionResponse: companionResponse,
      timestamp: DateTime.now(),
    );
    
    final encryptedData = await _encryption.encrypt(
      json.encode(conversation.toJson()),
    );
    
    await _database.insert('conversations', {
      'id': conversation.id,
      'companion_id': companionId,
      'encrypted_data': encryptedData,
      'timestamp': conversation.timestamp.millisecondsSinceEpoch,
    });
  }
}
```

## Network Security

### API Communication

All API calls to Google services use HTTPS with certificate pinning:

```dart
class SecureApiClient {
  static Dio createSecureClient() {
    final dio = Dio();
    
    // Certificate pinning for Google APIs
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (cert, host, port) {
        // Verify Google's certificate
        return _verifyGoogleCertificate(cert, host);
      };
      return client;
    };
    
    // Add security headers
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['User-Agent'] = 'Allma/1.0';
        options.headers['Accept'] = 'application/json';
        handler.next(options);
      },
    ));
    
    return dio;
  }
}
```

### API Key Protection

```dart
class ApiKeyManager {
  static const String _apiKeyKey = 'gemini_api_key';
  
  Future<void> storeApiKey(String apiKey) async {
    final secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: IOSAccessibility.first_unlock_this_device,
      ),
    );
    
    await secureStorage.write(key: _apiKeyKey, value: apiKey);
  }
  
  Future<String?> getApiKey() async {
    final secureStorage = FlutterSecureStorage();
    return await secureStorage.read(key: _apiKeyKey);
  }
}
```

## Biometric Authentication

### App Lock Implementation

```dart
class BiometricAuth {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  Future<bool> isBiometricAvailable() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return isAvailable && isDeviceSupported;
  }
  
  Future<bool> authenticateUser() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your companions',
        options: AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }
}
```

### Session Management

```dart
class SessionManager {
  static const Duration sessionTimeout = Duration(minutes: 15);
  Timer? _sessionTimer;
  bool _isLocked = true;
  
  Future<bool> unlockApp() async {
    final biometricAuth = BiometricAuth();
    
    if (await biometricAuth.isBiometricAvailable()) {
      final authenticated = await biometricAuth.authenticateUser();
      if (authenticated) {
        _isLocked = false;
        _startSessionTimer();
        return true;
      }
    }
    return false;
  }
  
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionTimeout, () {
      _isLocked = true;
    });
  }
  
  void extendSession() {
    if (!_isLocked) {
      _startSessionTimer();
    }
  }
}
```

## Data Anonymization

### Memory Anonymization

```dart
class DataAnonymizer {
  static final Map<RegExp, String> _patterns = {
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'): '[EMAIL]',
    RegExp(r'\b\d{3}-\d{2}-\d{4}\b'): '[SSN]',
    RegExp(r'\b\d{3}-\d{3}-\d{4}\b'): '[PHONE]',
    RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\b'): '[CARD]',
    RegExp(r'\b\d{1,5}\s\w+\s(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr|Court|Ct|Circle|Cir)\b', caseSensitive: false): '[ADDRESS]',
  };
  
  static String anonymizeText(String text) {
    String anonymized = text;
    
    _patterns.forEach((pattern, replacement) {
      anonymized = anonymized.replaceAll(pattern, replacement);
    });
    
    return anonymized;
  }
  
  static MemoryItem anonymizeMemory(MemoryItem memory) {
    return memory.copyWith(
      content: anonymizeText(memory.content),
    );
  }
}
```

## Privacy Controls

### User Privacy Settings

```dart
class PrivacySettings {
  bool dataRetentionEnabled;
  Duration conversationRetentionPeriod;
  bool analyticsEnabled;
  bool crashReportingEnabled;
  bool biometricLockEnabled;
  
  PrivacySettings({
    this.dataRetentionEnabled = true,
    this.conversationRetentionPeriod = const Duration(days: 365),
    this.analyticsEnabled = false,
    this.crashReportingEnabled = false,
    this.biometricLockEnabled = true,
  });
}
```

### Data Deletion

```dart
class DataDeletionService {
  Future<void> deleteAllUserData() async {
    // Delete conversations
    await _database.delete('conversations');
    
    // Delete companions
    await _database.delete('companions');
    
    // Delete memory items
    await _database.delete('memory_items');
    
    // Delete user preferences
    await _database.delete('user_preferences');
    
    // Clear secure storage
    await FlutterSecureStorage().deleteAll();
    
    // Clear caches
    await _clearAllCaches();
  }
  
  Future<void> deleteCompanionData(String companionId) async {
    await _database.delete(
      'conversations',
      where: 'companion_id = ?',
      whereArgs: [companionId],
    );
    
    await _database.delete(
      'companions',
      where: 'id = ?',
      whereArgs: [companionId],
    );
    
    await _database.delete(
      'memory_items',
      where: 'companion_id = ?',
      whereArgs: [companionId],
    );
  }
}
```

## Security Auditing

### Security Checklist

```dart
class SecurityAudit {
  Future<SecurityReport> performSecurityAudit() async {
    final report = SecurityReport();
    
    // Check encryption status
    report.encryptionStatus = await _checkEncryptionStatus();
    
    // Check secure storage
    report.secureStorageStatus = await _checkSecureStorage();
    
    // Check network security
    report.networkSecurityStatus = await _checkNetworkSecurity();
    
    // Check biometric protection
    report.biometricStatus = await _checkBiometricProtection();
    
    // Check for sensitive data exposure
    report.dataExposureRisks = await _scanForDataExposure();
    
    return report;
  }
}
```

## Compliance

### GDPR Compliance

```dart
class GDPRCompliance {
  // Right to Access
  Future<UserDataExport> exportUserData() async {
    return UserDataExport(
      companions: await _companionRepository.getAllCompanions(),
      conversations: await _conversationRepository.getAllConversations(),
      settings: await _settingsRepository.getUserSettings(),
      exportDate: DateTime.now(),
    );
  }
  
  // Right to Erasure
  Future<void> deleteUserData() async {
    await DataDeletionService().deleteAllUserData();
  }
  
  // Right to Portability
  Future<String> exportDataAsJson() async {
    final export = await exportUserData();
    return json.encode(export.toJson());
  }
}
```

### COPPA Compliance

```dart
class COPPACompliance {
  Future<bool> isUserUnder13() async {
    // Age verification logic
    final userAge = await _getUserAge();
    return userAge != null && userAge < 13;
  }
  
  Future<void> enableParentalControls() async {
    if (await isUserUnder13()) {
      // Enable stricter content filtering
      await _enableStrictContentFilter();
      
      // Disable data collection
      await _disableDataCollection();
      
      // Enable parental notification
      await _enableParentalNotification();
    }
  }
}
```

## Incident Response

### Security Incident Handling

```dart
class SecurityIncidentHandler {
  Future<void> reportSecurityIncident({
    required SecurityIncidentType type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final incident = SecurityIncident(
      id: _generateId(),
      type: type,
      description: description,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    // Log locally (encrypted)
    await _logIncidentLocally(incident);
    
    // If severe, prompt user for action
    if (type.severity == Severity.high) {
      await _promptUserForAction(incident);
    }
  }
}
```

This privacy and security documentation ensures Allma maintains the highest standards for user data protection while providing transparency about data handling practices.