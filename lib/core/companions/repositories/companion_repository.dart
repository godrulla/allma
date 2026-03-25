import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../models/companion.dart';
import '../../../shared/services/encryption_service.dart';
import '../../../shared/services/storage_service.dart';

abstract class CompanionRepository {
  Future<List<Companion>> getAllCompanions();
  Future<Companion?> getCompanion(String id);
  Future<void> saveCompanion(Companion companion);
  Future<void> deleteCompanion(String id);
  Future<void> deleteAllCompanions();
}

class LocalCompanionRepository implements CompanionRepository {
  final StorageService _storageService;
  final EncryptionService _encryptionService;

  LocalCompanionRepository({
    required StorageService storageService,
    required EncryptionService encryptionService,
  })  : _storageService = storageService,
        _encryptionService = encryptionService;

  @override
  Future<List<Companion>> getAllCompanions() async {
    try {
      final database = await _storageService.database;
      final result = await database.query(
        'companions',
        orderBy: 'last_interaction DESC',
      );

      final companions = <Companion>[];
      for (final row in result) {
        final companion = await _decryptCompanion(row);
        if (companion != null) {
          companions.add(companion);
        }
      }

      return companions;
    } catch (e) {
      throw CompanionRepositoryException('Failed to get all companions: $e');
    }
  }

  @override
  Future<Companion?> getCompanion(String id) async {
    try {
      final database = await _storageService.database;
      final result = await database.query(
        'companions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      return await _decryptCompanion(result.first);
    } catch (e) {
      throw CompanionRepositoryException('Failed to get companion: $e');
    }
  }

  @override
  Future<void> saveCompanion(Companion companion) async {
    try {
      final database = await _storageService.database;
      final encryptedData = await _encryptCompanion(companion);

      await database.insert(
        'companions',
        {
          'id': companion.id,
          'encrypted_data': encryptedData,
          'created_at': companion.createdAt.millisecondsSinceEpoch,
          'last_interaction': companion.lastInteraction.millisecondsSinceEpoch,
          'total_interactions': companion.totalInteractions,
          'name_search': companion.name.toLowerCase(), // For search optimization
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CompanionRepositoryException('Failed to save companion: $e');
    }
  }

  @override
  Future<void> deleteCompanion(String id) async {
    try {
      final database = await _storageService.database;
      await database.delete(
        'companions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CompanionRepositoryException('Failed to delete companion: $e');
    }
  }

  @override
  Future<void> deleteAllCompanions() async {
    try {
      final database = await _storageService.database;
      await database.delete('companions');
    } catch (e) {
      throw CompanionRepositoryException('Failed to delete all companions: $e');
    }
  }

  /// Encrypt companion data before storage
  Future<List<int>> _encryptCompanion(Companion companion) async {
    final jsonString = json.encode(companion.toJson());
    return await _encryptionService.encrypt(jsonString);
  }

  /// Decrypt companion data after retrieval
  Future<Companion?> _decryptCompanion(Map<String, dynamic> row) async {
    try {
      final encryptedData = row['encrypted_data'] as List<int>;
      final decryptedJson = await _encryptionService.decrypt(encryptedData);
      final companionData = json.decode(decryptedJson) as Map<String, dynamic>;
      return Companion.fromJson(companionData);
    } catch (e) {
      // Log error but don't throw - data might be corrupted
      print('Failed to decrypt companion data: $e');
      return null;
    }
  }

  /// Search companions by name (optimized with search index)
  Future<List<Companion>> searchByName(String query) async {
    try {
      final database = await _storageService.database;
      final lowerQuery = query.toLowerCase();
      
      final result = await database.query(
        'companions',
        where: 'name_search LIKE ?',
        whereArgs: ['%$lowerQuery%'],
        orderBy: 'last_interaction DESC',
      );

      final companions = <Companion>[];
      for (final row in result) {
        final companion = await _decryptCompanion(row);
        if (companion != null) {
          companions.add(companion);
        }
      }

      return companions;
    } catch (e) {
      throw CompanionRepositoryException('Failed to search companions: $e');
    }
  }

  /// Get companions with pagination
  Future<List<Companion>> getCompanionsPage({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final database = await _storageService.database;
      final result = await database.query(
        'companions',
        orderBy: 'last_interaction DESC',
        limit: limit,
        offset: offset,
      );

      final companions = <Companion>[];
      for (final row in result) {
        final companion = await _decryptCompanion(row);
        if (companion != null) {
          companions.add(companion);
        }
      }

      return companions;
    } catch (e) {
      throw CompanionRepositoryException('Failed to get companions page: $e');
    }
  }

  /// Get total count of companions
  Future<int> getCompanionCount() async {
    try {
      final database = await _storageService.database;
      final result = await database.rawQuery(
        'SELECT COUNT(*) as count FROM companions',
      );
      return result.first['count'] as int;
    } catch (e) {
      throw CompanionRepositoryException('Failed to get companion count: $e');
    }
  }

  /// Backup all companions to JSON
  Future<Map<String, dynamic>> exportCompanions() async {
    try {
      final companions = await getAllCompanions();
      return {
        'companions': companions.map((c) => c.toJson()).toList(),
        'export_timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    } catch (e) {
      throw CompanionRepositoryException('Failed to export companions: $e');
    }
  }

  /// Restore companions from JSON backup
  Future<void> importCompanions(Map<String, dynamic> backupData) async {
    try {
      final companionsData = backupData['companions'] as List<dynamic>;
      
      for (final companionData in companionsData) {
        final companion = Companion.fromJson(companionData as Map<String, dynamic>);
        await saveCompanion(companion);
      }
    } catch (e) {
      throw CompanionRepositoryException('Failed to import companions: $e');
    }
  }
}

/// Exception thrown by companion repository operations
class CompanionRepositoryException implements Exception {
  final String message;

  const CompanionRepositoryException(this.message);

  @override
  String toString() => 'CompanionRepositoryException: $message';
}