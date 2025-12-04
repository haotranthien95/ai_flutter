import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper for SharedPreferences to provide type-safe local storage.
///
/// Used for storing simple key-value data like user preferences,
/// settings, and non-sensitive cached data.
class LocalStorage {
  /// Creates a local storage instance.
  ///
  /// [prefs] is optional for testing. If not provided, will be lazily
  /// initialized on first use.
  LocalStorage({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences if not already done.
  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get a string value by key.
  ///
  /// Returns null if the key doesn't exist.
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs!.getString(key);
  }

  /// Save a string value.
  ///
  /// Returns true if successful.
  Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    return _prefs!.setString(key, value);
  }

  /// Get a boolean value by key.
  ///
  /// Returns null if the key doesn't exist.
  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs!.getBool(key);
  }

  /// Save a boolean value.
  ///
  /// Returns true if successful.
  Future<bool> setBool(String key, bool value) async {
    await _ensureInitialized();
    return _prefs!.setBool(key, value);
  }

  /// Get an integer value by key.
  ///
  /// Returns null if the key doesn't exist.
  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _prefs!.getInt(key);
  }

  /// Save an integer value.
  ///
  /// Returns true if successful.
  Future<bool> setInt(String key, int value) async {
    await _ensureInitialized();
    return _prefs!.setInt(key, value);
  }

  /// Get a double value by key.
  ///
  /// Returns null if the key doesn't exist.
  Future<double?> getDouble(String key) async {
    await _ensureInitialized();
    return _prefs!.getDouble(key);
  }

  /// Save a double value.
  ///
  /// Returns true if successful.
  Future<bool> setDouble(String key, double value) async {
    await _ensureInitialized();
    return _prefs!.setDouble(key, value);
  }

  /// Get a list of strings by key.
  ///
  /// Returns null if the key doesn't exist.
  Future<List<String>?> getStringList(String key) async {
    await _ensureInitialized();
    return _prefs!.getStringList(key);
  }

  /// Save a list of strings.
  ///
  /// Returns true if successful.
  Future<bool> setStringList(String key, List<String> value) async {
    await _ensureInitialized();
    return _prefs!.setStringList(key, value);
  }

  /// Remove a value by key.
  ///
  /// Returns true if successful.
  Future<bool> remove(String key) async {
    await _ensureInitialized();
    return _prefs!.remove(key);
  }

  /// Check if a key exists.
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    return _prefs!.containsKey(key);
  }

  /// Get all keys.
  Future<Set<String>> getKeys() async {
    await _ensureInitialized();
    return _prefs!.getKeys();
  }

  /// Clear all stored data.
  ///
  /// Use with caution - this removes ALL data from SharedPreferences.
  /// Returns true if successful.
  Future<bool> clear() async {
    await _ensureInitialized();
    return _prefs!.clear();
  }

  /// Reload data from storage.
  ///
  /// Useful for syncing changes made in other isolates or processes.
  Future<void> reload() async {
    await _ensureInitialized();
    await _prefs!.reload();
  }
}
