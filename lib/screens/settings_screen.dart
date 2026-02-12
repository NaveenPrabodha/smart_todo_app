import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _showCompletedByDefault = true;
  TaskPriority _defaultPriority = TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _showCompletedByDefault = prefs.getBool('show_completed_default') ?? true;
      final int priorityIndex =
          prefs.getInt('default_priority') ?? TaskPriority.medium.index;
      _defaultPriority = TaskPriority.values[priorityIndex];
    });
  }

  Future<void> _setNotifications(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (!value) {
      await NotificationService.instance.cancelAll();
    } else {
      await NotificationService.instance.requestPermissions();
    }
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _setShowCompleted(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_completed_default', value);
    setState(() => _showCompletedByDefault = value);
  }

  Future<void> _setDefaultPriority(TaskPriority priority) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_priority', priority.index);
    setState(() => _defaultPriority = priority);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: _setNotifications,
            title: const Text('Enable reminders'),
            subtitle: const Text('Allow local notifications for due tasks'),
          ),
          const SizedBox(height: 16),
          const Text('Task Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            value: _showCompletedByDefault,
            onChanged: _setShowCompleted,
            title: const Text('Show completed by default'),
            subtitle: const Text('Include completed tasks on the home list'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<TaskPriority>(
            value: _defaultPriority,
            decoration: const InputDecoration(labelText: 'Default priority'),
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
              _setDefaultPriority(value);
            },
          ),
          const SizedBox(height: 24),
          const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Smart Todo'),
            subtitle: Text('Focused task tracking with local storage'),
          ),
        ],
      ),
    );
  }
}
