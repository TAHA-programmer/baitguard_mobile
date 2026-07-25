import '../models/user_settings.dart';

abstract class SettingsRepository {
  Future<UserSettings> getSettings(String userId);
  Future<void> updateSettings(UserSettings settings);
}
