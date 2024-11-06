import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Record {
  final int? id;
  final String date;
  final int type;  // 1: 收入, 2: 支出
  final double amount;
  final String category;
  final String? note;

  Record({
    this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
    };
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'],
      date: map['date'],
      type: map['type'],
      amount: map['amount'].toDouble(),
      category: map['category'],
      note: map['note'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'neko_kare.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            type INTEGER NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            note TEXT
          )
        ''');
      },
    );
  }

  Future<List<Record>> getAllRecords() async {
    final db = await database;
    
    final List<Map<String, dynamic>> tableInfo = await db.rawQuery('PRAGMA table_info(records)');
    print('Table structure: $tableInfo');
    
    final List<Map<String, dynamic>> maps = await db.query('records');
    print('Raw records from database: $maps');
    
    final records = List.generate(maps.length, (i) {
      try {
        return Record.fromMap(maps[i]);
      } catch (e) {
        print('Error converting record ${maps[i]}: $e');
        rethrow;
      }
    });
    
    print('Converted records count: ${records.length}');
    if (records.isNotEmpty) {
      print('First record: ${records.first.toMap()}');
    }
    
    return records;
  }

  Future<void> insertRecord(Record record) async {
    final db = await database;
    final id = await db.insert(
      'records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Inserted record with id: $id');
  }

  Future<void> updateRecord(Record record) async {
    final db = await database;
    await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllRecords() async {
    final db = await database;
    await db.delete('records');
  }
} 