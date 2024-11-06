import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/saving_record.dart';
import '../models/exchange_rate.dart';
import '../models/book.dart';

class DatabaseService {
  static Database? _database;
  static int _currentBookId = 1;  // 默认账本ID

  static int get currentBookId => _currentBookId;
  static set currentBookId(int id) => _currentBookId = id;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getDatabasesPath();
      final path = join(documentsDirectory, 'savings.db');

      return await openDatabase(
        path,
        version: 5,  // 更新版本号
        onCreate: (Database db, int version) async {
          // 创建账本表
          await db.execute('''
            CREATE TABLE IF NOT EXISTS books(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          // 创建存储记录表（添加软删除字段）
          await db.execute('''
            CREATE TABLE IF NOT EXISTS savings(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              book_id INTEGER NOT NULL,
              amount REAL NOT NULL,
              currency TEXT NOT NULL DEFAULT "CNY",
              date TEXT NOT NULL,
              note TEXT,
              deleted_at TEXT,
              FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
            )
          ''');
          
          await db.execute('''
            CREATE TABLE IF NOT EXISTS exchange_rates(
              currency TEXT PRIMARY KEY,
              rate REAL NOT NULL
            )
          ''');
          
          // 创建默认账本
          await db.insert('books', {
            'name': '默认账本',
            'description': '我的第一个账本',
            'created_at': DateTime.now().toIso8601String(),
          });

          // 插入默认汇率
          await db.insert('exchange_rates', {'currency': 'CNY', 'rate': 1.0});
          await db.insert('exchange_rates', {'currency': 'USD', 'rate': 7.2});
          await db.insert('exchange_rates', {'currency': 'EUR', 'rate': 7.8});
          await db.insert('exchange_rates', {'currency': 'JPY', 'rate': 0.048});
          await db.insert('exchange_rates', {'currency': 'AUD', 'rate': 4.7});
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE savings ADD COLUMN currency TEXT NOT NULL DEFAULT "CNY"');
          }
          if (oldVersion < 3) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS exchange_rates(
                currency TEXT PRIMARY KEY,
                rate REAL NOT NULL
              )
            ''');
            
            await db.insert('exchange_rates', {'currency': 'CNY', 'rate': 1.0});
            await db.insert('exchange_rates', {'currency': 'USD', 'rate': 7.2});
            await db.insert('exchange_rates', {'currency': 'EUR', 'rate': 7.8});
            await db.insert('exchange_rates', {'currency': 'JPY', 'rate': 0.048});
            await db.insert('exchange_rates', {'currency': 'AUD', 'rate': 4.7});
          }
          if (oldVersion < 4) {
            // 创建账本表
            await db.execute('''
              CREATE TABLE IF NOT EXISTS books(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                created_at TEXT NOT NULL
              )
            ''');

            // 添加默认账本
            await db.insert('books', {
              'name': '默认账本',
              'description': '我的第一个账本',
              'created_at': DateTime.now().toIso8601String(),
            });

            // 添加book_id字段到savings表
            await db.execute('ALTER TABLE savings ADD COLUMN book_id INTEGER NOT NULL DEFAULT 1');
            await db.execute('CREATE INDEX savings_book_id_idx ON savings(book_id)');
          }
          if (oldVersion < 5) {
            // 添加软删除字段
            await db.execute('ALTER TABLE savings ADD COLUMN deleted_at TEXT');
          }
        },
      );
    } catch (e) {
      print('数据库初始化错误: $e');
      rethrow;
    }
  }

  // 账本相关方法
  Future<List<Book>> getAllBooks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'books',
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
    } catch (e) {
      print('获取账本列表错误: $e');
      return [];
    }
  }

  Future<Book> createBook(String name, String? description) async {
    try {
      final db = await database;
      final id = await db.insert('books', {
        'name': name,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
      return Book(
        id: id,
        name: name,
        description: description,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('创建账本错误: $e');
      rethrow;
    }
  }

  Future<void> deleteBook(int id) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        // 删除账本下的所有记录
        await txn.delete('savings', where: 'book_id = ?', whereArgs: [id]);
        // 删除账本
        await txn.delete('books', where: 'id = ?', whereArgs: [id]);
      });
    } catch (e) {
      print('删除账本错误: $e');
      rethrow;
    }
  }

  Future<void> updateBook(Book book) async {
    try {
      final db = await database;
      await db.update(
        'books',
        book.toMap(),
        where: 'id = ?',
        whereArgs: [book.id],
      );
    } catch (e) {
      print('更新账本错误: $e');
      rethrow;
    }
  }

  // 修改现有方法以支持多账本
  Future<int> insertRecord(SavingRecord record) async {
    try {
      final db = await database;
      final Map<String, dynamic> data = {
        'book_id': _currentBookId,
        'amount': record.amount,
        'currency': record.currency,
        'date': record.date.toIso8601String(),
        'note': record.note,
      };
      return await db.insert('savings', data);
    } catch (e) {
      print('插入记录错误: $e');
      rethrow;
    }
  }

  Future<List<SavingRecord>> getRecords() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'savings',
        where: 'book_id = ? AND deleted_at IS NULL',
        whereArgs: [_currentBookId],
        orderBy: 'date DESC',
      );
      return maps.map((map) => SavingRecord.fromMap(map)).toList();
    } catch (e) {
      print('获取记录错误: $e');
      return [];
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      final db = await database;
      await db.update(
        'savings',
        {'deleted_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('成功删除ID为 $id 的记录');
    } catch (e) {
      print('删除记录错误: $e');
      rethrow;
    }
  }

  // 获取汇率
  Future<double> getExchangeRate(String currency) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'exchange_rates',
        where: 'currency = ?',
        whereArgs: [currency],
      );
      return result.first['rate'] as double;
    } catch (e) {
      print('获取汇率错误: $e');
      return 1.0;  // 默认返回1.0
    }
  }

  // 更新汇率
  Future<void> updateExchangeRate(String currency, double rate) async {
    try {
      final db = await database;
      await db.insert(
        'exchange_rates',
        {'currency': currency, 'rate': rate},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('更新汇率错误: $e');
      rethrow;
    }
  }

  // 获取所有汇率
  Future<List<ExchangeRate>> getAllExchangeRates() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('exchange_rates');
      return List.generate(maps.length, (i) {
        return ExchangeRate(
          currency: maps[i]['currency'] as String,
          rate: maps[i]['rate'] as double,
        );
      });
    } catch (e) {
      print('获取所有汇率错误: $e');
      return [];
    }
  }

  Future<List<SavingRecord>> getRecordsForBook(int bookId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'savings',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'date DESC',
      );
      return maps.map((map) => SavingRecord.fromMap(map)).toList();
    } catch (e) {
      print('获取账本记录错误: $e');
      return [];
    }
  }

  // 获取已删除的记录
  Future<List<SavingRecord>> getDeletedRecords() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'savings',
        where: 'deleted_at IS NOT NULL',
        orderBy: 'deleted_at DESC',
      );
      return maps.map((map) => SavingRecord.fromMap(map)).toList();
    } catch (e) {
      print('获取已删除记录错误: $e');
      return [];
    }
  }

  // 恢复已删除的记录
  Future<void> restoreRecord(int id) async {
    try {
      final db = await database;
      await db.update(
        'savings',
        {'deleted_at': null},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('恢复记录错误: $e');
      rethrow;
    }
  }

  // 永久删除记录
  Future<void> permanentlyDeleteRecord(int id) async {
    try {
      final db = await database;
      await db.delete(
        'savings',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('永久删除记录错误: $e');
      rethrow;
    }
  }

  Future<String> getCurrentBookName() async {
    final book = await getBook(currentBookId);
    return book?.name ?? '默认账本';
  }

  Future<Book?> getBook(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'books',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return Book.fromMap(maps.first);
    } catch (e) {
      print('获取账本错误: $e');
      return null;
    }
  }
} 