import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../conversation_storage.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/services/encryption_service.dart';

/// Provider for conversation storage service
final conversationStorageProvider = Provider<ConversationStorage>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final encryptionService = ref.read(encryptionServiceProvider);
  
  return ConversationStorage(
    storageService: storageService,
    encryptionService: encryptionService,
  );
});

/// Provider for storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Provider for encryption service
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService.instance;
});