import 'notification_preferences.dart';

class UserSettings {
  final String userId;
  final NotificationPreferences notifications;

  const UserSettings({required this.userId, required this.notifications});
}
