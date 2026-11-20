import '../../domain/models/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../mock/mock_reminders.dart';

class MockReminderRepository implements ReminderRepository {
  final List<Reminder> _reminders = List.from(initialMockReminders);

  @override
  Future<List<Reminder>> getReminders() async {
    return List.unmodifiable(_reminders);
  }

  @override
  Future<Reminder?> getReminderById(String id) async {
    try {
      return _reminders.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index >= 0) {
      _reminders[index] = reminder;
    } else {
      _reminders.insert(0, reminder);
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> toggleReminderCompletion(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final rem = _reminders[index];
      if (rem.isCompleted) {
        _reminders[index] = rem.copyWith(clearCompletedAt: true);
      } else {
        _reminders[index] = rem.copyWith(completedAt: DateTime.now());
      }
    }
  }

  @override
  Future<void> saveAll(List<Reminder> reminders) async {
    _reminders
      ..clear()
      ..addAll(reminders);
  }
}
