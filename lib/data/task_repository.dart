import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';
import 'app_database.dart';

class TaskRepository extends ChangeNotifier {
  TaskRepository(this._db);

  final AppDatabase _db;
  final List<Task> _tasks = <Task>[];
  bool _loaded = false;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    await _refresh();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _refresh() async {
    final Database database = await _db.database;
    final List<Map<String, Object?>> rows = await database.query(
      AppDatabase.tasksTable,
      where: 'is_deleted = 0',
      orderBy: 'is_completed ASC, due_date ASC NULLS LAST, updated_at DESC',
    );
    _tasks
      ..clear()
      ..addAll(rows.map(Task.fromMap));
  }

  Future<Task> addTask(Task task) async {
    final Database database = await _db.database;
    final DateTime now = DateTime.now();
    final Task toInsert = task.copyWith(createdAt: now, updatedAt: now);
    final int id = await database.insert(
      AppDatabase.tasksTable,
      toInsert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final Task saved = toInsert.copyWith(id: id);
    _tasks.insert(0, saved);
    notifyListeners();
    return saved;
  }

  Future<void> updateTask(Task task) async {
    final Database database = await _db.database;
    final Task updated = task.copyWith(updatedAt: DateTime.now());
    await database.update(
      AppDatabase.tasksTable,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[updated.id],
    );
    final int index = _tasks.indexWhere((Task t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleComplete(Task task, bool value) async {
    final Task updated = task.copyWith(isCompleted: value);
    await updateTask(updated);
  }

  Future<void> deleteTask(Task task) async {
    final Database database = await _db.database;
    await database.update(
      AppDatabase.tasksTable,
      <String, Object?>{'is_deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: <Object?>[task.id],
    );
    _tasks.removeWhere((Task t) => t.id == task.id);
    notifyListeners();
  }

  List<String> categories() {
    final Set<String> unique = <String>{};
    for (final Task task in _tasks) {
      if (task.category.trim().isNotEmpty) {
        unique.add(task.category.trim());
      }
    }
    final List<String> list = unique.toList()..sort();
    return list;
  }

  List<Task> filteredTasks({
    required String query,
    TaskPriority? priority,
    bool? completed,
    String? category,
  }) {
    final String trimmedQuery = query.trim().toLowerCase();
    return _tasks.where((Task task) {
      if (completed != null && task.isCompleted != completed) return false;
      if (priority != null && task.priority != priority) return false;
      if (category != null && category.isNotEmpty && task.category != category) {
        return false;
      }
      if (trimmedQuery.isEmpty) return true;
      final String haystack =
          '${task.title} ${task.description} ${task.category} ${task.tags.join(' ')}'
              .toLowerCase();
      return haystack.contains(trimmedQuery);
    }).toList();
  }
}
