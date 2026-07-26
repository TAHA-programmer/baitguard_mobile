import '../../../domain/models/user_settings.dart';
import '../../../domain/models/notification_preferences.dart';
import '../../../domain/repositories/settings_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockSettingsRepository implements SettingsRepository {
  final MockBaitGuardDataSource _dataSource;

  MockSettingsRepository(this._dataSource);

  @override
  Future<UserSettings> getSettings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Check data source cache first
    var settings = _dataSource.getUserSettings(userId);
    if (settings == null) {
      // Return default if not set
      settings = UserSettings(
        userId: userId,
        notifications: const NotificationPreferences(),
      );
      _dataSource.updateUserSettings(settings);
    }
    return settings;
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _dataSource.updateUserSettings(settings);
  }
}
