import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/constants.dart';

class StorageService {
  static StorageService? _instance;
  static Database? _database;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, AppConstants.databaseName);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      throw StorageException('Failed to initialize database: $e');
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
    
    // Set journal mode to WAL for better performance
    await db.execute('PRAGMA journal_mode = WAL');
    
    // Set synchronous mode to NORMAL for balance of safety and performance
    await db.execute('PRAGMA synchronous = NORMAL');
    
    // Enable memory-mapped I/O
    await db.execute('PRAGMA mmap_size = 268435456'); // 256MB
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // Create companions table
      await txn.execute('''
        CREATE TABLE companions (
          id TEXT PRIMARY KEY,
          encrypted_data BLOB NOT NULL,
          created_at INTEGER NOT NULL,
          last_interaction INTEGER NOT NULL,
          total_interactions INTEGER NOT NULL DEFAULT 0,
          name_search TEXT NOT NULL
        )
      ''');

      // Create memory items table
      await txn.execute('''
        CREATE TABLE memory_items (
          id TEXT PRIMARY KEY,
          companion_id TEXT NOT NULL,
          encrypted_content BLOB NOT NULL,
          type TEXT NOT NULL,
          importance REAL NOT NULL DEFAULT 0.5,
          timestamp INTEGER NOT NULL,
          tags TEXT NOT NULL DEFAULT '[]',
          FOREIGN KEY (companion_id) REFERENCES companions(id) ON DELETE CASCADE
        )
      ''');

      // Create conversations table
      await txn.execute('''
        CREATE TABLE conversations (
          id TEXT PRIMARY KEY,
          companion_id TEXT NOT NULL,
          encrypted_user_message BLOB NOT NULL,
          encrypted_companion_response BLOB NOT NULL,
          timestamp INTEGER NOT NULL,
          metadata TEXT NOT NULL DEFAULT '{}',
          FOREIGN KEY (companion_id) REFERENCES companions(id) ON DELETE CASCADE
        )
      ''');

      // Create user preferences table
      await txn.execute('''
        CREATE TABLE user_preferences (
          key TEXT PRIMARY KEY,
          encrypted_value BLOB NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create safety logs table
      await txn.execute('''
        CREATE TABLE safety_logs (
          id TEXT PRIMARY KEY,
          companion_id TEXT,
          event_type TEXT NOT NULL,
          encrypted_details BLOB NOT NULL,
          severity TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          FOREIGN KEY (companion_id) REFERENCES companions(id) ON DELETE SET NULL
        )
      ''');

      // Create performance metrics table
      await txn.execute('''
        CREATE TABLE performance_metrics (
          id TEXT PRIMARY KEY,
          metric_name TEXT NOT NULL,
          metric_value REAL NOT NULL,
          timestamp INTEGER NOT NULL,
          metadata TEXT NOT NULL DEFAULT '{}'
        )
      ''');

      // Create indices for better performance
      await _createIndices(txn);
    });
  }

  Future<void> _createIndices(Transaction txn) async {
    // Companions indices
    await txn.execute('CREATE INDEX idx_companions_last_interaction ON companions(last_interaction DESC)');
    await txn.execute('CREATE INDEX idx_companions_name_search ON companions(name_search)');
    await txn.execute('CREATE INDEX idx_companions_created_at ON companions(created_at)');

    // Memory items indices
    await txn.execute('CREATE INDEX idx_memory_companion_id ON memory_items(companion_id)');
    await txn.execute('CREATE INDEX idx_memory_importance ON memory_items(companion_id, importance DESC)');
    await txn.execute('CREATE INDEX idx_memory_timestamp ON memory_items(companion_id, timestamp DESC)');
    await txn.execute('CREATE INDEX idx_memory_type ON memory_items(companion_id, type)');

    // Conversations indices
    await txn.execute('CREATE INDEX idx_conversations_companion_id ON conversations(companion_id)');
    await txn.execute('CREATE INDEX idx_conversations_timestamp ON conversations(companion_id, timestamp DESC)');

    // Safety logs indices
    await txn.execute('CREATE INDEX idx_safety_logs_companion_id ON safety_logs(companion_id)');
    await txn.execute('CREATE INDEX idx_safety_logs_timestamp ON safety_logs(timestamp DESC)');
    await txn.execute('CREATE INDEX idx_safety_logs_severity ON safety_logs(severity)');

    // Performance metrics indices
    await txn.execute('CREATE INDEX idx_performance_metrics_name ON performance_metrics(metric_name)');
    await txn.execute('CREATE INDEX idx_performance_metrics_timestamp ON performance_metrics(timestamp DESC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema migrations
    if (oldVersion < 2) {
      // Example migration for version 2
      await db.execute('ALTER TABLE companions ADD COLUMN name_search TEXT DEFAULT ""');
      
      // Update existing records
      final companions = await db.query('companions');
      for (final companion in companions) {
        // This would need to decrypt and re-encrypt with name search
        // Implementation depends on encryption strategy
      }
    }

    // Add more migration logic for future versions
    if (oldVersion < 3) {
      // Future migration logic
    }
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Delete the database file (for testing or reset)
  Future<void> deleteDatabase() async {
    await close();
    
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Also delete WAL and SHM files
    final walFile = File('$path-wal');
    if (await walFile.exists()) {
      await walFile.delete();
    }
    
    final shmFile = File('$path-shm');
    if (await shmFile.exists()) {
      await shmFile.delete();
    }
  }

  /// Get database file size in bytes
  Future<int> getDatabaseSize() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Vacuum the database to reclaim space
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  /// Optimize database performance
  Future<void> optimize() async {
    final db = await database;
    
    // Analyze tables for query optimization
    await db.execute('ANALYZE');
    
    // Rebuild indices if needed
    await db.execute('REINDEX');
  }

  /// Check database integrity
  Future<bool> checkIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      
      // If integrity check passes, result will contain a single row with 'ok'
      return result.length == 1 && result.first.values.first == 'ok';
    } catch (e) {
      return false;
    }
  }

  /// Get database statistics
  Future<DatabaseStats> getStats() async {
    final db = await database;
    
    // Get table counts
    final companionCount = await _getTableCount(db, 'companions');
    final memoryItemCount = await _getTableCount(db, 'memory_items');
    final conversationCount = await _getTableCount(db, 'conversations');
    final preferenceCount = await _getTableCount(db, 'user_preferences');
    
    // Get database size
    final sizeBytes = await getDatabaseSize();
    
    // Get page info
    final pageInfo = await db.rawQuery('PRAGMA page_count');
    final pageCount = pageInfo.first['page_count'] as int;
    
    final pageSizeInfo = await db.rawQuery('PRAGMA page_size');
    final pageSize = pageSizeInfo.first['page_size'] as int;
    
    return DatabaseStats(
      companionCount: companionCount,
      memoryItemCount: memoryItemCount,
      conversationCount: conversationCount,
      preferenceCount: preferenceCount,
      sizeBytes: sizeBytes,
      pageCount: pageCount,
      pageSize: pageSize,
    );
  }

  Future<int> _getTableCount(Database db, String tableName) async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return result.first['count'] as int;
  }

  /// Backup database to a file
  Future<String> createBackup() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, AppConstants.databaseName);
    final backupPath = join(
      documentsDirectory.path,
      'allma_backup_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.copy(backupPath);
    }
    
    return backupPath;
  }

  /// Restore database from a backup file
  Future<void> restoreBackup(String backupPath) async {
    await close();
    
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, AppConstants.databaseName);
    
    final backupFile = File(backupPath);
    if (await backupFile.exists()) {
      await backupFile.copy(dbPath);
    }
    
    // Reinitialize database
    _database = null;
    await database;
  }
}

/// Database statistics
class DatabaseStats {
  final int companionCount;
  final int memoryItemCount;
  final int conversationCount;
  final int preferenceCount;
  final int sizeBytes;
  final int pageCount;
  final int pageSize;

  const DatabaseStats({
    required this.companionCount,
    required this.memoryItemCount,
    required this.conversationCount,
    required this.preferenceCount,
    required this.sizeBytes,
    required this.pageCount,
    required this.pageSize,
  });

  double get sizeMB => sizeBytes / (1024 * 1024);
  int get totalRecords => companionCount + memoryItemCount + conversationCount + preferenceCount;
}

/// Exception thrown by storage operations
class StorageException implements Exception {
  final String message;

  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}