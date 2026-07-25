class NotificationPreferences {
  final bool emailAlerts;
  final bool pushAlerts;
  final bool dailyDigest;

  const NotificationPreferences({
    this.emailAlerts = true,
    this.pushAlerts = true,
    this.dailyDigest = false,
  });
}
