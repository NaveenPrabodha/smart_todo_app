import 'package:flutter/foundation.dart';

enum TaskPriority { low, medium, high }

@immutable
class Task {
  const Task({
    this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.category = '',
    this.tags = const <String>[],
    this.isCompleted = false,
    this.reminderEnabled = false,
    this.remindAt,
    this.createdAt,
    this.updatedAt,
    this.remoteId,
    this.isDeleted = false,
  });

  final int? id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final String category;
  final List<String> tags;
  final bool isCompleted;
  final bool reminderEnabled;
  final DateTime? remindAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? remoteId;
  final bool isDeleted;

  bool get isOverdue {
    if (dueDate == null) return false;
    return !isCompleted && dueDate!.isBefore(DateTime.now());
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? category,
    List<String>? tags,
    bool? isCompleted,
    bool? reminderEnabled,
    DateTime? remindAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remoteId,
    bool? isDeleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      remindAt: remindAt ?? this.remindAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'priority': priority.index,
      'category': category,
      'tags': tags.join(','),
      'is_completed': isCompleted ? 1 : 0,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'remind_at': remindAt?.millisecondsSinceEpoch,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'remote_id': remoteId,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  static Task fromMap(Map<String, Object?> map) {
    return Task(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      dueDate: map['due_date'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
      priority:
          TaskPriority.values[(map['priority'] as int?) ?? TaskPriority.medium.index],
      category: (map['category'] as String?) ?? '',
      tags: _splitTags(map['tags'] as String?),
      isCompleted: (map['is_completed'] as int?) == 1,
      reminderEnabled: (map['reminder_enabled'] as int?) == 1,
      remindAt: map['remind_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['remind_at'] as int),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      remoteId: map['remote_id'] as String?,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  static List<String> _splitTags(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String>[];
    return raw
        .split(',')
        .map((String tag) => tag.trim())
        .where((String tag) => tag.isNotEmpty)
        .toList();
  }
}
