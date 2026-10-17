import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  Database? _database;
  String? _databasePath;

  static const String _dbFileName = 'self_budget.db';

  static const String tableCategories = 'categories';
  static const String tableAccounts = 'accounts';
  static const String tableTransactions = 'transactions';
  static const String tableSavedDescriptions = 'saved_descriptions';

  static final List<IconData> _allKnownIcons = [
    ...CategoryItem.defaults.map((c) => c.icon),
    ...AccountItem.defaults.map((a) => a.icon),
    Icons.restaurant_outlined,
    Icons.local_drink_outlined,
    Icons.sanitizer_outlined,
    Icons.favorite_border_outlined,
    Icons.eco_outlined,
    Icons.apple_outlined,
    Icons.kebab_dining_outlined,
    Icons.cake_outlined,
    Icons.mail_outline_rounded,
    Icons.music_note_outlined,
    Icons.photo_camera_outlined,
    Icons.cast_for_education_outlined,
    Icons.fitness_center_outlined,
    Icons.sports_tennis_outlined,
    Icons.sports_esports_outlined,
    Icons.movie_outlined,
    Icons.explore_outlined,
    Icons.face_outlined,
    Icons.brush_outlined,
    Icons.checkroom_outlined,
    Icons.work_outline,
    Icons.hiking_outlined,
    Icons.face_retouching_natural_outlined,
    Icons.diamond_outlined,
    Icons.directions_car_filled_outlined,
    Icons.sports_bar_outlined,
    Icons.home_outlined,
    Icons.account_balance_outlined,
  ];

  static IconData getIconFromCode(int codePoint, [String? fontFamily]) {
    for (final icon in _allKnownIcons) {
      if (icon.codePoint == codePoint) {
        return icon;
      }
    }
    // ignore: non_const_argument_for_const_parameter
    return IconData(codePoint, fontFamily: fontFamily ?? 'MaterialIcons');
  }

  /// Returns the active SQLite database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database factory for desktop platforms (Linux, Windows, macOS).
  void _initPlatformFactory() {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Returns the absolute path of the persistent SQLite database file.
  Future<String> getDatabasePath() async {
    if (_databasePath != null) return _databasePath!;
    String dirPath;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      dirPath = docsDir.path;
    } catch (_) {
      dirPath = await getDatabasesPath();
    }
    _databasePath = p.join(dirPath, _dbFileName);
    return _databasePath!;
  }

  /// Returns the directory path where the database and backups reside.
  Future<String> getDatabaseDirectoryPath() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      return docsDir.path;
    } catch (_) {
      return await getDatabasesPath();
    }
  }

  /// Explicitly initialize the database (called on app startup).
  Future<void> init() async {
    await database;
  }

  /// Closes the active database connection.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// Initializes and opens the SQLite database with WAL and Foreign Key support.
  Future<Database> _initDatabase() async {
    _initPlatformFactory();
    final dbPath = await getDatabasePath();

    // Ensure parent directory exists
    final parentDir = Directory(p.dirname(dbPath));
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    return await openDatabase(
      dbPath,
      version: 3,
      onConfigure: (db) async {
        // Enforce foreign key constraints and write-ahead logging for safety
        await db.execute('PRAGMA foreign_keys = ON;');
        try {
          await db.execute('PRAGMA journal_mode = WAL;');
        } catch (_) {
          // Some environments may not support WAL; graceful fallback
        }
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedInitialData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Clean up any old dummy test transactions and descriptions
          await db.delete(
            tableTransactions,
            where: 'id IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            whereArgs: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
          );
          await db.delete(
            tableSavedDescriptions,
            where: 'description IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            whereArgs: [
              'Khana',
              'Dinner with friends',
              'Super hair',
              'Groceries',
              'Metro recharge',
              'Snacks',
              'Coffee',
              'Medicines',
              'Shopping',
              'Fuel',
            ],
          );
        }
        if (oldVersion < 3) {
          // Rename 'bob_bank' account to 'bank'
          await db.update(
            tableAccounts,
            {'id': 'bank', 'display_name': 'Bank'},
            where: 'id = ?',
            whereArgs: ['bob_bank'],
          );
          await db.update(
            tableTransactions,
            {'account_id': 'bank'},
            where: 'account_id = ?',
            whereArgs: ['bob_bank'],
          );
        }
      },
    );
  }

  /// Creates secure tables with strict types, constraints, and indexes.
  Future<void> _createTables(Database db) async {
    // Categories table
    await db.execute('''
      CREATE TABLE $tableCategories (
        id TEXT PRIMARY KEY NOT NULL,
        display_name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        font_family TEXT,
        color_value INTEGER NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // Accounts table
    await db.execute('''
      CREATE TABLE $tableAccounts (
        id TEXT PRIMARY KEY NOT NULL,
        display_name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        font_family TEXT,
        color_value INTEGER NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // Transactions table with non-negative amount constraint
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id TEXT PRIMARY KEY NOT NULL,
        amount REAL NOT NULL CHECK(amount >= 0),
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        description TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      );
    ''');

    // Saved descriptions table
    await db.execute('''
      CREATE TABLE $tableSavedDescriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT UNIQUE NOT NULL COLLATE NOCASE,
        created_at INTEGER NOT NULL
      );
    ''');

    // Indexes for high-performance parameterized queries
    await db.execute('CREATE INDEX idx_transactions_timestamp ON $tableTransactions(timestamp);');
    await db.execute('CREATE INDEX idx_transactions_category ON $tableTransactions(category_id);');
    await db.execute('CREATE INDEX idx_transactions_account ON $tableTransactions(account_id);');
  }

  /// Seeds default categories, accounts, descriptions, and initial transactions safely.
  Future<void> _seedInitialData(Database db) async {
    final batch = db.batch();

    // Seed default categories
    int catSort = 0;
    for (final cat in CategoryItem.defaults) {
      batch.insert(
        tableCategories,
        {
          'id': cat.id,
          'display_name': cat.displayName,
          'icon_code': cat.icon.codePoint,
          'font_family': cat.icon.fontFamily,
          'color_value': cat.color.toARGB32(),
          'is_custom': 0,
          'sort_order': catSort++,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // Seed default accounts
    int accSort = 0;
    for (final acc in AccountItem.defaults) {
      batch.insert(
        tableAccounts,
        {
          'id': acc.id,
          'display_name': acc.displayName,
          'icon_code': acc.icon.codePoint,
          'font_family': acc.icon.fontFamily,
          'color_value': catColorToARGB32(acc.color),
          'is_custom': 0,
          'sort_order': accSort++,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }

  static int catColorToARGB32(Color color) {
    return color.toARGB32();
  }

  // ===========================================================================
  // Sanitization & Security Helpers (Prevents SQL injection & invalid inputs)
  // ===========================================================================

  String _sanitizeText(String input, {int maxLength = 250}) {
    // Strip null bytes and control characters
    final cleaned = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '').trim();
    if (cleaned.length > maxLength) {
      return cleaned.substring(0, maxLength);
    }
    return cleaned;
  }

  String _sanitizeId(String id) {
    final cleaned = id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    if (cleaned.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
    return cleaned.length > 64 ? cleaned.substring(0, 64) : cleaned;
  }

  double _validateAmount(double amount) {
    if (amount.isNaN || amount.isInfinite || amount < 0) {
      return 0.0;
    }
    return double.parse(amount.toStringAsFixed(2));
  }

  // ===========================================================================
  // CATEGORIES CRUD (Fully Parameterized)
  // ===========================================================================

  Future<List<CategoryItem>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCategories,
      orderBy: 'sort_order ASC, id ASC',
    );

    return maps.map((map) {
      return CategoryItem(
        id: map['id'] as String,
        displayName: map['display_name'] as String,
        icon: getIconFromCode(
          map['icon_code'] as int,
          map['font_family'] as String?,
        ),
        color: Color(map['color_value'] as int),
        isCustom: (map['is_custom'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  Future<void> insertCategory(CategoryItem category, [int sortOrder = 999]) async {
    final db = await database;
    final safeId = _sanitizeId(category.id);
    final safeName = _sanitizeText(category.displayName, maxLength: 60);

    await db.insert(
      tableCategories,
      {
        'id': safeId,
        'display_name': safeName,
        'icon_code': category.icon.codePoint,
        'font_family': category.icon.fontFamily,
        'color_value': category.color.toARGB32(),
        'is_custom': category.isCustom ? 1 : 0,
        'sort_order': sortOrder,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      tableCategories,
      where: 'id = ?',
      whereArgs: [_sanitizeId(id)],
    );
  }

  // ===========================================================================
  // ACCOUNTS CRUD (Fully Parameterized)
  // ===========================================================================

  Future<List<AccountItem>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableAccounts,
      orderBy: 'sort_order ASC, id ASC',
    );

    return maps.map((map) {
      return AccountItem(
        id: map['id'] as String,
        displayName: map['display_name'] as String,
        icon: getIconFromCode(
          map['icon_code'] as int,
          map['font_family'] as String?,
        ),
        color: Color(map['color_value'] as int),
        isCustom: (map['is_custom'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  Future<void> insertAccount(AccountItem account, [int sortOrder = 999]) async {
    final db = await database;
    final safeId = _sanitizeId(account.id);
    final safeName = _sanitizeText(account.displayName, maxLength: 60);

    await db.insert(
      tableAccounts,
      {
        'id': safeId,
        'display_name': safeName,
        'icon_code': account.icon.codePoint,
        'font_family': account.icon.fontFamily,
        'color_value': account.color.toARGB32(),
        'is_custom': account.isCustom ? 1 : 0,
        'sort_order': sortOrder,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    await db.delete(
      tableAccounts,
      where: 'id = ?',
      whereArgs: [_sanitizeId(id)],
    );
  }

  // ===========================================================================
  // TRANSACTIONS CRUD (Fully Parameterized)
  // ===========================================================================

  Future<List<ExpenseTransaction>> getTransactions(
    Map<String, CategoryItem> categoryMap,
    Map<String, AccountItem> accountMap,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      orderBy: 'timestamp DESC',
    );

    final fallbackCategory = CategoryItem.defaults.first;
    final fallbackAccount = AccountItem.defaults.first;

    return maps.map((map) {
      final catId = map['category_id'] as String;
      final accId = map['account_id'] as String;
      final category = categoryMap[catId] ?? fallbackCategory;
      final account = accountMap[accId] ?? (accId == 'bob_bank' ? accountMap['bank'] : null) ?? fallbackAccount;

      return ExpenseTransaction(
        id: map['id'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: category,
        account: account,
        description: map['description'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
    }).toList();
  }

  Future<void> insertTransaction(ExpenseTransaction tx) async {
    final db = await database;
    final safeId = _sanitizeId(tx.id);
    final safeAmount = _validateAmount(tx.amount);
    final safeCatId = _sanitizeId(tx.category.id);
    final safeAccId = _sanitizeId(tx.account.id);
    final safeDesc = _sanitizeText(tx.description);

    await db.insert(
      tableTransactions,
      {
        'id': safeId,
        'amount': safeAmount,
        'category_id': safeCatId,
        'account_id': safeAccId,
        'description': safeDesc,
        'timestamp': tx.timestamp.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(ExpenseTransaction tx) async {
    final db = await database;
    final safeId = _sanitizeId(tx.id);
    final safeAmount = _validateAmount(tx.amount);
    final safeCatId = _sanitizeId(tx.category.id);
    final safeAccId = _sanitizeId(tx.account.id);
    final safeDesc = _sanitizeText(tx.description);

    await db.update(
      tableTransactions,
      {
        'amount': safeAmount,
        'category_id': safeCatId,
        'account_id': safeAccId,
        'description': safeDesc,
        'timestamp': tx.timestamp.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [safeId],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      tableTransactions,
      where: 'id = ?',
      whereArgs: [_sanitizeId(id)],
    );
  }

  // ===========================================================================
  // SAVED DESCRIPTIONS CRUD (Fully Parameterized)
  // ===========================================================================

  Future<List<String>> getSavedDescriptions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSavedDescriptions,
      orderBy: 'created_at DESC',
    );

    return maps.map((m) => m['description'] as String).toList();
  }

  Future<void> insertSavedDescription(String description) async {
    final cleaned = _sanitizeText(description, maxLength: 100);
    if (cleaned.isEmpty) return;

    final db = await database;
    await db.insert(
      tableSavedDescriptions,
      {
        'description': cleaned,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deleteSavedDescription(String description) async {
    final cleaned = _sanitizeText(description, maxLength: 100);
    final db = await database;
    await db.delete(
      tableSavedDescriptions,
      where: 'LOWER(description) = LOWER(?)',
      whereArgs: [cleaned],
    );
  }

  // ===========================================================================
  // DATABASE BACKUP & IMPORT CAPABILITIES (Security-hardened)
  // ===========================================================================

  /// Validates an external SQLite database file before replacing the active database.
  /// Checks magic bytes, schema integrity, and required table presence.
  Future<bool> validateDatabaseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    // Verify SQLite magic header: "SQLite format 3\000"
    final bytes = await file.openRead(0, 16).first;
    const sqliteHeader = [
      0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66,
      0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00,
    ];
    if (bytes.length < 16) return false;
    for (int i = 0; i < 16; i++) {
      if (bytes[i] != sqliteHeader[i]) return false;
    }

    _initPlatformFactory();
    Database? tempDb;
    try {
      tempDb = await openReadOnlyDatabase(filePath);
      // Run SQLite integrity check
      final integrity = await tempDb.rawQuery('PRAGMA integrity_check;');
      if (integrity.isEmpty || integrity.first.values.first != 'ok') {
        return false;
      }

      // Check required tables exist
      final tables = await tempDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN (?, ?, ?);",
        [tableCategories, tableAccounts, tableTransactions],
      );
      if (tables.length < 3) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      await tempDb?.close();
    }
  }

  /// Replaces the current database with an imported database file after strict validation.
  Future<bool> importDatabase(String sourceFilePath) async {
    final isValid = await validateDatabaseFile(sourceFilePath);
    if (!isValid) {
      throw Exception('Selected file is not a valid or compatible Self Budget database.');
    }

    await close();
    final currentDbPath = await getDatabasePath();

    // Copy source database to active database path
    final sourceFile = File(sourceFilePath);
    await sourceFile.copy(currentDbPath);

    // Reopen and verify
    _database = await _initDatabase();
    return true;
  }

  /// Exports a copy of current database file to the specified target directory or file path.
  Future<String> exportDatabase({String? destinationDirectory}) async {
    final db = await database;
    try {
      // Checkpoint WAL to flush all transactions to the main .db file
      await db.rawQuery('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {}

    final currentDbPath = await getDatabasePath();
    final sourceFile = File(currentDbPath);

    final String targetPath;
    if (destinationDirectory != null) {
      final dir = Directory(destinationDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      targetPath = p.join(dir.path, 'self_budget_backup_$timestamp.db');
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      targetPath = p.join(docsDir.path, 'self_budget_backup.db');
    }

    await sourceFile.copy(targetPath);
    return targetPath;
  }
}

