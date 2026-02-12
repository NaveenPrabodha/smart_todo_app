import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/task_repository.dart';
import '../models/task.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskRepository>(
      builder: (BuildContext context, TaskRepository repo, _) {
        final List<Task> tasks = repo.tasks;
        final int total = tasks.length;
        final int completed = tasks.where((Task task) => task.isCompleted).length;
        final int active = total - completed;
        final int overdue =
            tasks.where((Task task) => task.isOverdue && !task.isCompleted).length;
        final DateTime now = DateTime.now();
        final int dueToday = tasks.where((Task task) {
          if (task.dueDate == null) return false;
          final DateTime due = task.dueDate!;
          return due.year == now.year &&
              due.month == now.month &&
              due.day == now.day;
        }).length;
        final int highPriority =
            tasks.where((Task task) => task.priority == TaskPriority.high).length;

        return Scaffold(
          appBar: AppBar(title: const Text('Productivity Dashboard')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 1.3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: <Widget>[
                _StatCard(label: 'Total Tasks', value: total.toString()),
                _StatCard(label: 'Completed', value: completed.toString()),
                _StatCard(label: 'Active', value: active.toString()),
                _StatCard(label: 'Overdue', value: overdue.toString()),
                _StatCard(label: 'Due Today', value: dueToday.toString()),
                _StatCard(label: 'High Priority', value: highPriority.toString()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(value, style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
