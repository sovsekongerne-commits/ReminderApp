import '../models/reminder.dart';

/// Abstrakt snitflade for håndtering af påmindelser.
abstract class ReminderRepository {
  Future<List<Reminder>> getReminders();
  Future<Reminder?> getReminderById(String id);
  Future<void> saveReminder(Reminder reminder);
  Future<void> deleteReminder(String id);
  Future<void> toggleReminderCompletion(String id);
  Future<void> saveAll(List<Reminder> reminders);
}
