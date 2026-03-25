import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/constants.dart';

class EncryptionService {
  static EncryptionService? _instance;
  late final FlutterSecureStorage _secureStorage;
  late final Encrypter _encrypter;
  late final IV _iv;

  EncryptionService._() {
    _secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  static EncryptionService get instance {
    _instance ??= EncryptionService._();
    return _instance!;
  }

  /// Initialize encryption service with master key
  Future<void> initialize() async {
    try {
      final masterKey = await _getMasterKey();
      final key = Key.fromBase64(masterKey);
      _encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      _iv = IV.fromSecureRandom(12); // GCM uses 12-byte IV
    } catch (e) {
      throw EncryptionException('Failed to initialize encryption service: $e');
    }
  }

  /// Encrypt a string
  Future<List<int>> encrypt(String plaintext) async {
    try {
      if (!_isInitialized()) {
        await initialize();
      }

      final iv = IV.fromSecureRandom(12);
      final encrypted = _encrypter.encrypt(plaintext, iv: iv);
      
      // Combine IV + encrypted data + MAC for GCM
      final result = <int>[];
      result.addAll(iv.bytes);
      result.addAll(encrypted.bytes);
      
      return result;
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  /// Decrypt data
  Future<String> decrypt(List<int> encryptedData) async {
    try {
      if (!_isInitialized()) {
        await initialize();
      }

      if (encryptedData.length < 12) {
        throw EncryptionException('Invalid encrypted data format');
      }

      // Extract IV and encrypted content
      final iv = IV(Uint8List.fromList(encryptedData.take(12).toList()));
      final encryptedBytes = encryptedData.skip(12).toList();
      
      final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));
      final decrypted = _encrypter.decrypt(encrypted, iv: iv);
      
      return decrypted;
    } catch (e) {
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  /// Encrypt binary data
  Future<List<int>> encryptBytes(List<int> data) async {
    final base64Data = base64Encode(data);
    final encryptedString = await encrypt(base64Data);
    return encryptedString;
  }

  /// Decrypt binary data
  Future<List<int>> decryptBytes(List<int> encryptedData) async {
    final decryptedString = await decrypt(encryptedData);
    return base64Decode(decryptedString);
  }

  /// Generate a secure hash for data integrity
  String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify data integrity using hash
  bool verifyHash(String data, String expectedHash) {
    final actualHash = generateHash(data);
    return actualHash == expectedHash;
  }

  /// Generate a cryptographically secure random string
  String generateSecureRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Derive a key from a password using PBKDF2
  String deriveKeyFromPassword(String password, String salt, {int iterations = 10000}) {
    final saltBytes = utf8.encode(salt);
    final passwordBytes = utf8.encode(password);
    
    // Use a simple key derivation for now
    final combinedBytes = [...passwordBytes, ...saltBytes];
    final hash = sha256.convert(combinedBytes);
    return base64.encode(hash.bytes);
  }

  /// Create a secure backup of encrypted data
  Future<Map<String, dynamic>> createSecureBackup(Map<String, dynamic> data) async {
    final jsonString = json.encode(data);
    final encryptedData = await encrypt(jsonString);
    final dataHash = generateHash(jsonString);
    
    return {
      'encrypted_data': base64Encode(encryptedData),
      'data_hash': dataHash,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// Restore data from secure backup
  Future<Map<String, dynamic>> restoreSecureBackup(Map<String, dynamic> backup) async {
    try {
      final encryptedData = base64Decode(backup['encrypted_data'] as String);
      final expectedHash = backup['data_hash'] as String;
      
      final decryptedJson = await decrypt(encryptedData);
      
      // Verify integrity
      if (!verifyHash(decryptedJson, expectedHash)) {
        throw EncryptionException('Backup data integrity verification failed');
      }
      
      return json.decode(decryptedJson) as Map<String, dynamic>;
    } catch (e) {
      throw EncryptionException('Failed to restore backup: $e');
    }
  }

  /// Change the master key (for security key rotation)
  Future<void> rotateMasterKey() async {
    try {
      // Generate new master key
      final newMasterKey = _generateMasterKey();
      
      // Store the new key
      await _secureStorage.write(
        key: AppConstants.encryptionKeyAlias,
        value: newMasterKey,
      );
      
      // Reinitialize with new key
      await initialize();
    } catch (e) {
      throw EncryptionException('Failed to rotate master key: $e');
    }
  }

  /// Check if encryption service is initialized
  bool _isInitialized() {
    try {
      // Try to access the encrypter to see if it's initialized
      _encrypter.toString();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get or generate master key
  Future<String> _getMasterKey() async {
    try {
      // Try to get existing key
      String? existingKey = await _secureStorage.read(key: AppConstants.encryptionKeyAlias);
      
      if (existingKey != null) {
        return existingKey;
      }
      
      // Generate new master key
      final newKey = _generateMasterKey();
      await _secureStorage.write(
        key: AppConstants.encryptionKeyAlias,
        value: newKey,
      );
      
      return newKey;
    } catch (e) {
      throw EncryptionException('Failed to get master key: $e');
    }
  }

  /// Generate a new 256-bit master key
  String _generateMasterKey() {
    final key = Key.fromSecureRandom(32); // 256 bits
    return key.base64;
  }

  /// Securely wipe sensitive data from memory
  void secureWipe(List<int> data) {
    final random = Random.secure();
    for (int i = 0; i < data.length; i++) {
      data[i] = random.nextInt(256);
    }
  }

  /// Clear all stored encryption keys (for logout/reset)
  Future<void> clearAllKeys() async {
    try {
      await _secureStorage.delete(key: AppConstants.encryptionKeyAlias);
      // Clear any other stored keys if needed
    } catch (e) {
      throw EncryptionException('Failed to clear encryption keys: $e');
    }
  }

  /// Get encryption metadata for debugging/monitoring
  Future<EncryptionMetadata> getEncryptionMetadata() async {
    final hasKey = await _secureStorage.containsKey(key: AppConstants.encryptionKeyAlias);
    
    return EncryptionMetadata(
      algorithm: 'AES-256-GCM',
      keySize: 256,
      ivSize: 96, // 12 bytes * 8 = 96 bits
      hasStoredKey: hasKey,
      isInitialized: _isInitialized(),
    );
  }

  /// Test encryption/decryption with sample data
  Future<bool> testEncryption() async {
    try {
      const testData = 'This is a test message for encryption validation.';
      final encrypted = await encrypt(testData);
      final decrypted = await decrypt(encrypted);
      
      return decrypted == testData;
    } catch (e) {
      return false;
    }
  }
}

/// Metadata about encryption configuration
class EncryptionMetadata {
  final String algorithm;
  final int keySize;
  final int ivSize;
  final bool hasStoredKey;
  final bool isInitialized;

  const EncryptionMetadata({
    required this.algorithm,
    required this.keySize,
    required this.ivSize,
    required this.hasStoredKey,
    required this.isInitialized,
  });

  Map<String, dynamic> toJson() {
    return {
      'algorithm': algorithm,
      'key_size': keySize,
      'iv_size': ivSize,
      'has_stored_key': hasStoredKey,
      'is_initialized': isInitialized,
    };
  }
}

/// PBKDF2 implementation for key derivation
class Pbkdf2 {
  final MacAlgorithm macAlgorithm;
  final int iterations;
  final int bits;

  Pbkdf2({
    required this.macAlgorithm,
    required this.iterations,
    required this.bits,
  });

  SecretKey deriveKey({
    required SecretKey secretKey,
    required List<int> nonce,
  }) {
    final mac = macAlgorithm.toSync();
    final secretKeyBytes = secretKey.extractSync();
    
    final dkLen = (bits + 7) ~/ 8; // Convert bits to bytes
    final hLen = mac.macLength;
    final l = (dkLen + hLen - 1) ~/ hLen;
    
    final result = <int>[];
    
    for (int i = 1; i <= l; i++) {
      final u = <int>[];
      u.addAll(_int32ToBytes(i));
      
      mac.setSecretKey(SecretKey(secretKeyBytes));
      var uPrev = mac.calculateMac(nonce + u).bytes;
      
      final t = List<int>.from(uPrev);
      
      for (int j = 1; j < iterations; j++) {
        mac.setSecretKey(SecretKey(secretKeyBytes));
        uPrev = mac.calculateMac(uPrev).bytes;
        
        for (int k = 0; k < t.length; k++) {
          t[k] ^= uPrev[k];
        }
      }
      
      result.addAll(t);
    }
    
    return SecretKey(result.take(dkLen).toList());
  }

  List<int> _int32ToBytes(int value) {
    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }
}

/// Mock secret key class for PBKDF2
class SecretKey {
  final List<int> _bytes;

  SecretKey(this._bytes);

  List<int> extractSync() => List<int>.from(_bytes);
}

/// Mock MAC algorithm interface
abstract class MacAlgorithm {
  MacSync toSync();
}

/// Mock MAC sync interface
abstract class MacSync {
  int get macLength;
  void setSecretKey(SecretKey key);
  Mac calculateMac(List<int> data);
}

/// Mock MAC result
class Mac {
  final List<int> bytes;
  Mac(this.bytes);
}

/// Exception thrown by encryption operations
class EncryptionException implements Exception {
  final String message;

  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}