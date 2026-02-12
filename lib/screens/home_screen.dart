import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/task_repository.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  TaskPriority? _priority;
  bool? _completed;
  String? _category;
  bool _showCompletedByDefault = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _showCompletedByDefault = prefs.getBool('show_completed_default') ?? true;
      _completed = _showCompletedByDefault ? null : false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm([Task? task]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<TaskFormResult>(
        builder: (BuildContext context) => TaskFormScreen(task: task),
      ),
    );
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'No due date';
    final DateFormat formatter = DateFormat('EEE, MMM d • h:mm a');
    return formatter.format(date);
  }

  Color _priorityColor(TaskPriority priority, ThemeData theme) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green.shade600;
      case TaskPriority.medium:
        return theme.colorScheme.secondary;
      case TaskPriority.high:
        return Colors.red.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskRepository>(
      builder: (BuildContext context, TaskRepository repo, _) {
        final List<String> categories = repo.categories();
        final List<Task> tasks = repo.filteredTasks(
          query: _searchController.text,
          priority: _priority,
          completed: _completed,
          category: _category,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Smart Todo'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.insights_outlined),
                onPressed: () => Navigator.of(context).pushNamed('/stats'),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search tasks',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: <Widget>[
                      _FilterChip<TaskPriority?>(
                        label: 'Priority',
                        value: _priority,
                        options: const <TaskPriority?>[
                          null,
                          TaskPriority.low,
                          TaskPriority.medium,
                          TaskPriority.high,
                        ],
                        labelFor: (TaskPriority? value) {
                          if (value == null) return 'All';
                          return value.name[0].toUpperCase() + value.name.substring(1);
                        },
                        onChanged: (TaskPriority? value) {
                          setState(() => _priority = value);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip<bool?>(
                        label: 'Status',
                        value: _completed,
                        options: const <bool?>[null, false, true],
                        labelFor: (bool? value) {
                          if (value == null) return 'All';
                          return value ? 'Completed' : 'Active';
                        },
                        onChanged: (bool? value) {
                          setState(() => _completed = value);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip<String?>(
                        label: 'Category',
                        value: _category,
                        options: <String?>[null, ...categories],
                        labelFor: (String? value) =>
                            value == null || value.isEmpty ? 'All' : value,
                        onChanged: (String? value) {
                          setState(() => _category = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: tasks.isEmpty
                      ? _EmptyState(onAdd: _openForm)
                      : ListView.builder(
                          itemCount: tasks.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (BuildContext context, int index) {
                            final Task task = tasks[index];
                            return Dismissible(
                              key: ValueKey<int>(task.id ?? index),
                              background: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) async {
                                await repo.deleteTask(task);
                                if (task.id != null) {
                                  await NotificationService.instance.cancel(task.id!);
                                }
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: task.isCompleted,
                                    onChanged: (bool? value) async {
                                      await repo.toggleComplete(task, value ?? false);
                                    },
                                  ),
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const SizedBox(height: 4),
                                      Text(_formatDueDate(task.dueDate)),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: -6,
                                        children: <Widget>[
                                          Chip(
                                            label: Text(
                                              task.priority.name.toUpperCase(),
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: _priorityColor(
                                              task.priority,
                                              Theme.of(context),
                                            ).withOpacity(0.15),
                                          ),
                                          if (task.category.trim().isNotEmpty)
                                            Chip(
                                              label: Text(task.category),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ...task.tags.map((String tag) {
                                            return Chip(
                                              label: Text(tag),
                                              visualDensity: VisualDensity.compact,
                                            );
                                          }),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: task.isOverdue
                                      ? const Icon(Icons.warning_amber_rounded, color: Colors.red)
                                      : null,
                                  onTap: () => _openForm(task),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('New Task'),
          ),
        );
      },
    );
  }
}

class _FilterChip<T> extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onChanged,
      itemBuilder: (BuildContext context) {
        return options
            .map(
              (T option) => PopupMenuItem<T>(
                value: option,
                child: Text(labelFor(option)),
              ),
            )
            .toList();
      },
      child: Chip(
        label: Text('$label: ${labelFor(value)}'),
        avatar: const Icon(Icons.filter_alt_outlined, size: 18),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.inbox_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              'Nothing here yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Add your first task to get started.'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }
}
