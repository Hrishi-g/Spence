import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spence/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late String testDbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sb_db_test_');
    testDbPath = p.join(tempDir.path, 'test_budget.db');
  });

  tearDown(() async {
    await DatabaseService.instance.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('DatabaseService file validation and CRUD operations', () async {
    // Open a test database using sqflite
    final db = await openDatabase(
      testDbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY NOT NULL,
            display_name TEXT NOT NULL,
            icon_code INTEGER NOT NULL,
            font_family TEXT,
            color_value INTEGER NOT NULL,
            is_custom INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE accounts (
            id TEXT PRIMARY KEY NOT NULL,
            display_name TEXT NOT NULL,
            icon_code INTEGER NOT NULL,
            font_family TEXT,
            color_value INTEGER NOT NULL,
            is_custom INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY NOT NULL,
            amount REAL NOT NULL CHECK(amount >= 0),
            category_id TEXT NOT NULL,
            account_id TEXT NOT NULL,
            description TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE saved_descriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT UNIQUE NOT NULL COLLATE NOCASE,
            created_at INTEGER NOT NULL
          );
        ''');
      },
    );

    // Test parameterized insert of category
    await db.insert('categories', {
      'id': 'test_cat',
      'display_name': 'Test Category',
      'icon_code': Icons.fastfood.codePoint,
      'font_family': Icons.fastfood.fontFamily,
      'color_value': Colors.orange.toARGB32(),
      'is_custom': 1,
      'sort_order': 0,
    });

    final cats = await db.query('categories', where: 'id = ?', whereArgs: ['test_cat']);
    expect(cats.length, equals(1));
    expect(cats.first['display_name'], equals('Test Category'));

    // Test parameterized insert of transaction
    await db.insert('transactions', {
      'id': 'tx_101',
      'amount': 250.75,
      'category_id': 'test_cat',
      'account_id': 'upi',
      'description': 'Lunch',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final txs = await db.query('transactions', where: 'id = ?', whereArgs: ['tx_101']);
    expect(txs.length, equals(1));
    expect((txs.first['amount'] as num).toDouble(), equals(250.75));

    await db.close();

    // Verify validation detects this database as valid
    final isValid = await DatabaseService.instance.validateDatabaseFile(testDbPath);
    expect(isValid, isTrue);

    // Verify non-sqlite file is rejected by validateDatabaseFile
    final fakeFile = File(p.join(tempDir.path, 'fake.db'));
    await fakeFile.writeAsString('not a sqlite database');
    final isFakeValid = await DatabaseService.instance.validateDatabaseFile(fakeFile.path);
    expect(isFakeValid, isFalse);
  });
}

