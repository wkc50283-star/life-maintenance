import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  bool _writesEnabled = true;

  bool get writesEnabled => _writesEnabled;

  void disableWrites() {
    _writesEnabled = false;
  }

  void enableWrites() {
    _writesEnabled = true;
  }

  Future<void> saveString(String key, String value) async {
    _ensureWritesEnabled();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  Future<String?> readString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  Future<void> remove(String key) async {
    _ensureWritesEnabled();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  void _ensureWritesEnabled() {
    if (!_writesEnabled) {
      throw const LegacyStorageReadOnlyException();
    }
  }
}

class LegacyStorageReadOnlyException implements Exception {
  const LegacyStorageReadOnlyException();

  @override
  String toString() => 'SharedPreferences recovery source is read-only.';
}
