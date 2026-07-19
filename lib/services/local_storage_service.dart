import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  Future<String?> readString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  /// Creates an immutable v1 recovery backup and never overwrites it.
  Future<void> writeBackupIfAbsent(String key, String value) async {
    if (!key.startsWith('backup_v1_')) {
      throw ArgumentError.value(
        key,
        'key',
        'Only backup_v1_* keys are allowed.',
      );
    }
    final preferences = await SharedPreferences.getInstance();
    if (!preferences.containsKey(key)) {
      await preferences.setString(key, value);
    }
  }
}
