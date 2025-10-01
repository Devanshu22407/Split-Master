import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing local storage using SharedPreferences
/// All data is stored per user email to support multiple accounts
class StorageService {
  static const String _currentUserEmailKey = 'current_user_email';
  static const String _userDataPrefix = 'user_data_';
  static const String _expensesKey = 'expenses';
  static const String _userInfoKey = 'user_info';
  static const String _profileKey = 'profile';
  static const String _settingsKey = 'settings';
  static const String _spendingLimitsKey = 'spending_limits';
  static const String _friendsKey = 'friends';
  static const String _passwordKey = 'password';
  static const String _themeKey = 'theme_mode';

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the current logged-in user's email
  static String? getCurrentUserEmail() {
    return _prefs?.getString(_currentUserEmailKey);
  }

  /// Set the current logged-in user's email
  static Future<void> setCurrentUserEmail(String email) async {
    await _prefs?.setString(_currentUserEmailKey, email);
  }

  /// Clear current user session (logout)
  static Future<void> clearCurrentUser() async {
    await _prefs?.remove(_currentUserEmailKey);
  }

  /// Generate user-specific key
  static String _getUserKey(String email, String dataType) {
    return '$_userDataPrefix${email}_$dataType';
  }

  // === USER INFO MANAGEMENT ===

  /// Save user information
  static Future<void> saveUserInfo(String email, Map<String, dynamic> userInfo) async {
    final key = _getUserKey(email, _userInfoKey);
    final jsonString = jsonEncode(userInfo);
    await _prefs?.setString(key, jsonString);
  }

  /// Load user information
  static Map<String, dynamic>? loadUserInfo(String email) {
    final key = _getUserKey(email, _userInfoKey);
    final jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    }
    return null;
  }

  // === PASSWORD MANAGEMENT ===

  /// Save user password (in a real app, this should be hashed)
  static Future<void> savePassword(String email, String password) async {
    final key = _getUserKey(email, _passwordKey);
    await _prefs?.setString(key, password);
  }

  /// Load user password
  static String? loadPassword(String email) {
    final key = _getUserKey(email, _passwordKey);
    return _prefs?.getString(key);
  }

  /// Verify user password
  static bool verifyPassword(String email, String password) {
    final storedPassword = loadPassword(email);
    return storedPassword != null && storedPassword == password;
  }

  // === EXPENSES MANAGEMENT ===

  /// Save expenses list
  static Future<void> saveExpenses(String email, List<Map<String, dynamic>> expenses) async {
    final key = _getUserKey(email, _expensesKey);
    final jsonString = jsonEncode(expenses);
    await _prefs?.setString(key, jsonString);
  }

  /// Load expenses list
  static List<Map<String, dynamic>> loadExpenses(String email) {
    final key = _getUserKey(email, _expensesKey);
    final jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  /// Add single expense
  static Future<void> addExpense(String email, Map<String, dynamic> expense) async {
    final expenses = loadExpenses(email);
    expenses.add(expense);
    await saveExpenses(email, expenses);
  }

  /// Update expense at index
  static Future<void> updateExpense(String email, int index, Map<String, dynamic> expense) async {
    final expenses = loadExpenses(email);
    if (index >= 0 && index < expenses.length) {
      expenses[index] = expense;
      await saveExpenses(email, expenses);
    }
  }

  /// Delete expense at index
  static Future<void> deleteExpense(String email, int index) async {
    final expenses = loadExpenses(email);
    if (index >= 0 && index < expenses.length) {
      expenses.removeAt(index);
      await saveExpenses(email, expenses);
    }
  }

  // === FRIENDS MANAGEMENT ===

  /// Save friends list
  static Future<void> saveFriends(String email, List<Map<String, dynamic>> friends) async {
    final key = _getUserKey(email, _friendsKey);
    final jsonString = jsonEncode(friends);
    await _prefs?.setString(key, jsonString);
  }

  /// Load friends list
  static List<Map<String, dynamic>> loadFriends(String email) {
    final key = _getUserKey(email, _friendsKey);
    final jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  /// Add single friend
  static Future<void> addFriend(String email, Map<String, dynamic> friend) async {
    final friends = loadFriends(email);
    // Check if friend already exists (by id or email)
    final existingIndex = friends.indexWhere((f) => 
      f['id'] == friend['id'] || f['email'] == friend['email']);
    
    if (existingIndex == -1) {
      friends.add(friend);
      await saveFriends(email, friends);
    }
  }

  /// Update friend at index
  static Future<void> updateFriend(String email, int index, Map<String, dynamic> friend) async {
    final friends = loadFriends(email);
    if (index >= 0 && index < friends.length) {
      friends[index] = friend;
      await saveFriends(email, friends);
    }
  }

  /// Delete friend by ID
  static Future<void> deleteFriend(String email, String friendId) async {
    final friends = loadFriends(email);
    friends.removeWhere((friend) => friend['id'] == friendId);
    await saveFriends(email, friends);
  }

  // === PROFILE MANAGEMENT ===

  /// Save user profile data
  static Future<void> saveProfile(String email, Map<String, dynamic> profile) async {
    final key = _getUserKey(email, _profileKey);
    final jsonString = jsonEncode(profile);
    await _prefs?.setString(key, jsonString);
  }

  /// Load user profile data
  static Map<String, dynamic>? loadProfile(String email) {
    final key = _getUserKey(email, _profileKey);
    final jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    }
    return null;
  }

  // === SPENDING LIMITS MANAGEMENT ===

  /// Save spending limits
  static Future<void> saveSpendingLimits(String email, Map<String, dynamic> limits) async {
    final key = _getUserKey(email, _spendingLimitsKey);
    final jsonString = jsonEncode(limits);
    await _prefs?.setString(key, jsonString);
  }

  /// Load spending limits
  static Map<String, dynamic>? loadSpendingLimits(String email) {
    final key = _getUserKey(email, _spendingLimitsKey);
    final jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    }
    return null;
  }

  // === SETTINGS MANAGEMENT ===

  /// Save app settings (per user)
  static Future<void> saveSettings(String email, Map<String, dynamic> settings) async {
    final key = _getUserKey(email, _settingsKey);
    final jsonString = jsonEncode(settings);
    await _prefs?.setString(key, jsonString);
  }

  /// Load app settings (per user)
  static Map<String, dynamic>? loadSettings(String email) {
    final key = _getUserKey(email, _settingsKey);
    final jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    }
    return null;
  }

  // === THEME MANAGEMENT (GLOBAL) ===

  /// Save theme mode (global setting)
  static Future<void> saveThemeMode(String themeModeString) async {
    await _prefs?.setString(_themeKey, themeModeString);
  }

  /// Load theme mode (global setting)
  static String? loadThemeMode() {
    return _prefs?.getString(_themeKey);
  }

  // === USER DATA MANAGEMENT ===

  /// Check if user has existing data
  static bool hasUserData(String email) {
    final userInfoKey = _getUserKey(email, _userInfoKey);
    final expensesKey = _getUserKey(email, _expensesKey);
    
    return _prefs?.containsKey(userInfoKey) == true || 
           _prefs?.containsKey(expensesKey) == true;
  }

  /// Clear all data for a specific user
  static Future<void> clearUserData(String email) async {
    final keys = [
      _getUserKey(email, _userInfoKey),
      _getUserKey(email, _expensesKey),
      _getUserKey(email, _profileKey),
      _getUserKey(email, _settingsKey),
      _getUserKey(email, _spendingLimitsKey),
      _getUserKey(email, _friendsKey),
      _getUserKey(email, _passwordKey),
    ];

    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }

  /// Get all stored user emails
  static List<String> getAllUserEmails() {
    final keys = _prefs?.getKeys() ?? <String>{};
    final userEmails = <String>{};

    for (final key in keys) {
      if (key.startsWith(_userDataPrefix)) {
        final parts = key.split('_');
        if (parts.length >= 3) {
          final email = parts[2]; // Extract email from key
          userEmails.add(email);
        }
      }
    }

    return userEmails.toList();
  }

  // === BACKUP AND RESTORE ===

  /// Export all user data as JSON (excluding password for security)
  static Map<String, dynamic> exportUserData(String email) {
    return {
      'email': email,
      'userInfo': loadUserInfo(email),
      'expenses': loadExpenses(email),
      'friends': loadFriends(email),
      'profile': loadProfile(email),
      'settings': loadSettings(email),
      'spendingLimits': loadSpendingLimits(email),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Import user data from JSON
  static Future<void> importUserData(String email, Map<String, dynamic> data) async {
    if (data['userInfo'] != null) {
      await saveUserInfo(email, data['userInfo']);
    }
    if (data['expenses'] != null) {
      final expenses = List<Map<String, dynamic>>.from(data['expenses']);
      await saveExpenses(email, expenses);
    }
    if (data['friends'] != null) {
      final friends = List<Map<String, dynamic>>.from(data['friends']);
      await saveFriends(email, friends);
    }
    if (data['profile'] != null) {
      await saveProfile(email, data['profile']);
    }
    if (data['settings'] != null) {
      await saveSettings(email, data['settings']);
    }
    if (data['spendingLimits'] != null) {
      await saveSpendingLimits(email, data['spendingLimits']);
    }
  }

  // === DEBUGGING AND UTILITIES ===

  /// Print all stored keys (for debugging)
  static void debugPrintAllKeys() {
    final keys = _prefs?.getKeys() ?? <String>{};
    print('=== ALL STORED KEYS ===');
    for (final key in keys) {
      print('Key: $key');
    }
    print('=====================');
  }

  /// Get storage statistics
  static Map<String, dynamic> getStorageStats() {
    final keys = _prefs?.getKeys() ?? <String>{};
    final userEmails = getAllUserEmails();
    
    return {
      'totalKeys': keys.length,
      'userCount': userEmails.length,
      'userEmails': userEmails,
      'currentUser': getCurrentUserEmail(),
      'hasCurrentUser': getCurrentUserEmail() != null,
    };
  }
}