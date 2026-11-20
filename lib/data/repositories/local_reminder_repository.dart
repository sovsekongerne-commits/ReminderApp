import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';

class LocalReminderRepository implements ReminderRepository {
  static const String _key = 'saved_reminders_v1';

  @override
  Future<List<Reminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    // Baggrunds-koden (ankomst / knapper på beskeden) kan have ændret data.
    await prefs.reload();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .map((item) => Reminder.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Reminder?> getReminderById(String id) async {
    final reminders = await getReminders();
    try {
      return reminders.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index >= 0) {
      reminders[index] = reminder;
    } else {
      reminders.insert(0, reminder);
    }
    await saveAll(reminders);
  }

  @override
  Future<void> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.id == id);
    await saveAll(reminders);
  }

  @override
  Future<void> toggleReminderCompletion(String id) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final r = reminders[index];
      if (r.isCompleted) {
        reminders[index] = r.copyWith(clearCompletedAt: true);
      } else {
        reminders[index] = r.copyWith(completedAt: DateTime.now());
      }
      await saveAll(reminders);
    }
  }

  @override
  Future<void> saveAll(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
