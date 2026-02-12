import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/task_repository.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;

  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  bool _reminderEnabled = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    final Task? task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _categoryController = TextEditingController(text: task?.category ?? '');
    _tagsController = TextEditingController(text: task?.tags.join(', ') ?? '');
    _dueDate = task?.dueDate;
    _priority = task?.priority ?? TaskPriority.medium;
    _reminderEnabled = task?.reminderEnabled ?? false;
    _loadDefaultsIfNeeded();
  }

  Future<void> _loadDefaultsIfNeeded() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int priorityIndex =
        prefs.getInt('default_priority') ?? TaskPriority.medium.index;
    final bool notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? true;
    if (!mounted) return;
    setState(() {
      if (widget.task == null) {
        _priority = TaskPriority.values[priorityIndex];
      }
      _notificationsEnabled = notificationsEnabled;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final TimeOfDay time = await showTimePicker(
      context: context,
      initialTime: _dueDate == null
          ? TimeOfDay.fromDateTime(now)
          : TimeOfDay.fromDateTime(_dueDate!),
    ) ??
        TimeOfDay.fromDateTime(now);
    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'Select due date';
    return DateFormat('EEE, MMM d • h:mm a').format(date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reminderEnabled && _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a due date for reminders.')),
      );
      return;
    }

    final List<String> tags = _tagsController.text
        .split(',')
        .map((String tag) => tag.trim())
        .where((String tag) => tag.isNotEmpty)
        .toList();

    final TaskRepository repo = context.read<TaskRepository>();
    final Task base = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      category: _categoryController.text.trim(),
      tags: tags,
      isCompleted: widget.task?.isCompleted ?? false,
      reminderEnabled: _reminderEnabled,
      remindAt: _reminderEnabled ? _dueDate : null,
      createdAt: widget.task?.createdAt,
      updatedAt: widget.task?.updatedAt,
      remoteId: widget.task?.remoteId,
      isDeleted: widget.task?.isDeleted ?? false,
    );

    Task saved;
    if (widget.task == null) {
      saved = await repo.addTask(base);
    } else {
      await repo.updateTask(base);
      saved = base;
    }

    if (saved.id != null) {
      if (_reminderEnabled && _dueDate != null && _notificationsEnabled) {
        await NotificationService.instance.scheduleDueDateNotification(
          id: saved.id!,
          title: 'Task due: ${saved.title}',
          body: saved.description.isEmpty ? 'Tap to view details' : saved.description,
          scheduledAt: _dueDate!,
        );
      } else {
        await NotificationService.instance.cancel(saved.id!);
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.task != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_formatDueDate(_dueDate)),
                leading: const Icon(Icons.calendar_today_outlined),
                trailing: TextButton(
                  onPressed: _pickDueDate,
                  child: const Text('Pick'),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskPriority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: TaskPriority.values
                    .map(
                      (TaskPriority value) => DropdownMenuItem<TaskPriority>(
                        value: value,
                        child: Text(value.name[0].toUpperCase() + value.name.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (TaskPriority? value) {
                  if (value == null) return;
                  setState(() => _priority = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  helperText: 'Comma separated, e.g. work, errands',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _reminderEnabled,
                onChanged: (bool value) {
                  setState(() => _reminderEnabled = value);
                },
                title: const Text('Enable reminder'),
                subtitle: const Text('Sends a local notification when due'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Save Changes' : 'Create Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskFormResult {
  const TaskFormResult();
}
