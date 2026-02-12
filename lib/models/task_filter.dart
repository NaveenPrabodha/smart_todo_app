import 'package:flutter/foundation.dart';

import 'task.dart';

@immutable
class TaskFilter {
  const TaskFilter({
    this.query = '',
    this.priority,
    this.completed,
    this.category,
  });

  final String query;
  final TaskPriority? priority;
  final bool? completed;
  final String? category;

  TaskFilter copyWith({
    String? query,
    TaskPriority? priority,
    bool? completed,
    String? category,
  }) {
    return TaskFilter(
      query: query ?? this.query,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      category: category ?? this.category,
    );
  }
}
