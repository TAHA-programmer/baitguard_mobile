import '../../../domain/models/user_settings.dart';
import '../../../domain/models/notification_preferences.dart';
import '../../../domain/repositories/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  @override
  Future<UserSettings> getSettings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return UserSettings(
      userId: userId,
      notifications: const NotificationPreferences(),
    );
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }
}
