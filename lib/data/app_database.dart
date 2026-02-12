import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const int _version = 1;
  static const String tasksTable = 'tasks';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, 'smart_todo.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tasksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date INTEGER,
        priority INTEGER NOT NULL,
        category TEXT,
        tags TEXT,
        is_completed INTEGER NOT NULL,
        reminder_enabled INTEGER NOT NULL,
        remind_at INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        remote_id TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
