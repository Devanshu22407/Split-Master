import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'storage_service.dart';
import 'all_expenses_screen.dart';
import 'profile_screen.dart';

// --- Data Models ---

// Responsive utility class
class ResponsiveUtils {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 700;
  }
  
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }
  
  static double getResponsivePadding(BuildContext context, {double small = 16, double normal = 24}) {
    return isSmallScreen(context) ? small : normal;
  }
  
  static double getResponsiveSpacing(BuildContext context, {double small = 12, double normal = 16}) {
    return isSmallScreen(context) ? small : normal;
  }
  
  static double getResponsiveFontSize(BuildContext context, {double small = 14, double normal = 16}) {
    return isSmallScreen(context) ? small : normal;
  }
  
  static EdgeInsets getResponsiveScreenPadding(BuildContext context) {
    final isSmall = isSmallScreen(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return EdgeInsets.fromLTRB(
      isSmall ? 16.0 : 24.0,
      isSmall ? 16.0 : 24.0,
      isSmall ? 16.0 : 24.0,
      keyboardHeight > 0 ? 16.0 : (isSmall ? 16.0 : 24.0),
    );
  }
  
  static String formatAmountWithK(double amount, {String currencySymbol = '₹'}) {
    if (amount.abs() >= 1000) {
      double kAmount = amount / 1000;
      return '${currencySymbol}${kAmount.toStringAsFixed(1)}k';
    } else {
      return '${currencySymbol}${amount.toStringAsFixed(2)}';
    }
  }
}

// Helper function to generate initials from full name
class ProfileUtils {
  static String getInitials(String fullName) {
    if (fullName.trim().isEmpty) return '?';
    
    List<String> nameParts = fullName.trim().split(' ');
    if (nameParts.length == 1) {
      // If only one name, return first letter
      return nameParts[0].substring(0, 1).toUpperCase();
    } else {
      // Return first letter of first name + first letter of last name
      String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
      String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
      return firstInitial + lastInitial;
    }
  }
}

enum ExpenseCategory {
  food,
  transportation,
  housing,
  entertainment,
  utilities,
  groceries,
  shopping,
  health,
  education,
  travel,
  other,
}

// Extension to provide human-readable names and icons for categories
extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    return toString().split('.').last.replaceAll('_', ' ').capitalizeFirst;
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.housing:
        return Icons.home;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.utilities:
        return Icons.lightbulb;
      case ExpenseCategory.groceries:
        return Icons.local_grocery_store;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.health:
        return Icons.local_hospital;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.travel:
        return Icons.flight;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }
}

extension StringExtension on String {
  String get capitalizeFirst {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class AppUser {
  final String id;
  final String name; // Full name
  final String username; // Shorter display name
  final String email;
  final DateTime? dob;
  final String? country;
  final String? gender;
  final String? phoneNumber;

  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.dob,
    this.country,
    this.gender,
    this.phoneNumber,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    DateTime? dob,
    String? country,
    String? gender,
    String? phoneNumber,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SplitShare {
  double amount;
  bool paid; // True if this user has paid their share to the payer
  final String userId;

  SplitShare({required this.userId, required this.amount, this.paid = false});
}

class Expense {
  final String id;
  String title;
  double amount;
  ExpenseCategory category;
  DateTime date;
  String? receiptImageUrl;
  String? payerId; // Who initially paid for the expense
  List<SplitShare> splitDetails; // Who is involved in splitting and their shares

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.receiptImageUrl,
    this.payerId,
    List<SplitShare>? splitDetails,
  }) : splitDetails = splitDetails ?? <SplitShare>[];
}

// --- State Management (ChangeNotifier) ---

class AuthManager extends ChangeNotifier {
  bool _isAuthenticated = false;
  AppUser? _currentUser;
  String _dummyPassword = 'password'; // Simulate a password for the dummy user

  bool get isAuthenticated => _isAuthenticated;
  AppUser? get currentUser => _currentUser;

  AuthManager() {
    // Check for existing session on startup
    _loadSession();
  }

  /// Load existing session from SharedPreferences
  Future<void> _loadSession() async {
    final currentEmail = StorageService.getCurrentUserEmail();
    if (currentEmail != null) {
      final userInfo = StorageService.loadUserInfo(currentEmail);
      if (userInfo != null) {
        _isAuthenticated = true;
        _currentUser = AppUser(
          id: userInfo['id'] ?? 'user_1',
          name: userInfo['name'] ?? 'User',
          username: userInfo['username'] ?? 'user',
          email: currentEmail,
          dob: userInfo['dob'] != null ? DateTime.parse(userInfo['dob']) : null,
          country: userInfo['country'],
          gender: userInfo['gender'],
          phoneNumber: userInfo['phoneNumber'],
        );
        notifyListeners();
      }
    }
  }

  /// Save current user session to SharedPreferences
  Future<void> _saveSession() async {
    if (_currentUser != null) {
      await StorageService.setCurrentUserEmail(_currentUser!.email);
      await StorageService.saveUserInfo(_currentUser!.email, {
        'id': _currentUser!.id,
        'name': _currentUser!.name,
        'username': _currentUser!.username,
        'email': _currentUser!.email,
        'dob': _currentUser!.dob?.toIso8601String(),
        'country': _currentUser!.country,
        'gender': _currentUser!.gender,
        'phoneNumber': _currentUser!.phoneNumber,
      });
    }
  }

  Future<void> login(String email, String password) async {
    // Input validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    
    // Email format validation
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(email.trim())) {
      throw Exception('Please enter a valid email address');
    }
    
    final cleanEmail = email.trim();
    
    // Check if user has existing data
    if (StorageService.hasUserData(cleanEmail)) {
      // Verify password for existing user
      if (!StorageService.verifyPassword(cleanEmail, password)) {
        throw Exception('Invalid email or password');
      }
      
      // Load existing user data
      final userInfo = StorageService.loadUserInfo(cleanEmail);
      if (userInfo != null) {
        _isAuthenticated = true;
        _currentUser = AppUser(
          id: userInfo['id'],
          name: userInfo['name'],
          username: userInfo['username'],
          email: cleanEmail,
          dob: userInfo['dob'] != null ? DateTime.parse(userInfo['dob']) : null,
          country: userInfo['country'],
          gender: userInfo['gender'],
          phoneNumber: userInfo['phoneNumber'],
        );
        _saveSession();
        notifyListeners();
        return;
      } else {
        throw Exception('User data corrupted. Please contact support.');
      }
    }
    
    // For demo user (backwards compatibility)
    if (cleanEmail == 'user@example.com' && password == _dummyPassword) {
      _isAuthenticated = true;
      _currentUser = AppUser(
        id: 'user_1',
        name: 'John Doe',
        username: 'johndoe',
        email: cleanEmail,
        dob: null,
        country: null,
        gender: null,
        phoneNumber: null,
      );
      // Save demo user password for consistency
      await StorageService.savePassword(cleanEmail, password);
      _saveSession();
      notifyListeners();
    } else {
      // Invalid credentials
      throw Exception('Invalid email or password');
    }
  }

  Future<void> signup(String name, String username, String email, String password) async {
    // Input validation
    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }
    
    // Name validation
    if (name.trim().length < 2) {
      throw Exception('Name must be at least 2 characters long');
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name.trim())) {
      throw Exception('Name can only contain letters and spaces');
    }
    
    // Username validation
    if (username.trim().length < 3) {
      throw Exception('Username must be at least 3 characters long');
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.trim())) {
      throw Exception('Username can only contain letters, numbers, and underscores');
    }
    
    if (username.trim().length > 20) {
      throw Exception('Username cannot be longer than 20 characters');
    }
    
    // Email format validation
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(email.trim())) {
      throw Exception('Please enter a valid email address');
    }
    
    // Password validation
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      throw Exception('Password must contain at least one uppercase letter, one lowercase letter, and one number');
    }
    
    if (password.contains(' ')) {
      throw Exception('Password cannot contain spaces');
    }
    
    final cleanEmail = email.trim();
    
    // Check if user already exists
    if (StorageService.hasUserData(cleanEmail)) {
      throw Exception('An account with this email already exists. Please login instead.');
    }
    
    // Create new user
    _isAuthenticated = true;
    _currentUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      username: username.trim(),
      email: cleanEmail,
      dob: null,
      country: null,
      gender: null,
      phoneNumber: null,
    );
    
    // Save password and user session
    await StorageService.savePassword(cleanEmail, password);
    _saveSession();
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    StorageService.clearCurrentUser(); // Clear current session
    _dummyPassword = 'password'; // Reset dummy password
    notifyListeners();
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) {
      return 'No user logged in to change password.';
    }
    
    // Validate current password
    if (currentPassword.isEmpty) {
      return 'Current password is required.';
    }
    
    // Check current password against stored password
    if (!StorageService.verifyPassword(_currentUser!.email, currentPassword)) {
      return 'Current password is incorrect.';
    }
    
    // Validate new password
    if (newPassword.isEmpty) {
      return 'New password is required.';
    }
    
    if (newPassword.length < 8) {
      return 'New password must be at least 8 characters long.';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(newPassword)) {
      return 'New password must contain at least one uppercase letter, one lowercase letter, and one number.';
    }
    
    if (newPassword.contains(' ')) {
      return 'New password cannot contain spaces.';
    }
    
    if (currentPassword == newPassword) {
      return 'New password must be different from current password.';
    }
    
    // Update password
    await StorageService.savePassword(_currentUser!.email, newPassword);
    debugPrint('Password changed successfully for ${_currentUser!.email}');
    notifyListeners();
    return null; // Success
  }

  void updateUserProfile({
    String? name,
    required String username,
    DateTime? dob,
    String? country,
    String? gender,
    String? phoneNumber,
  }) {
    if (_currentUser == null) {
      debugPrint('Error: No user logged in to update profile.');
      return;
    }
    _currentUser = _currentUser!.copyWith(
      name: name,
      username: username,
      dob: dob,
      country: country,
      gender: gender,
      phoneNumber: phoneNumber,
    );
    
    // Save updated user info to SharedPreferences
    _saveSession();
    notifyListeners();
  }
}

class AppConfig extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default to light theme for professional look
  String _currency = 'INR'; // Default currency

  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;

  AppConfig() {
    _loadThemeMode();
  }

  /// Load theme mode from SharedPreferences
  void _loadThemeMode() {
    final savedTheme = StorageService.loadThemeMode();
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'light':
        default:
          _themeMode = ThemeMode.light;
          break;
      }
    }
  }

  /// Save theme mode to SharedPreferences
  Future<void> _saveThemeMode() async {
    final themeString = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await StorageService.saveThemeMode(themeString);
  }

  // Get currency symbol based on selected currency
  String get currencySymbol {
    switch (_currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'INR':
      default:
        return '₹';
    }
  }

  // Get currency display name
  String get currencyDisplayName {
    switch (_currency) {
      case 'USD':
        return 'USD (US Dollar)';
      case 'EUR':
        return 'EUR (Euro)';
      case 'INR':
      default:
        return 'INR (Indian Rupee)';
    }
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode();
    notifyListeners();
  }

  void setCurrency(String currency) {
    _currency = currency;
    notifyListeners();
  }
}

class ExpenseManager extends ChangeNotifier {
  final List<Expense> _expenses = <Expense>[];
  final List<AppUser> _allUsers = <AppUser>[];

  double? _dailyLimit;
  double? _monthlyLimit;
  bool _isDailyLimitEnabled = false;
  bool _isMonthlyLimitEnabled = false;

  String? _currentUserEmail;

  List<Expense> get expenses => List<Expense>.unmodifiable(_expenses);
  List<AppUser> get allUsers => List<AppUser>.unmodifiable(_allUsers);

  double? get dailyLimit => _dailyLimit;
  double? get monthlyLimit => _monthlyLimit;
  bool get isDailyLimitEnabled => _isDailyLimitEnabled;
  bool get isMonthlyLimitEnabled => _isMonthlyLimitEnabled;

  ExpenseManager() {
    // Initialize with empty data - ready for new users
    _dailyLimit = null;
    _monthlyLimit = null;
    _isDailyLimitEnabled = false;
    _isMonthlyLimitEnabled = false;
  }

  /// Load user data when user logs in
  void loadUserData(String userEmail) {
    _currentUserEmail = userEmail;
    
    // Load expenses
    final expensesData = StorageService.loadExpenses(userEmail);
    _expenses.clear();
    for (final expenseMap in expensesData) {
      try {
        _expenses.add(_expenseFromMap(expenseMap));
      } catch (e) {
        print('Error loading expense: $e');
      }
    }
    
    // Load friends
    final friendsData = StorageService.loadFriends(userEmail);
    _allUsers.clear();
    for (final friendMap in friendsData) {
      try {
        _allUsers.add(_friendFromMap(friendMap));
      } catch (e) {
        print('Error loading friend: $e');
      }
    }
    
    // Load spending limits
    final limitsData = StorageService.loadSpendingLimits(userEmail);
    if (limitsData != null) {
      _dailyLimit = limitsData['dailyLimit']?.toDouble();
      _monthlyLimit = limitsData['monthlyLimit']?.toDouble();
      _isDailyLimitEnabled = limitsData['isDailyLimitEnabled'] ?? false;
      _isMonthlyLimitEnabled = limitsData['isMonthlyLimitEnabled'] ?? false;
    }
    
    notifyListeners();
  }

  /// Clear data when user logs out
  void clearUserData() {
    _currentUserEmail = null;
    _expenses.clear();
    _allUsers.clear();
    _dailyLimit = null;
    _monthlyLimit = null;
    _isDailyLimitEnabled = false;
    _isMonthlyLimitEnabled = false;
    notifyListeners();
  }

  /// Save expenses to SharedPreferences
  Future<void> _saveExpenses() async {
    if (_currentUserEmail != null) {
      final expensesData = _expenses.map((expense) => _expenseToMap(expense)).toList();
      await StorageService.saveExpenses(_currentUserEmail!, expensesData);
    }
  }

  /// Save spending limits to SharedPreferences
  Future<void> _saveSpendingLimits() async {
    if (_currentUserEmail != null) {
      final limitsData = {
        'dailyLimit': _dailyLimit,
        'monthlyLimit': _monthlyLimit,
        'isDailyLimitEnabled': _isDailyLimitEnabled,
        'isMonthlyLimitEnabled': _isMonthlyLimitEnabled,
      };
      await StorageService.saveSpendingLimits(_currentUserEmail!, limitsData);
    }
  }

  void addExpense(Expense expense) {
    _expenses.add(expense);
    _saveExpenses();
    notifyListeners();
  }

  void updateExpense(Expense updatedExpense) {
    final int index =
        _expenses.indexWhere((Expense expense) => expense.id == updatedExpense.id);
    if (index != -1) {
      _expenses[index] = updatedExpense;
      _saveExpenses();
      notifyListeners();
    }
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((Expense expense) => expense.id == id);
    _saveExpenses();
    notifyListeners();
  }

  /// Update spending limits
  void updateSpendingLimits({
    double? dailyLimit,
    double? monthlyLimit,
    bool? isDailyLimitEnabled,
    bool? isMonthlyLimitEnabled,
  }) {
    if (dailyLimit != null) _dailyLimit = dailyLimit;
    if (monthlyLimit != null) _monthlyLimit = monthlyLimit;
    if (isDailyLimitEnabled != null) _isDailyLimitEnabled = isDailyLimitEnabled;
    if (isMonthlyLimitEnabled != null) _isMonthlyLimitEnabled = isMonthlyLimitEnabled;
    
    _saveSpendingLimits();
    notifyListeners();
  }

  /// Convert Expense to Map for storage
  Map<String, dynamic> _expenseToMap(Expense expense) {
    return {
      'id': expense.id,
      'title': expense.title,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'category': expense.category.toString(),
      'payerId': expense.payerId,
      'receiptImageUrl': expense.receiptImageUrl,
      'splitDetails': expense.splitDetails.map((split) => {
        'userId': split.userId,
        'amount': split.amount,
        'paid': split.paid,
      }).toList(),
    };
  }

  /// Convert Map to Expense from storage
  Expense _expenseFromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'].toDouble(),
      date: DateTime.parse(map['date']),
      category: ExpenseCategory.values.firstWhere(
        (cat) => cat.toString() == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      payerId: map['payerId'],
      receiptImageUrl: map['receiptImageUrl'],
      splitDetails: (map['splitDetails'] as List<dynamic>?)
          ?.map((split) => SplitShare(
                userId: split['userId'],
                amount: split['amount'].toDouble(),
                paid: split['paid'] ?? false,
              ))
          .toList() ?? [],
    );
  }

  /// Save friends to SharedPreferences
  Future<void> _saveFriends() async {
    if (_currentUserEmail != null) {
      final friendsData = _allUsers.map((friend) => _friendToMap(friend)).toList();
      await StorageService.saveFriends(_currentUserEmail!, friendsData);
    }
  }

  /// Convert AppUser (friend) to Map for storage
  Map<String, dynamic> _friendToMap(AppUser friend) {
    return {
      'id': friend.id,
      'name': friend.name,
      'username': friend.username,
      'email': friend.email,
      'dob': friend.dob?.toIso8601String(),
      'country': friend.country,
      'gender': friend.gender,
      'phoneNumber': friend.phoneNumber,
    };
  }

  /// Convert Map to AppUser (friend) from storage
  AppUser _friendFromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      email: map['email'],
      dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
      country: map['country'],
      gender: map['gender'],
      phoneNumber: map['phoneNumber'],
    );
  }

  // NEW: Method to add a new AppUser (friend)
  void addAppUser(AppUser user) {
    // In a real app, you might want to check for duplicate IDs or emails
    if (!_allUsers.any((AppUser existingUser) => existingUser.id == user.id)) {
      _allUsers.add(user);
      _saveFriends();
      notifyListeners();
    }
  }

  // NEW: Method to delete an AppUser (friend)
  void deleteAppUser(String userId) {
    _allUsers.removeWhere((AppUser user) => user.id == userId);
    _saveFriends();
    notifyListeners();
    // NOTE: In a real application, deleting a user would require complex
    // cascading logic to handle their involvement in existing expenses
    // (e.g., as payer, or in splitDetails). For this exercise, we are
    // simply removing them from the _allUsers list. Existing expenses
    // might then reference non-existent user IDs, which should be
    // handled gracefully by UI components (e.g., displaying "Unknown").
  }

  List<Expense> getExpensesForMonth(DateTime month) {
    return _expenses
        .where((Expense expense) =>
            expense.date.year == month.year && expense.date.month == month.month)
        .toList();
  }

  double getTotalSpend() {
    return _expenses.fold(0.0, (double sum, Expense expense) => sum + expense.amount);
  }

  Map<ExpenseCategory, double> getTotalSpendByCategory() {
    final Map<ExpenseCategory, double> categorySums = <ExpenseCategory, double>{};
    for (final ExpenseCategory category in ExpenseCategory.values) {
      categorySums[category] = 0.0;
    }
    for (final Expense expense in _expenses) {
      categorySums[expense.category] =
          (categorySums[expense.category] ?? 0.0) + expense.amount;
    }
    return categorySums;
  }

  // Monthly spend trend for a given number of months back
  Map<DateTime, double> getMonthlySpendTrend(int monthsBack) {
    final Map<DateTime, double> monthlySpend = <DateTime, double>{};
    final DateTime now = DateTime.now();

    for (int i = monthsBack - 1; i >= 0; i--) {
      final DateTime month = DateTime(now.year, now.month - i, 1);
      monthlySpend[month] = 0.0;
    }

    for (final Expense expense in _expenses) {
      final DateTime expenseMonth =
          DateTime(expense.date.year, expense.date.month, 1);
      if (monthlySpend.containsKey(expenseMonth)) {
        monthlySpend[expenseMonth] =
            (monthlySpend[expenseMonth] ?? 0.0) + expense.amount;
      }
    }
    return monthlySpend;
  }

  Map<String, double> getOwedAmounts(String currentUserId, {List<Expense>? expensesToConsider}) {
    final List<Expense> expenses = expensesToConsider ?? _expenses;
    final Map<String, double> owed = <String, double>{}; // Amounts current user owes to others
    final Map<String, double> owedToMe = <String, double>{}; // Amounts others owe to current user

    for (final Expense expense in expenses) {
      if (expense.payerId == currentUserId) {
        // Current user paid
        for (final SplitShare split in expense.splitDetails) {
          if (split.userId != currentUserId && !split.paid) {
            owedToMe[split.userId] =
                (owedToMe[split.userId] ?? 0.0) + split.amount;
          }
        }
      } else {
        // Someone else paid
        for (final SplitShare split in expense.splitDetails) {
          if (split.userId == currentUserId && !split.paid) {
            // If the payerId is null (which shouldn't happen with current logic for new expenses)
            // or if it's the current user (which means they paid it, not owe it).
            // This condition is for when *someone else* paid and I owe them.
            if (expense.payerId != null && expense.payerId != currentUserId) {
              owed[expense.payerId!] = (owed[expense.payerId!] ?? 0.0) + split.amount;
            }
          }
        }
      }
    }

    // Combine net amounts
    final Map<String, double> netOwed = <String, double>{};
    // Initialize with all potential users to ensure all are considered in the net calculation
    for (final AppUser user in _allUsers) {
      if (user.id != currentUserId) {
        netOwed[user.id] = 0.0;
      }
    }

    for (final String userId in owed.keys) {
      netOwed[userId] = (netOwed[userId] ?? 0.0) - owed[userId]!;
    }
    for (final String userId in owedToMe.keys) {
      netOwed[userId] = (netOwed[userId] ?? 0.0) + owedToMe[userId]!;
    }

    return netOwed;
  }

  // Helper function to get the last expense date between current user and another user
  DateTime? getLastExpenseDateBetween(String currentUserId, String otherUserId) {
    DateTime? lastDate;
    
    for (final Expense expense in _expenses) {
      // Check if this expense involves both users
      bool involvesCurrentUser = expense.payerId == currentUserId || 
          expense.splitDetails.any((split) => split.userId == currentUserId);
      bool involvesOtherUser = expense.payerId == otherUserId || 
          expense.splitDetails.any((split) => split.userId == otherUserId);
      
      if (involvesCurrentUser && involvesOtherUser) {
        if (lastDate == null || expense.date.isAfter(lastDate)) {
          lastDate = expense.date;
        }
      }
    }
    
    return lastDate;
  }

  void markSplitShareAsPaid(String expenseId, String userId) {
    final int expenseIndex =
        _expenses.indexWhere((Expense expense) => expense.id == expenseId);
    if (expenseIndex != -1) {
      final Expense expense = _expenses[expenseIndex];
      final int splitIndex =
          expense.splitDetails.indexWhere((SplitShare split) => split.userId == userId);
      if (splitIndex != -1) {
        expense.splitDetails[splitIndex].paid = true;
        _saveExpenses(); // Save the updated payment status to SharedPreferences
        notifyListeners();
      }
    }
  }

  // Helper method to calculate current user's personal share of an expense
  double _calculatePersonalShareOfExpense(Expense expense, String currentUserId) {
    if (expense.splitDetails.isEmpty) {
      // If no split details, the payer bore the full expense.
      return expense.payerId == currentUserId ? expense.amount : 0.0;
    } else {
      // Expense has split details. Find current user's share.
      final SplitShare? currentUserShare = expense.splitDetails.firstWhereOrNull(
        (SplitShare split) => split.userId == currentUserId,
      );

      if (currentUserShare != null) {
        // Current user is part of the split. Their personal spend is their share.
        return currentUserShare.amount;
      } else {
        // Current user is not part of the split details, this expense does not count as their personal spend.
        return 0.0;
      }
    }
  }

  // Renamed for clarity: calculates total spend including amounts paid by user for others
  double getTotalDailySpend(DateTime date) {
    return _expenses
        .where((Expense expense) =>
            expense.date.year == date.year &&
            expense.date.month == date.month &&
            expense.date.day == date.day)
        .fold(0.0, (double sum, Expense expense) => sum + expense.amount);
  }

  // Renamed for clarity: calculates total spend including amounts paid by user for others
  double getTotalMonthlySpend(DateTime date) {
    return _expenses
        .where((Expense expense) =>
            expense.date.year == date.year && expense.date.month == date.month)
        .fold(0.0, (double sum, Expense expense) => sum + expense.amount);
  }

  // NEW: Calculates the current user's personal spend for a given day
  double getCurrentDailyPersonalSpend(DateTime date, String currentUserId) {
    return _expenses
        .where((Expense expense) =>
            expense.date.year == date.year &&
            expense.date.month == date.month &&
            expense.date.day == date.day)
        .fold(0.0,
            (double sum, Expense expense) => sum + _calculatePersonalShareOfExpense(expense, currentUserId));
  }

  // NEW: Calculates the current user's personal spend for a given month
  double getCurrentMonthlyPersonalSpend(DateTime date, String currentUserId) {
    return _expenses
        .where((Expense expense) =>
            expense.date.year == date.year && expense.date.month == date.month)
        .fold(0.0,
            (double sum, Expense expense) => sum + _calculatePersonalShareOfExpense(expense, currentUserId));
  }

  // Methods for managing spending limits
  void setDailyLimit(double? limit, bool enabled) {
    _dailyLimit = limit;
    _isDailyLimitEnabled = enabled;
    notifyListeners();
  }

  void setMonthlyLimit(double? limit, bool enabled) {
    _monthlyLimit = limit;
    _isMonthlyLimitEnabled = enabled;
    notifyListeners();
  }

  // Updated: Checks if adding a new expense's personal share would exceed the daily limit
  bool isDailyLimitExceeded(
      double totalNewExpenseAmount, List<SplitShare> newExpenseSplitDetails, DateTime expenseDate, String currentUserId) {
    if (!_isDailyLimitEnabled || _dailyLimit == null || _dailyLimit! <= 0) {
      return false;
    }
    final double currentPersonalSpendToday =
        getCurrentDailyPersonalSpend(expenseDate, currentUserId);

    final SplitShare? newExpenseCurrentUserShare = newExpenseSplitDetails.firstWhereOrNull(
      (SplitShare split) => split.userId == currentUserId,
    );
    final double personalShareOfNewExpense = newExpenseCurrentUserShare?.amount ?? 0.0;

    return (currentPersonalSpendToday + personalShareOfNewExpense) > _dailyLimit!;
  }

  // Updated: Checks if adding a new expense's personal share would exceed the monthly limit
  bool isMonthlyLimitExceeded(
      double totalNewExpenseAmount, List<SplitShare> newExpenseSplitDetails, DateTime expenseDate, String currentUserId) {
    if (!_isMonthlyLimitEnabled || _monthlyLimit == null || _monthlyLimit! <= 0) {
      return false;
    }
    final double currentPersonalSpendMonth =
        getCurrentMonthlyPersonalSpend(expenseDate, currentUserId);

    final SplitShare? newExpenseCurrentUserShare = newExpenseSplitDetails.firstWhereOrNull(
      (SplitShare split) => split.userId == currentUserId,
    );
    final double personalShareOfNewExpense = newExpenseCurrentUserShare?.amount ?? 0.0;

    return (currentPersonalSpendMonth + personalShareOfNewExpense) > _monthlyLimit!;
  }
}

// --- Main App Widget ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  await StorageService.init();
  
  runApp(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<AuthManager>(
          create: (BuildContext context) => AuthManager(),
        ),
        ChangeNotifierProvider<AppConfig>(
          create: (BuildContext context) => AppConfig(),
        ),
        ChangeNotifierProvider<ExpenseManager>(
          create: (BuildContext context) => ExpenseManager(),
        ),
      ],
      builder: (BuildContext context, Widget? child) {
        final AppConfig appConfig = Provider.of<AppConfig>(context);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SplitMaster',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB), // Professional blue
              brightness: Brightness.light,
              primary: const Color(0xFF2563EB),
              secondary: const Color(0xFF10B981), // Professional green
              surface: const Color(0xFFF8FAFC),
              background: const Color(0xFFF1F5F9),
              error: const Color(0xFFEF4444),
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
              headlineLarge: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
              headlineMedium: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              headlineSmall: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              titleLarge: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF334155),
              ),
              titleMedium: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
              bodyLarge: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
              bodyMedium: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: const Color(0xFFFAFAFA),
              foregroundColor: const Color(0xFF1E293B),
              titleTextStyle: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              iconTheme: const IconThemeData(
                color: Color(0xFF1E293B),
                size: 24,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
              labelStyle: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF60A5FA), // Brighter, more visible blue
              brightness: Brightness.dark,
              primary: const Color(0xFF60A5FA), // More vibrant blue
              secondary: const Color(0xFF4ADE80), // Brighter green
              surface: const Color(0xFF1F2937), // Lighter gray for better contrast
              background: const Color(0xFF111827), // Deeper background
              error: const Color(0xFFF87171), // Softer red
              onPrimary: const Color(0xFF000000), // Black text on primary
              onSecondary: const Color(0xFF000000), // Black text on secondary
              onSurface: const Color(0xFFF9FAFB), // Very light text
              onBackground: const Color(0xFFF3F4F6), // Light text on background
              onError: const Color(0xFF000000), // Black text on error
              outline: const Color(0xFF6B7280), // Medium gray for borders
              surfaceVariant: const Color(0xFF374151), // Mid-gray surfaces
              onSurfaceVariant: const Color(0xFFD1D5DB), // Light gray text
              primaryContainer: const Color(0xFF1E40AF), // Darker blue container
              onPrimaryContainer: const Color(0xFFDBEAFE), // Very light blue text
              secondaryContainer: const Color(0xFF166534), // Darker green container
              onSecondaryContainer: const Color(0xFFDCFCE7), // Very light green text
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).primaryTextTheme).copyWith(
              headlineLarge: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF9FAFB), // Almost white
              ),
              headlineMedium: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF9FAFB), // Almost white
              ),
              headlineSmall: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF3F4F6), // Light gray
              ),
              titleLarge: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFE5E7EB), // Medium-light gray
              ),
              titleMedium: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFD1D5DB), // Medium gray
              ),
              bodyLarge: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFD1D5DB), // Medium gray for readability
              ),
              bodyMedium: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFD1D5DB), // Medium gray for readability
              ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: const Color(0xFF1F2937), // Matches surface
              foregroundColor: const Color(0xFFF9FAFB), // Almost white
              titleTextStyle: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF9FAFB), // Almost white
              ),
              iconTheme: const IconThemeData(
                color: Color(0xFFF9FAFB), // Almost white
                size: 24,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 8, // Increased for better depth
              shadowColor: Colors.black.withOpacity(0.5), // Stronger shadow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: const Color(0xFF1F2937), // Lighter than background
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: const Color(0xFF60A5FA), // Bright blue
                foregroundColor: const Color(0xFF000000), // Black text for contrast
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF374151), // Medium gray
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6B7280)), // Medium border
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6B7280)), // Medium border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 2), // Bright blue
              ),
              labelStyle: GoogleFonts.inter(
                color: const Color(0xFFD1D5DB), // Light gray
                fontWeight: FontWeight.w500,
              ),
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF), // Medium gray
                fontWeight: FontWeight.w400,
              ),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF60A5FA); // Bright blue when selected
                }
                return const Color(0xFF6B7280); // Gray when unselected
              }),
              trackColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF1E40AF); // Dark blue track when selected
                }
                return const Color(0xFF374151); // Dark gray track when unselected
              }),
            ),
            iconTheme: const IconThemeData(
              color: Color(0xFFD1D5DB), // Light gray for icons
              size: 24,
            ),
          ),
          themeMode: appConfig.themeMode,
          home: const AuthWrapper(),
        );
      },
    ),
  );
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthManager, ExpenseManager>(
      builder: (context, authManager, expenseManager, child) {
        if (authManager.isAuthenticated && authManager.currentUser != null) {
          // Load user data when user is authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            expenseManager.loadUserData(authManager.currentUser!.email);
          });
          return const MainAppShell();
        } else {
          // Clear data when user is not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            expenseManager.clearUserData();
          });
          return const AuthScreen();
        }
      },
    );
  }
}

// --- Authentication Screen ---

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _usernameController.clear();
    _confirmPasswordController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _isPasswordVisible = false;
      _isConfirmPasswordVisible = false;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _authenticate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
    
    try {
      if (_isLogin) {
        await authManager.login(_emailController.text.trim(), _passwordController.text);
      } else {
        await authManager.signup(
            _nameController.text.trim(), 
            _usernameController.text.trim(),
            _emailController.text.trim(), 
            _passwordController.text
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Email validation function
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    
    return null;
  }

  // Password validation function
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }
    
    return null;
  }

  // Name validation function
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  // Username validation function
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters long';
    }
    
    if (value.trim().length > 20) {
      return 'Username cannot be longer than 20 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }

  // Confirm password validation function
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24.0,
                isSmallScreen ? 16.0 : 24.0,
                24.0,
                keyboardHeight > 0 ? 16.0 : 24.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (isSmallScreen ? 32.0 : 48.0),
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // Flexible spacing at top
                        if (!isSmallScreen) const Spacer(flex: 1),
                        
                        // App Logo - Responsive size
                        Container(
                          width: isSmallScreen ? 80 : 100,
                          height: isSmallScreen ? 80 : 100,
                          margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: isSmallScreen ? 80 : 100,
                              height: isSmallScreen ? 80 : 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: isSmallScreen ? 80 : 100,
                                  height: isSmallScreen ? 80 : 100,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    size: isSmallScreen ? 40 : 50,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        // App Name and Tagline - Responsive text
                        Column(
                          children: [
                            Text(
                              'Welcome to SplitMaster',
                              style: GoogleFonts.inter(
                                fontSize: isSmallScreen ? 22 : 26,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            Text(
                              'Split expenses, track balances, stay organized',
                              style: GoogleFonts.inter(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: isSmallScreen ? 24 : 32),
                        
                        // Form Fields Container
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth > 600 ? 400 : double.infinity,
                          ),
                          child: Column(
                            children: [
                              // Name field for signup
                              if (!_isLogin) ...<Widget>[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    hintText: 'Enter your full name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.person_outline),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isSmallScreen ? 8 : 12, // Reduced vertical padding
                                    ),
                                  ),
                                  keyboardType: TextInputType.name,
                                  textCapitalization: TextCapitalization.words,
                                  validator: _validateName,
                                  textInputAction: TextInputAction.next,
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 12), // Reduced spacing
                                
                                // Username field for signup
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    hintText: 'Choose a unique username',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.alternate_email),
                                    helperText: isSmallScreen ? null : 'Only letters, numbers, and underscores allowed',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isSmallScreen ? 8 : 12, // Reduced vertical padding
                                    ),
                                  ),
                                  keyboardType: TextInputType.text,
                                  validator: _validateUsername,
                                  textInputAction: TextInputAction.next,
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 12), // Reduced spacing
                              ],
                              
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'Enter your email',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: isSmallScreen ? 8 : 12, // Reduced vertical padding
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                textInputAction: TextInputAction.next,
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12), // Reduced spacing
                              
                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: _isLogin ? 'Enter your password' : 'Create a strong password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: isSmallScreen ? 8 : 12, // Reduced vertical padding
                                  ),
                                ),
                                obscureText: !_isPasswordVisible,
                                validator: _isLogin ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                } : _validatePassword,
                                textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                              ),
                              
                              // Confirm password field for signup
                              if (!_isLogin) ...<Widget>[
                                SizedBox(height: isSmallScreen ? 8 : 12), // Reduced spacing
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    hintText: 'Re-enter your password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                        });
                                      },
                                      icon: Icon(
                                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isSmallScreen ? 8 : 12, // Reduced vertical padding
                                    ),
                                  ),
                                  obscureText: !_isConfirmPasswordVisible,
                                  validator: _validateConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                ),
                              ],
                              
                              // Password requirements for signup - Only show on larger screens
                              if (!_isLogin && !isSmallScreen) ...<Widget>[
                                SizedBox(height: isSmallScreen ? 8 : 12), // Reduced spacing
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Password Requirements:',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildPasswordRequirement('At least 8 characters'),
                                      _buildPasswordRequirement('At least one uppercase letter'),
                                      _buildPasswordRequirement('At least one lowercase letter'),
                                      _buildPasswordRequirement('At least one number'),
                                      _buildPasswordRequirement('At least one special character'),
                                    ],
                                  ),
                                ),
                              ],
                              
                              SizedBox(height: isSmallScreen ? 16 : 20), // Reduced spacing
                              
                              // Submit Button
                              Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.6, // 60% width (40% reduction)
                                  height: isSmallScreen ? 32 : 38, // Reduced height by 20%
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _authenticate,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8), // Reduced border radius by 20%
                                      ),
                                      elevation: 1, // Reduced elevation
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 13 : 16, // Reduced padding by 20%
                                        vertical: isSmallScreen ? 6 : 8, // Reduced padding by 20%
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: isSmallScreen ? 13 : 14, // Reduced loading indicator size by 20%
                                            width: isSmallScreen ? 13 : 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).colorScheme.onPrimary,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min, // Prevent overflow
                                            children: [
                                              Icon(
                                                _isLogin ? Icons.login : Icons.person_add,
                                                size: isSmallScreen ? 13 : 14, // Reduced icon size by 20%
                                              ),
                                              SizedBox(width: isSmallScreen ? 5 : 6), // Reduced spacing by 20%
                                              Flexible(
                                                child: Text(
                                                  _isLogin ? 'Login' : 'Sign Up',
                                                  style: GoogleFonts.inter(
                                                    fontSize: isSmallScreen ? 10 : 12, // Reduced font size by 20%
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 12 : 16), // Reduced spacing
                              
                              // Toggle between login and signup
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _isLogin ? "Don't have an account? " : "Already have an account? ",
                                      style: GoogleFonts.inter(
                                        fontSize: isSmallScreen ? 12 : 13, // Reduced font size
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLogin = !_isLogin;
                                        _clearForm();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 4 : 6, // Reduced padding
                                        vertical: isSmallScreen ? 2 : 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      _isLogin ? 'Sign Up' : 'Login',
                                      style: GoogleFonts.inter(
                                        fontSize: isSmallScreen ? 12 : 13, // Reduced font size
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Flexible spacing at bottom
                        if (!isSmallScreen) const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPasswordRequirement(String requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            requirement,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Main App Shell with Bottom Navigation
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 2) { // Add button
      _showAddOptionsBottomSheet(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  void _showAddOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: ResponsiveUtils.getResponsiveScreenPadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 16, normal: 20)),
                  
                  Text(
                    'Add New',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 18, normal: 20),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 20, normal: 24)),
                  
                  // Side by side compact tiles
                  Row(
                    children: [
                      // Add Expense Tile
                      Expanded(
                        child: Container(
                          height: ResponsiveUtils.isSmallScreen(context) ? 44 : 50,
                          margin: EdgeInsets.only(right: ResponsiveUtils.getResponsiveSpacing(context, small: 6, normal: 8)),
                          child: Material(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddExpenseScreen(
                                      onSaveAndNavigateBack: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          _selectedIndex = 0;
                                        });
                                        _pageController.jumpToPage(0);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.getResponsiveSpacing(context, small: 8, normal: 12),
                                  vertical: ResponsiveUtils.getResponsiveSpacing(context, small: 6, normal: 8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.add_card_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Expense',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Add Friend Tile
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: const EdgeInsets.only(left: 8),
                          child: Material(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FriendsListScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.person_add_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Friend',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: <Widget>[
          const HomeScreen(),
          const InsightsScreen(),
          const AddPlaceholderScreen(), // Placeholder - not directly accessed
          const CalendarScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --- Home Screen ---

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ExpenseManager>(
        builder: (BuildContext context, ExpenseManager expenseManager, Widget? child) {
          final AuthManager authManager =
              Provider.of<AuthManager>(context, listen: false);
          final String currentUserId = authManager.currentUser?.id ?? 'unknown_user';

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsivePadding(context, small: 12, normal: 16),
                vertical: ResponsiveUtils.getResponsivePadding(context, small: 8, normal: 12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 8, normal: 12)),
                  // Simple Welcome Banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getResponsivePadding(context, small: 12, normal: 16),
                      vertical: ResponsiveUtils.getResponsiveSpacing(context, small: 8, normal: 12),
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E3A8A).withOpacity(0.2) // Dark mode: deep blue with transparency
                          : const Color(0xFFDBEAFE), // Light mode: light blue
                      borderRadius: BorderRadius.circular(16),
                      border: Theme.of(context).brightness == Brightness.dark
                          ? Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              width: 1,
                            )
                          : Border.all(
                              color: const Color(0xFF93C5FD),
                              width: 1,
                            ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 14, normal: 16),
                          fontWeight: FontWeight.w400, // Normal weight for "Welcome,"
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.8)
                              : const Color(0xFF374151),
                        ),
                        children: [
                          const TextSpan(text: 'Welcome, '),
                          TextSpan(
                            text: authManager.currentUser?.username ?? 'Guest',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 14, normal: 16),
                              fontWeight: FontWeight.w700, // Bold for username
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF60A5FA) // Light blue for dark mode
                                  : const Color(0xFF1E40AF), // Dark blue for light mode
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 12, normal: 16)),
                  OverallSplitSummaryCards(
                      expenseManager: expenseManager, currentUserId: currentUserId),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 12, normal: 16)),
                  // NEW: Friends Balances List
                  FriendsBalancesList(
                      expenseManager: expenseManager, currentUserId: currentUserId),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 12, normal: 16)),
                  Row(
                    children: [
                      Text(
                        'Recent Expenses',
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 16, normal: 18),
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<Widget>(
                              builder: (context) => const AllExpensesScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward, size: 14),
                        label: const Text('View All'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, small: 8, normal: 12)),
                  RecentExpensesList(expenseManager: expenseManager),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- NEW: Overall Split Summary Cards for Home Screen ---
class OverallSplitSummaryCards extends StatelessWidget {
  final ExpenseManager expenseManager;
  final String currentUserId;

  const OverallSplitSummaryCards({
    super.key,
    required this.expenseManager,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, double> netOwed =
        expenseManager.getOwedAmounts(currentUserId);
    final List<MapEntry<String, double>> owingToOthers = netOwed.entries
        .where((MapEntry<String, double> entry) => entry.value < 0)
        .toList();
    final List<MapEntry<String, double>> othersOwingToMe = netOwed.entries
        .where((MapEntry<String, double> entry) => entry.value > 0)
        .toList();

    final double totalOwedToMe = othersOwingToMe.fold(
        0.0, (double sum, MapEntry<String, double> entry) => sum + entry.value);
    final double totalIOwe = owingToOthers.fold(
        0.0, (double sum, MapEntry<String, double> entry) => sum + entry.value.abs());

    // Use responsive design based on screen size
    final cardSpacing = ResponsiveUtils.getResponsiveSpacing(context, small: 12, normal: 16);
    
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildSummaryTile(
            context,
            'You Owe',
            ResponsiveUtils.formatAmountWithK(totalIOwe),
            Icons.trending_down_rounded,
            const Color(0xFFFF6B6B), // Soft red
            false, // isOwedToMe: false (I owe)
          ),
        ),
        SizedBox(width: cardSpacing),
        Expanded(
          child: _buildSummaryTile(
            context,
            'You Are Owed',
            ResponsiveUtils.formatAmountWithK(totalOwedToMe),
            Icons.trending_up_rounded,
            const Color(0xFF10B981), // Soft green
            true, // isOwedToMe: true (Others owe me)
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTile(BuildContext context, String title, String value,
      IconData icon, Color accentColor, bool isOwedToMe) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
      decoration: BoxDecoration(
        color: isDark 
            ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : accentColor.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<Widget>(
                builder: (BuildContext context) => OverallSplitLedgerScreen(
                  isOwedToMe: isOwedToMe,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Top row with icon and arrow
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: isSmallScreen ? 16 : 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: isSmallScreen ? 10 : 12,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isSmallScreen ? 8 : 12),
              
              // Title
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 10, normal: 12),
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: isSmallScreen ? 2 : 4),
              
              // Amount
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 16 : 20,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- NEW: Friends Balances List for Home Screen ---
class FriendsBalancesList extends StatelessWidget {
  final ExpenseManager expenseManager;
  final String currentUserId;

  const FriendsBalancesList({
    super.key,
    required this.expenseManager,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, double> netOwed =
        expenseManager.getOwedAmounts(currentUserId);

    // Show only top 5 friends sorted by amount (highest amounts first)
    final List<AppUser> allFriends = expenseManager.allUsers
        .where((AppUser user) => user.id != currentUserId) // Exclude current user
        .toList();

    // Sort friends by balance amount (descending - highest amounts first)
    allFriends.sort((AppUser a, AppUser b) {
      final double balanceA = (netOwed[a.id] ?? 0.0).abs();
      final double balanceB = (netOwed[b.id] ?? 0.0).abs();
      return balanceB.compareTo(balanceA); // Descending order
    });

    // Take only top 5 friends
    final List<AppUser> friendsToDisplay = allFriends.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(
                color: const Color(0xFF374151), // Subtle border for dark theme
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3) // Stronger shadow for dark theme
                : Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsivePadding(context, small: 12, normal: 16),
          vertical: ResponsiveUtils.getResponsivePadding(context, small: 10, normal: 14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, small: 4, normal: 6)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.people_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: ResponsiveUtils.isSmallScreen(context) ? 14 : 16,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, small: 6, normal: 10)),
                Text(
                  'Split Overview',
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 14, normal: 16),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<Widget>(
                        builder: (BuildContext context) => const AllSplitsScreen(),
                      ),
                    );
                  },
                  child: Text('View All', 
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (friendsToDisplay.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 36,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No friends added yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add friends to start splitting expenses together',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: friendsToDisplay.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
                itemBuilder: (BuildContext context, int index) {
                  final AppUser friend = friendsToDisplay[index];
                  final double balance = netOwed[friend.id] ?? 0.0;

                  String balanceText;
                  Color balanceColor;
                  Color amountColor;
                  bool isSettled = balance == 0.0;

                  if (isSettled) {
                    final DateTime? lastExpenseDate = expenseManager.getLastExpenseDateBetween(currentUserId, friend.id);
                    if (lastExpenseDate != null) {
                      balanceText = 'Settled on ${DateFormat('MMM d').format(lastExpenseDate)}';
                    } else {
                      balanceText = 'Settled';
                    }
                    balanceColor = Theme.of(context).colorScheme.onSurfaceVariant;
                    amountColor = Theme.of(context).colorScheme.onSurfaceVariant;
                  } else {
                    final bool youOwe = balance < 0;
                    balanceText = youOwe ? 'You owe' : 'Owes you';
                    balanceColor = youOwe ? const Color(0xFFFF6B6B) : const Color(0xFF10B981);
                    amountColor = youOwe ? const Color(0xFFFF6B6B) : const Color(0xFF10B981);
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<Widget>(
                          builder: (BuildContext context) => SplitDetailScreen(
                            currentUserId: currentUserId,
                            otherUserId: friend.id,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          // Friend Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              ProfileUtils.getInitials(friend.name),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Friend Name and Status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend.username,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      isSettled 
                                          ? Icons.check_circle_outline 
                                          : (balance < 0 ? Icons.arrow_upward : Icons.arrow_downward),
                                      size: 13,
                                      color: balanceColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      balanceText,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: balanceColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Amount
                          Text(
                            isSettled
                                ? ''
                                : ResponsiveUtils.formatAmountWithK(balance.abs()),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: amountColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// --- NEW: Insights Screen ---
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool isMonthlyView = true; // Toggle between monthly and weekly view
  int? tappedBarIndex; // Track which bar is tapped in weekly view

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<ExpenseManager>(
          builder: (BuildContext context, ExpenseManager expenseManager, Widget? child) {
            final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
            final String currentUserId = authManager.currentUser?.id ?? 'unknown_user';

            return SingleChildScrollView(
              padding: ResponsiveUtils.getResponsiveScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 16, normal: 20)),
                  
                  // Header
                  Text(
                    'Financial Insights',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 24, normal: 28),
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, small: 6, normal: 8)),
                  Text(
                    'Track your spending patterns and financial health',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 14, normal: 16),
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 24, normal: 32)),

                  // 1. Spending Summary
                  _buildSummarySection(context, expenseManager, currentUserId),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 24, normal: 32)),

                  // 2. Monthly/Weekly Spending Graph with Toggle
                  _buildSpendingOverviewChart(context, expenseManager, currentUserId),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 24, normal: 32)),

                  // 3. Spending by Category (smaller chart)
                  _buildCategoryAnalysisChart(context, expenseManager),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 24, normal: 32)),

                  // 4. Top Spending Categories
                  _buildTopCategoriesSection(context, expenseManager),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, small: 20, normal: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, ExpenseManager expenseManager, String currentUserId) {
    final DateTime now = DateTime.now();
    final double todaySpend = expenseManager.getCurrentDailyPersonalSpend(now, currentUserId);
    final double monthSpend = expenseManager.getCurrentMonthlyPersonalSpend(now, currentUserId);
    final double weekSpend = _getWeeklySpend(expenseManager, currentUserId);
    final double avgDaily = now.day > 0 ? monthSpend / now.day : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Summary',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: ResponsiveUtils.isTablet(context) ? 4 : 2,
          crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, small: 8, normal: 12),
          mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, small: 8, normal: 12),
          childAspectRatio: ResponsiveUtils.isSmallScreen(context) ? 1.1 : 1.2,
          children: [
            _buildSummaryCard(
              context,
              'Today',
              todaySpend >= 10000 
                  ? ResponsiveUtils.formatAmountWithK(todaySpend)
                  : '₹${todaySpend.toStringAsFixed(0)}',
              Icons.today_outlined,
              const Color(0xFF3B82F6),
              const Color(0xFFEBF4FF),
            ),
            _buildSummaryCard(
              context,
              'This Week',
              weekSpend >= 10000
                  ? ResponsiveUtils.formatAmountWithK(weekSpend)
                  : '₹${weekSpend.toStringAsFixed(0)}',
              Icons.date_range_outlined,
              const Color(0xFF10B981),
              const Color(0xFFECFDF5),
            ),
            _buildSummaryCard(
              context,
              'This Month',
              monthSpend >= 10000
                  ? ResponsiveUtils.formatAmountWithK(monthSpend)
                  : '₹${monthSpend.toStringAsFixed(0)}',
              Icons.calendar_month_outlined,
              const Color(0xFF8B5CF6),
              const Color(0xFFF3F4F6),
            ),
            _buildSummaryCard(
              context,
              'Daily Average',
              avgDaily >= 10000
                  ? ResponsiveUtils.formatAmountWithK(avgDaily)
                  : '₹${avgDaily.toStringAsFixed(0)}',
              Icons.trending_up_outlined,
              const Color(0xFFF59E0B),
              const Color(0xFFFEF3C7),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color iconColor, Color bgColor) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final cardPadding = ResponsiveUtils.getResponsivePadding(context, small: 12, normal: 16);
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          Container(
            width: isSmallScreen ? 32 : 40,
            height: isSmallScreen ? 32 : 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon, 
              color: iconColor, 
              size: isSmallScreen ? 16 : 20,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 10, normal: 11),
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isSmallScreen ? 1 : 2),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 14 : 18,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingOverviewChart(BuildContext context, ExpenseManager expenseManager, String currentUserId) {
    final Map<String, double> monthlyData = isMonthlyView 
        ? _getMonthlySpendingData(expenseManager, currentUserId)
        : _getWeeklyTrendData(expenseManager, currentUserId);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: const Color(0xFF6366F1), size: 24),
              const SizedBox(width: 12),
              Text(
                isMonthlyView ? 'Monthly Spending Trend' : 'Weekly Spending Pattern',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Toggle Button below the title
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('Monthly', isMonthlyView, () {
                      setState(() {
                        isMonthlyView = true;
                      });
                    }),
                    _buildToggleButton('Weekly', !isMonthlyView, () {
                      setState(() {
                        isMonthlyView = false;
                      });
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: monthlyData.isEmpty 
              ? Center(
                  child: Text(
                    'No spending data available',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                )
              : isMonthlyView 
                ? LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: const Color(0xFF6366F1),
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tooltipMargin: 8,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              final value = touchedSpot.y;
                              return LineTooltipItem(
                                value >= 1000 
                                  ? ResponsiveUtils.formatAmountWithK(value)
                                  : '₹${value.toStringAsFixed(0)}',
                                GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                          return spotIndexes.map((index) {
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: const Color(0xFF6366F1).withOpacity(0.5),
                                strokeWidth: 2,
                                dashArray: [5, 5],
                              ),
                              FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                  radius: 6,
                                  color: const Color(0xFF6366F1),
                                  strokeWidth: 3,
                                  strokeColor: Colors.white,
                                ),
                              ),
                            );
                          }).toList();
                        },
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1000,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              if (value >= 1000) {
                                return Text(
                                  ResponsiveUtils.formatAmountWithK(value),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                );
                              }
                              return Text(
                                '₹${value.toInt()}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final months = monthlyData.keys.toList();
                              if (value.toInt() < months.length) {
                                return Text(
                                  months[value.toInt()],
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: monthlyData.entries.map((e) => FlSpot(
                            monthlyData.keys.toList().indexOf(e.key).toDouble(),
                            e.value,
                          )).toList(),
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1).withOpacity(0.3),
                                const Color(0xFF8B5CF6).withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF6366F1),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: monthlyData.values.isNotEmpty ? monthlyData.values.reduce((a, b) => a > b ? a : b) * 1.2 : 100,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, barTouchResponse) {
                          setState(() {
                            if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                              tappedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                            } else if (event is FlPanEndEvent || event is FlLongPressEnd) {
                              tappedBarIndex = null;
                            }
                          });
                        },
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: const Color(0xFF6366F1),
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tooltipMargin: 8,
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final entries = monthlyData.entries.toList();
                            if (groupIndex < entries.length) {
                              final value = entries[groupIndex].value;
                              return BarTooltipItem(
                                value >= 1000 
                                  ? ResponsiveUtils.formatAmountWithK(value)
                                  : '₹${value.toStringAsFixed(0)}',
                                GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              if (value >= 1000) {
                                return Text(
                                  ResponsiveUtils.formatAmountWithK(value),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                );
                              }
                              return Text(
                                '₹${value.toInt()}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = monthlyData.keys.toList();
                              if (value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: monthlyData.entries.map((entry) {
                        final index = monthlyData.keys.toList().indexOf(entry.key);
                        final isTapped = tappedBarIndex == index;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              gradient: LinearGradient(
                                colors: isTapped 
                                  ? [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]
                                  : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: isTapped ? 28 : 24,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                          showingTooltipIndicators: isTapped ? [0] : [],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryAnalysisChart(BuildContext context, ExpenseManager expenseManager) {
    final Map<ExpenseCategory, double> categorySums = expenseManager.getTotalSpendByCategory();
    final double total = categorySums.values.fold(0.0, (sum, amount) => sum + amount);

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No category data available',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFF59E0B),
      const Color(0xFFEF4444), const Color(0xFF8B5CF6), const Color(0xFF06B6D4),
      const Color(0xFFEC4899), const Color(0xFF84CC16), const Color(0xFFF97316),
    ];

    int index = 0;
    for (final entry in categorySums.entries) {
      if (entry.value > 0) {
        final percentage = (entry.value / total) * 100;
        sections.add(
          PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value,
            title: percentage > 8 ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: 45, // Reduced from 60 to make chart smaller and rounder
            titleStyle: GoogleFonts.inter(
              fontSize: 11, // Reduced font size
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
        index++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: const Color(0xFF10B981), size: 24),
              const SizedBox(width: 12),
              Text(
                'Spending by Category',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 180, // Reduced height from default
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2, // Reduced section space
                      centerSpaceRadius: 35, // Reduced center space for smaller, rounder chart
                      startDegreeOffset: -90,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categorySums.entries
                      .where((entry) => entry.value > 0)
                      .take(6)
                      .map((entry) {
                    final categoryIndex = categorySums.keys.toList().indexOf(entry.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8), // Reduced padding
                      child: Row(
                        children: [
                          Container(
                            width: 10, // Reduced size
                            height: 10, // Reduced size
                            decoration: BoxDecoration(
                              color: colors[categoryIndex % colors.length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6), // Reduced spacing
                          Expanded(
                            child: Text(
                              entry.key.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 11, // Reduced font size
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesSection(BuildContext context, ExpenseManager expenseManager) {
    final Map<ExpenseCategory, double> categorySums = expenseManager.getTotalSpendByCategory();
    final List<MapEntry<ExpenseCategory, double>> sortedCategories = categorySums.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: const Color(0xFFEF4444), size: 24),
              const SizedBox(width: 12),
              Text(
                'Top Spending Categories',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...topCategories.map((entry) {
            final total = categorySums.values.fold(0.0, (sum, amount) => sum + amount);
            final percentage = total > 0 ? (entry.value / total) * 100 : 0;
            final colors = [
              const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFF59E0B),
              const Color(0xFFEF4444), const Color(0xFF8B5CF6),
            ];
            final colorIndex = topCategories.indexOf(entry);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors[colorIndex].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          entry.key.icon,
                          color: colors[colorIndex],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${percentage.toStringAsFixed(1)}% of total spending',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors[colorIndex],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: colors[colorIndex].withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(colors[colorIndex]),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  double _getWeeklySpend(ExpenseManager expenseManager, String currentUserId) {
    final DateTime now = DateTime.now();
    // Calculate Monday of current week at start of day (00:00:00)
    final int currentWeekday = now.weekday;
    final DateTime monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));
    final DateTime sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    double totalWeeklySpend = 0.0;
    
    for (final expense in expenseManager.expenses) {
      if (expense.date.isAfter(monday.subtract(const Duration(seconds: 1))) && 
          expense.date.isBefore(sunday.add(const Duration(seconds: 1)))) {
        
        // Calculate user's share of this expense
        if (expense.splitDetails.isEmpty) {
          // No split details - if user paid, they bear full cost
          if (expense.payerId == currentUserId) {
            totalWeeklySpend += expense.amount;
          }
        } else {
          // Has split details - find user's share
          final userSplit = expense.splitDetails.firstWhere(
            (split) => split.userId == currentUserId,
            orElse: () => SplitShare(userId: currentUserId, amount: 0.0),
          );
          totalWeeklySpend += userSplit.amount;
        }
      }
    }
    
    return totalWeeklySpend;
  }

  Map<String, double> _getMonthlySpendingData(ExpenseManager expenseManager, String currentUserId) {
    final Map<String, double> monthlyData = {};
    final DateTime now = DateTime.now();
    
    // Get last 6 months of data
    for (int i = 5; i >= 0; i--) {
      final DateTime targetMonth = DateTime(now.year, now.month - i, 1);
      final String monthKey = DateFormat('MMM').format(targetMonth);
      
      double monthSpend = 0.0;
      
      for (final expense in expenseManager.expenses) {
        if (expense.date.year == targetMonth.year && 
            expense.date.month == targetMonth.month) {
          
          // Calculate user's share of this expense
          if (expense.splitDetails.isEmpty) {
            // No split details - if user paid, they bear full cost
            if (expense.payerId == currentUserId) {
              monthSpend += expense.amount;
            }
          } else {
            // Has split details - find user's share
            final userSplit = expense.splitDetails.firstWhere(
              (split) => split.userId == currentUserId,
              orElse: () => SplitShare(userId: currentUserId, amount: 0.0),
            );
            monthSpend += userSplit.amount;
          }
        }
      }
      
      monthlyData[monthKey] = monthSpend;
    }
    
    return monthlyData;
  }

  Map<String, double> _getWeeklyTrendData(ExpenseManager expenseManager, String currentUserId) {
    final Map<String, double> weeklyData = {};
    final DateTime now = DateTime.now();
    
    // Calculate Monday of current week (Monday = 1, Sunday = 7)
    final int currentWeekday = now.weekday;
    final DateTime monday = now.subtract(Duration(days: currentWeekday - 1));
    
    // Get current week's data (Monday to Sunday)
    for (int i = 0; i < 7; i++) {
      final DateTime targetDay = monday.add(Duration(days: i));
      final String dayKey = DateFormat('E').format(targetDay); // Mon, Tue, Wed, etc.
      
      double daySpend = 0.0;
      
      for (final expense in expenseManager.expenses) {
        if (expense.date.year == targetDay.year && 
            expense.date.month == targetDay.month && 
            expense.date.day == targetDay.day) {
          
          // Calculate user's share of this expense
          if (expense.splitDetails.isEmpty) {
            // No split details - if user paid, they bear full cost
            if (expense.payerId == currentUserId) {
              daySpend += expense.amount;
            }
          } else {
            // Has split details - find user's share
            final userSplit = expense.splitDetails.firstWhere(
              (split) => split.userId == currentUserId,
              orElse: () => SplitShare(userId: currentUserId, amount: 0.0),
            );
            daySpend += userSplit.amount;
          }
        }
      }
      
      weeklyData[dayKey] = daySpend;
    }
    
    return weeklyData;
  }
}

class DashboardSummaryCards extends StatelessWidget {
  final ExpenseManager expenseManager;
  final String currentUserId; // Added to get current user's ID

  const DashboardSummaryCards({
    super.key,
    required this.expenseManager,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    // Calculate personal spend for Today
    final double todayPersonalSpend =
        expenseManager.getCurrentDailyPersonalSpend(now, currentUserId);

    // Calculate personal spend for This Month
    final double currentMonthPersonalSpend =
        expenseManager.getCurrentMonthlyPersonalSpend(now, currentUserId);

    // According to the prompt, if money is 'used' (spent), the color should be red.
    // Personal spend is always money 'used'.
    final Color usedMoneyColor = Theme.of(context).colorScheme.error;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: <Widget>[
        // Reordered: Today card before This Month card
        _buildSummaryCard(
            context,
            'Today',
            ResponsiveUtils.formatAmountWithK(todayPersonalSpend),
            Icons.today,
            valueColor: usedMoneyColor),
        _buildSummaryCard(
            context,
            'This Month',
            ResponsiveUtils.formatAmountWithK(currentMonthPersonalSpend),
            Icons.calendar_month,
            valueColor: usedMoneyColor),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value,
      IconData icon, {Color? valueColor}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class SharedExpensesSummary extends StatelessWidget {
  final ExpenseManager expenseManager;
  final String currentUserId;

  const SharedExpensesSummary({
    super.key,
    required this.expenseManager,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, double> netOwed =
        expenseManager.getOwedAmounts(currentUserId);
    final List<MapEntry<String, double>> owingToOthers = netOwed.entries
        .where((MapEntry<String, double> entry) => entry.value < 0)
        .toList();
    final List<MapEntry<String, double>> othersOwingToMe = netOwed.entries
        .where((MapEntry<String, double> entry) => entry.value > 0)
        .toList();

    final double totalOwedToMe = othersOwingToMe.fold(
        0.0, (double sum, MapEntry<String, double> entry) => sum + entry.value);
    final double totalIOwe = owingToOthers.fold(
        0.0, (double sum, MapEntry<String, double> entry) => sum + entry.value.abs());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Shared Expenses Ledger',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (owingToOthers.isEmpty && othersOwingToMe.isEmpty)
              Text(
                'No outstanding shared expenses.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...<Widget>[
              if (othersOwingToMe.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'You are owed:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...othersOwingToMe.map<Widget>((MapEntry<String, double> entry) {
                      final AppUser? user = expenseManager.allUsers.firstWhereOrNull(
                          (AppUser user) => user.id == entry.key);
                      return ListTile(
                        onTap: () {
                          if (user != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute<Widget>(
                                builder: (BuildContext context) => SplitDetailScreen(
                                  currentUserId: currentUserId,
                                  otherUserId: user.id,
                                ),
                              ),
                            );
                          }
                        },
                        title: Text('${user?.username ?? 'Unknown'}'),
                        trailing: Text(
                          ResponsiveUtils.formatAmountWithK(entry.value.abs()),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.green.shade700, // Professional green
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        leading: Icon(Icons.arrow_circle_right,
                            color: Colors.green.shade700), // Professional green
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }).toList(),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Total you are owed:',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ResponsiveUtils.formatAmountWithK(totalOwedToMe),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.green.shade700, // Professional green
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              if (owingToOthers.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'You owe:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...owingToOthers.map<Widget>((MapEntry<String, double> entry) {
                      final AppUser? user = expenseManager.allUsers.firstWhereOrNull(
                          (AppUser user) => user.id == entry.key);
                      return ListTile(
                        onTap: () {
                          if (user != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute<Widget>(
                                builder: (BuildContext context) => SplitDetailScreen(
                                  currentUserId: currentUserId,
                                  otherUserId: user.id,
                                ),
                              ),
                            );
                          }
                        },
                        title: Text('${user?.username ?? 'Unknown'}'),
                        trailing: Text(
                          ResponsiveUtils.formatAmountWithK(entry.value.abs()),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error, // Professional red (theme-aware)
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        leading: Icon(Icons.arrow_circle_left,
                            color: Theme.of(context)
                                .colorScheme
                                .error), // Professional red (theme-aware)
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }).toList(),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Total you owe:',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ResponsiveUtils.formatAmountWithK(totalIOwe),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error, // Professional red (theme-aware)
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// Helper extension for List to find first item or return null
extension _IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final T element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

class ExpensesByCategoryChart extends StatelessWidget {
  final ExpenseManager expenseManager;

  const ExpensesByCategoryChart({super.key, required this.expenseManager});

  @override
  Widget build(BuildContext context) {
    final Map<ExpenseCategory, double> categorySums =
        expenseManager.getTotalSpendByCategory();
    final double total =
        categorySums.values.fold(0.0, (double sum, double amount) => sum + amount);

    final List<PieChartSectionData> sections = <PieChartSectionData>[];
    int i = 0;
    for (final MapEntry<ExpenseCategory, double> entry in categorySums.entries) {
      if (entry.value > 0) {
        final double percentage = total > 0 ? (entry.value / total) * 100 : 0;
        sections.add(
          PieChartSectionData(
            color: _getChartColor(i, context),
            value: entry.value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            showTitle: percentage > 5, // Only show title if slice is large enough
          ),
        );
        i++;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Expenses by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (sections.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No expenses recorded yet.'),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 1.3,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    startDegreeOffset: -90,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categorySums.entries
                  .where((MapEntry<ExpenseCategory, double> entry) => entry.value > 0)
                  .map<Widget>((MapEntry<ExpenseCategory, double> entry) {
                final int index =
                    ExpenseCategory.values.indexOf(entry.key); // Consistent index for color
                return _LegendItem(
                  color: _getChartColor(index, context),
                  title: entry.key.displayName,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChartColor(int index, BuildContext context) {
    final List<Color> colors = <Color>[
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.surfaceContainerHighest,
      const Color.fromARGB(255, 76, 175, 80), // Equivalent to Colors.green (0xFF4CAF50)
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.blueGrey,
    ];
    return colors[index % colors.length];
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String title;

  const _LegendItem({required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class MonthlySpendTrendChart extends StatelessWidget {
  final ExpenseManager expenseManager;

  const MonthlySpendTrendChart({super.key, required this.expenseManager});

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, double> monthlySpend =
        expenseManager.getMonthlySpendTrend(6); // Last 6 months
    final List<DateTime> months = monthlySpend.keys.toList()..sort();

    final List<BarChartGroupData> barGroups = <BarChartGroupData>[];
    double maxY = 0.0;
    for (int i = 0; i < months.length; i++) {
      final DateTime month = months[i];
      final double amount = monthlySpend[month] ?? 0.0;
      if (amount > maxY) maxY = amount;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: <BarChartRodData>[
            BarChartRodData(
              toY: amount,
              color: Theme.of(context).colorScheme.primary,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          showingTooltipIndicators: const <int>[0], // Show tooltip for each bar (value)
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Monthly Spend Trend (Last 6 Months)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.6,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final DateTime month = months[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _getMonthShortName(month.month),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                        reservedSize: 32,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '₹${value.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.2, // Add some padding above max bar
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (BarChartGroupData group, int groupIndex,
                          BarChartRodData rod, int rodIndex) {
                        return BarTooltipItem(
                          ResponsiveUtils.formatAmountWithK(rod.toY),
                          TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthShortName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }
}

class RecentExpensesList extends StatelessWidget {
  final ExpenseManager expenseManager;

  const RecentExpensesList({super.key, required this.expenseManager});

  @override
  Widget build(BuildContext context) {
    final List<Expense> recentExpenses =
        List<Expense>.from(expenseManager.expenses);
    recentExpenses.sort(
        (Expense a, Expense b) => b.date.compareTo(a.date)); // Sort by date descending

    // Show empty state if no expenses
    if (recentExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No expense added yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first expense to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: recentExpenses.take(5).map<Widget>((Expense expense) {
        return ExpenseListItem(expense: expense);
      }).toList(),
    );
  }
}

class ExpenseListItem extends StatelessWidget {
  final Expense expense;

  const ExpenseListItem({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    // Get current user ID to calculate personal share
    final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
    final String currentUserId = authManager.currentUser?.id ?? 'unknown_user';
    
    // Calculate user's personal share and amount owed to them
    double personalShare;
    double amountOwedToMe = 0.0;
    bool isOwedToMe = false;
    
    if (expense.splitDetails.isEmpty) {
      // No split details - if user paid, they bear full cost
      personalShare = expense.payerId == currentUserId ? expense.amount : 0.0;
    } else {
      // Has split details - find user's share
      final userSplit = expense.splitDetails.firstWhere(
        (split) => split.userId == currentUserId,
        orElse: () => SplitShare(userId: currentUserId, amount: 0.0),
      );
      personalShare = userSplit.amount;
      
      // If user paid but their share is 0 or less than total, calculate how much others owe them
      if (expense.payerId == currentUserId) {
        amountOwedToMe = expense.amount - personalShare;
        isOwedToMe = amountOwedToMe > 0;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(
                color: const Color(0xFF374151), // Subtle border for dark theme
                width: 1,
              )
            : Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2) // Stronger shadow for dark theme
                : Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        onDismissed: (DismissDirection direction) {
          Provider.of<ExpenseManager>(context, listen: false).deleteExpense(expense.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${expense.title} deleted'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.1),
                Colors.red.withOpacity(0.3),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<Widget>(
                  builder: (BuildContext context) => AddExpenseScreen(expense: expense),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      expense.category.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                expense.category.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              ' • ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                DateFormat('MMM d, yyyy').format(expense.date),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOwedToMe
                                ? (Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF10B981).withOpacity(0.2)
                                    : const Color(0xFF10B981).withOpacity(0.1))
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFF87171).withOpacity(0.2)
                                    : const Color(0xFFFF6B6B).withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOwedToMe
                                ? '+${ResponsiveUtils.formatAmountWithK(amountOwedToMe)}'
                                : '-${ResponsiveUtils.formatAmountWithK(personalShare)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isOwedToMe
                                  ? const Color(0xFF10B981) // Green for money owed to you
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFFFF6B6B)), // Red for your expenses
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Add/Edit Expense Screen ---

// Enum for the 5 distinct splitting options
enum _SplitOption {
  iPaidEvenly, // "You paid, split equally."
  iAmOwedFullAmount, // "You are owed the full amount." (I paid, but my share is 0, others split the full amount)
  friendPaidEvenly, // "Friend paid, split equally."
  friendIsOwedFullAmount, // "Friend is owed the full amount." (Friend paid, but their share is 0, others split the full amount)
  manualSplit, // "Split Unequally" - This option allows user to select payer and manually enter shares
}

// --- Add Placeholder Screen ---

class AddPlaceholderScreen extends StatelessWidget {
  const AddPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Options',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Calendar Screen ---

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isWeeklyView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<ExpenseManager>(
          builder: (context, expenseManager, child) {
            final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
            final String currentUserId = authManager.currentUser?.id ?? 'unknown_user';
            
            return Column(
              children: [
                // Header with view toggle
                Container(
                  padding: ResponsiveUtils.getResponsiveScreenPadding(context),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Calendar',
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 20, normal: 24),
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                      // View toggle buttons below the title
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildViewToggle('Monthly', !_isWeeklyView),
                              _buildViewToggle('Weekly', _isWeeklyView),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Calendar
                Expanded(
                  child: SingleChildScrollView(
                    padding: ResponsiveUtils.getResponsiveScreenPadding(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TableCalendar<Expense>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        calendarFormat: _isWeeklyView ? CalendarFormat.week : CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        
                        // Styling
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          titleTextStyle: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          headerPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          weekendStyle: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          cellMargin: const EdgeInsets.all(2),
                          cellPadding: const EdgeInsets.all(0),
                          defaultDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          weekendDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          _showDayExpenses(context, selectedDay, expenseManager, currentUserId);
                        },
                        
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            return _buildCalendarDay(context, day, expenseManager, currentUserId);
                          },
                          selectedBuilder: (context, day, focusedDay) {
                            return _buildCalendarDay(context, day, expenseManager, currentUserId, isSelected: true);
                          },
                          todayBuilder: (context, day, focusedDay) {
                            return _buildCalendarDay(context, day, expenseManager, currentUserId, isToday: true);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewToggle(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isWeeklyView = text == 'Weekly';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarDay(BuildContext context, DateTime day, ExpenseManager expenseManager, String currentUserId, {bool isSelected = false, bool isToday = false}) {
    // Get expenses for this day
    final dayExpenses = expenseManager.expenses.where((expense) {
      return isSameDay(expense.date, day) && 
             (expense.payerId == currentUserId || expense.splitDetails.any((s) => s.userId == currentUserId));
    }).toList();
    
    // Calculate total expense for the day
    double totalExpense = 0.0;
    for (final expense in dayExpenses) {
      if (expense.payerId == currentUserId) {
        totalExpense += expense.amount;
      } else {
        final userSplit = expense.splitDetails.firstWhere(
          (s) => s.userId == currentUserId,
          orElse: () => SplitShare(userId: currentUserId, amount: 0.0),
        );
        totalExpense += userSplit.amount;
      }
    }
    
    // Check if over limit (assuming daily limit of ₹500 for demo)
    const double dailyLimit = 500.0;
    final bool isOverLimit = totalExpense > dailyLimit;
    
    Color backgroundColor;
    Color textColor;
    
    if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = const Color(0xFF6366F1); // Modern indigo for today
      textColor = Colors.white;
    } else if (isOverLimit) {
      backgroundColor = const Color(0xFFEF4444); // Modern red for over limit
      textColor = Colors.white;
    } else if (totalExpense > 0) {
      backgroundColor = const Color(0xFF10B981); // Modern emerald for expenses
      textColor = Colors.white;
    } else {
      backgroundColor = Theme.of(context).colorScheme.surface;
      textColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    }
    
    return Container(
      margin: const EdgeInsets.all(2),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected ? [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : (totalExpense > 0 && !isOverLimit) ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
              height: 1.1,
            ),
          ),
          if (totalExpense > 0) ...[
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                totalExpense >= 1000 
                    ? '₹${(totalExpense / 1000).toStringAsFixed(1)}k'
                    : '₹${totalExpense.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDayExpenses(BuildContext context, DateTime day, ExpenseManager expenseManager, String currentUserId) {
    final dayExpenses = expenseManager.expenses.where((expense) {
      return isSameDay(expense.date, day) && 
             (expense.payerId == currentUserId || expense.splitDetails.any((s) => s.userId == currentUserId));
    }).toList();
    
    if (dayExpenses.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'No Expenses',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No expenses recorded for',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(day),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start tracking your expenses to see them appear here.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayExpensesScreen(
          date: day,
          expenses: dayExpenses,
          currentUserId: currentUserId,
        ),
      ),
    );
  }
}

// Helper function
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// Day Expenses Screen
class DayExpensesScreen extends StatelessWidget {
  final DateTime date;
  final List<Expense> expenses;
  final String currentUserId;

  const DayExpensesScreen({
    super.key,
    required this.date,
    required this.expenses,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    double totalExpense = 0.0;
    for (final expense in expenses) {
      if (expense.payerId == currentUserId) {
        totalExpense += expense.amount;
      } else {
        final userSplit = expense.splitDetails.firstWhere(
          (s) => s.userId == currentUserId,
          orElse: () => SplitShare(userId: currentUserId, amount: 0.0),
        );
        totalExpense += userSplit.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMM dd, yyyy').format(date)),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Total Expenses',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ResponsiveUtils.formatAmountWithK(totalExpense),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Expenses list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                final bool isPayer = expense.payerId == currentUserId;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(expense.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(expense.category),
                        color: _getCategoryColor(expense.category),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      expense.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          isPayer ? 'You paid' : 'Your share',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          DateFormat('hh:mm a').format(expense.date),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      isPayer 
                          ? ResponsiveUtils.formatAmountWithK(expense.amount)
                          : ResponsiveUtils.formatAmountWithK(expense.splitDetails.firstWhere((s) => s.userId == currentUserId, orElse: () => SplitShare(userId: currentUserId, amount: 0.0)).amount),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE53E3E), // Red for all amounts
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFF4CAF50);
      case ExpenseCategory.transportation:
        return const Color(0xFF2196F3);
      case ExpenseCategory.housing:
        return const Color(0xFF9C27B0);
      case ExpenseCategory.entertainment:
        return const Color(0xFFFF5722);
      case ExpenseCategory.utilities:
        return const Color(0xFF607D8B);
      case ExpenseCategory.groceries:
        return const Color(0xFF4CAF50);
      case ExpenseCategory.shopping:
        return const Color(0xFFFF9800);
      case ExpenseCategory.health:
        return const Color(0xFFE91E63);
      case ExpenseCategory.education:
        return const Color(0xFF00BCD4);
      case ExpenseCategory.travel:
        return const Color(0xFF795548);
      case ExpenseCategory.other:
        return const Color(0xFF795548);
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.housing:
        return Icons.home;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.utilities:
        return Icons.electrical_services;
      case ExpenseCategory.groceries:
        return Icons.local_grocery_store;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.health:
        return Icons.medical_services;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.travel:
        return Icons.flight;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense; // Null if adding new, not null if editing
  final VoidCallback? onSaveAndNavigateBack; // Callback for navigating back in PageView

  const AddExpenseScreen({super.key, this.expense, this.onSaveAndNavigateBack});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;

  _SplitOption? _selectedSplitOption; // Mandatory selection
  String? _selectedPayerId; // Derived or user-selected for manual split
  String? _selectedFriendPayerId; // Only relevant for friendPaid scenarios
  final List<AppUser> _selectedSplitUsers =
      <AppUser>[]; // List of people *other than the determined payer* involved in the split
  final Map<String, double> _splitAmounts =
      <String, double>{}; // Stores amounts for ALL people involved in the split (payer + others)

  @override
  void initState() {
    super.initState();
    final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
    final ExpenseManager expenseManager = Provider.of<ExpenseManager>(context, listen: false);
    final AppUser? currentUser = authManager.currentUser;

    _titleController = TextEditingController(text: widget.expense?.title ?? '');
    _amountController =
        TextEditingController(text: widget.expense?.amount.toStringAsFixed(2) ?? '');
    _selectedCategory = widget.expense?.category ?? ExpenseCategory.food;
    _selectedDate = widget.expense?.date ?? DateTime.now();

    if (widget.expense != null) {
      // Editing existing expense: try to infer the split option and populate state
      _selectedPayerId = widget.expense!.payerId;
      _selectedFriendPayerId = (_selectedPayerId != currentUser?.id) ? _selectedPayerId : null;

      if (widget.expense!.splitDetails.isEmpty || widget.expense!.splitDetails.length == 1 && widget.expense!.splitDetails.first.userId == _selectedPayerId) {
        // No actual split, or only payer's share recorded means payer paid for self
        _selectedSplitOption = (_selectedPayerId == currentUser?.id) ? _SplitOption.iAmOwedFullAmount : _SplitOption.friendIsOwedFullAmount;
      } else {
        // There are split details, try to infer if it was an even split
        final double totalAmount = widget.expense!.amount;
        final List<SplitShare> shares = widget.expense!.splitDetails;
        final Set<String> participantIds = shares.map((SplitShare s) => s.userId).toSet();
        final int numParticipants = participantIds.length;

        bool isEvenSplit = true;
        if (numParticipants > 0) {
          final double expectedEvenShare = totalAmount / numParticipants;
          for (final SplitShare share in shares) {
            if ((share.amount - expectedEvenShare).abs() > 0.01) {
              isEvenSplit = false;
              break;
            }
          }
        } else {
          isEvenSplit = false; // Should not happen with splitDetails.isNotEmpty
        }

        if (isEvenSplit) {
          if (_selectedPayerId == currentUser?.id) {
            _selectedSplitOption = _SplitOption.iPaidEvenly;
          } else {
            _selectedSplitOption = _SplitOption.friendPaidEvenly;
          }
        } else {
          // Default to manual split if not clearly even
          _selectedSplitOption = _SplitOption.manualSplit;
        }

        // Populate _selectedSplitUsers and _splitAmounts based on existing data
        _selectedSplitUsers.clear();
        for (final SplitShare split in widget.expense!.splitDetails) {
          _splitAmounts[split.userId] = split.amount;
          if (split.userId != _selectedPayerId) {
            final AppUser? user = expenseManager.allUsers.firstWhereOrNull((AppUser u) => u.id == split.userId);
            if (user != null) {
              _selectedSplitUsers.add(user);
            }
          }
        }
      }
    } else {
      // Adding new expense, default to current user paying and no specific split method selected yet
      _selectedPayerId = currentUser?.id;
      // No default _selectedSplitOption, user must choose one.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Gets all participants for the current splitting logic (payer + selected others)
  List<AppUser> _getAllActiveSplitParticipants(ExpenseManager expenseManager, AuthManager authManager) {
    final Set<AppUser> participantsSet = <AppUser>{};
    final AppUser? currentUser = authManager.currentUser;

    AppUser? determinedPayer;
    if (_selectedSplitOption == _SplitOption.iPaidEvenly ||
        _selectedSplitOption == _SplitOption.iAmOwedFullAmount) {
      determinedPayer = currentUser;
    } else if (_selectedSplitOption == _SplitOption.friendPaidEvenly ||
               _selectedSplitOption == _SplitOption.friendIsOwedFullAmount) {
      determinedPayer = expenseManager.allUsers.firstWhereOrNull((AppUser u) => u.id == _selectedFriendPayerId);
    } else if (_selectedSplitOption == _SplitOption.manualSplit) {
      determinedPayer = expenseManager.allUsers.firstWhereOrNull((AppUser u) => u.id == _selectedPayerId);
      if (determinedPayer == null && _selectedPayerId == currentUser?.id) {
        determinedPayer = currentUser;
      }
    }

    if (determinedPayer != null) {
      participantsSet.add(determinedPayer);
    }

    for (final AppUser user in _selectedSplitUsers) {
      participantsSet.add(user);
    }
    return participantsSet.toList();
  }

  // Gets participants who are involved in the debt (excluding payer's 0 share cases)
  List<AppUser> _getDebtParticipants(ExpenseManager expenseManager, AuthManager authManager) {
    final Set<AppUser> participantsSet = <AppUser>{};
    final AppUser? currentUser = authManager.currentUser;

    if (_selectedSplitOption == _SplitOption.iAmOwedFullAmount ||
        _selectedSplitOption == _SplitOption.friendIsOwedFullAmount) {
      // In these scenarios, the "selected split users" are the ones who owe.
      for (final AppUser user in _selectedSplitUsers) {
        participantsSet.add(user);
      }
      if (_selectedSplitOption == _SplitOption.friendIsOwedFullAmount && currentUser != null) {
        // If friend is owed, and I am not the payer, then I am also a debt participant.
        if (currentUser.id != _selectedFriendPayerId) {
          participantsSet.add(currentUser);
        }
      }
    } else {
      // For other split types, it includes everyone in _getAllActiveSplitParticipants.
      return _getAllActiveSplitParticipants(expenseManager, authManager);
    }
    return participantsSet.toList();
  }


  // Helper for "Add participant" dialog to get available users
  List<AppUser> _getUsersAvailableToAdd(ExpenseManager expenseManager, AuthManager authManager) {
    final AppUser? currentUser = authManager.currentUser;
    final List<AppUser> allAvailableUsers = List<AppUser>.from(expenseManager.allUsers);
    if (currentUser != null && !allAvailableUsers.contains(currentUser)) {
      allAvailableUsers.add(currentUser);
    }

    AppUser? currentPayer; // Removed 'final' keyword
    if (_selectedSplitOption == _SplitOption.iPaidEvenly ||
        _selectedSplitOption == _SplitOption.iAmOwedFullAmount ||
        _selectedSplitOption == _SplitOption.manualSplit && _selectedPayerId == null) {
      currentPayer = currentUser;
    } else if (_selectedSplitOption == _SplitOption.friendPaidEvenly ||
               _selectedSplitOption == _SplitOption.friendIsOwedFullAmount) {
      currentPayer = expenseManager.allUsers.firstWhereOrNull((AppUser u) => u.id == _selectedFriendPayerId);
    } else if (_selectedSplitOption == _SplitOption.manualSplit) {
      currentPayer = expenseManager.allUsers.firstWhereOrNull((AppUser u) => u.id == _selectedPayerId);
      if (currentPayer == null && _selectedPayerId == currentUser?.id) {
        currentPayer = currentUser;
      }
    } else {
      currentPayer = null;
    }

    return allAvailableUsers
        .where((AppUser user) =>
            !_selectedSplitUsers.contains(user) &&
            (currentPayer == null || user.id != currentPayer.id) // Exclude the determined payer
            )
        .toList();
  }

  List<Widget> _buildSplitShareRows(
      BuildContext context, ExpenseManager expenseManager, AuthManager authManager) {
    final AppUser? currentUser = authManager.currentUser;
    // Participants for share input are all involved users, including payer, whose shares need to be set.
    final List<AppUser> participantsForShareInput = _getAllActiveSplitParticipants(expenseManager, authManager);

    if (participantsForShareInput.isEmpty) {
      return <Widget>[];
    }

    return participantsForShareInput.map<Widget>((AppUser user) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: <Widget>[
            Expanded(
                child: Text(user.id == currentUser?.id ? 'Me (${user.username})' : user.username)),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _splitAmounts[user.id]?.toStringAsFixed(2) ?? '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Share (₹)',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (String value) {
                  _splitAmounts[user.id] = double.tryParse(value) ?? 0.0;
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Please correct the highlighted errors before saving.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    final String title = _titleController.text;
    final double amount = double.parse(_amountController.text);

    final ExpenseManager expenseManager =
        Provider.of<ExpenseManager>(context, listen: false);
    final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
    final String currentUserId = authManager.currentUser?.id ?? 'unknown_user';

    // Validate that a split option is selected
    if (_selectedSplitOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a bill splitting method.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    String? determinedPayerId;
    List<SplitShare> splitDetails = <SplitShare>[];
    List<AppUser> actualParticipantsForSplit = <AppUser>[]; // Participants who actually bear a share

    switch (_selectedSplitOption!) {
      case _SplitOption.iPaidEvenly:
        determinedPayerId = currentUserId;
        actualParticipantsForSplit = _getAllActiveSplitParticipants(expenseManager, authManager);
        if (actualParticipantsForSplit.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please add participants for even split.')),
          );
          return;
        }
        final double evenShare = amount / actualParticipantsForSplit.length;
        for (final AppUser user in actualParticipantsForSplit) {
          splitDetails.add(SplitShare(
            userId: user.id,
            amount: evenShare,
            paid: user.id == determinedPayerId,
          ));
        }
        break;

      case _SplitOption.iAmOwedFullAmount:
        determinedPayerId = currentUserId;
        actualParticipantsForSplit = _getDebtParticipants(expenseManager, authManager);
        if (actualParticipantsForSplit.isEmpty) {
          // If no one else is selected, this means I paid for myself entirely.
          splitDetails.add(SplitShare(userId: currentUserId, amount: amount, paid: true));
        } else {
          // My share is 0, others split the full amount
          splitDetails.add(SplitShare(userId: currentUserId, amount: 0.0, paid: true));
          final double evenShareOthers = amount / actualParticipantsForSplit.length;
          for (final AppUser user in actualParticipantsForSplit) {
            splitDetails.add(SplitShare(userId: user.id, amount: evenShareOthers, paid: false));
          }
        }
        break;

      case _SplitOption.friendPaidEvenly:
        if (_selectedFriendPayerId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select which friend paid.')),
          );
          return;
        }
        determinedPayerId = _selectedFriendPayerId!;
        actualParticipantsForSplit = _getAllActiveSplitParticipants(expenseManager, authManager);
        if (actualParticipantsForSplit.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please add participants for even split.')),
          );
          return;
        }
        final double evenShare = amount / actualParticipantsForSplit.length;
        for (final AppUser user in actualParticipantsForSplit) {
          splitDetails.add(SplitShare(
            userId: user.id,
            amount: evenShare,
            paid: user.id == determinedPayerId,
          ));
        }
        break;

      case _SplitOption.friendIsOwedFullAmount:
        if (_selectedFriendPayerId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select which friend paid.')),
          );
          return;
        }
        determinedPayerId = _selectedFriendPayerId!;
        actualParticipantsForSplit = _getDebtParticipants(expenseManager, authManager);
        if (actualParticipantsForSplit.isEmpty) {
           // If no one else is selected, this means friend paid for themselves entirely.
           splitDetails.add(SplitShare(userId: determinedPayerId, amount: amount, paid: true));
        } else {
          // Friend's share is 0, others split the full amount
          splitDetails.add(SplitShare(userId: determinedPayerId, amount: 0.0, paid: true));
          final double evenShareOthers = amount / actualParticipantsForSplit.length;
          for (final AppUser user in actualParticipantsForSplit) {
            splitDetails.add(SplitShare(userId: user.id, amount: evenShareOthers, paid: false));
          }
        }
        break;

      case _SplitOption.manualSplit: // Corrected from iPaidManualSplit
        if (_selectedPayerId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select who paid for this expense.')),
          );
          return;
        }
        determinedPayerId = _selectedPayerId;
        actualParticipantsForSplit = _getAllActiveSplitParticipants(expenseManager, authManager);

        if (actualParticipantsForSplit.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please add participants for manual split.')),
          );
          return;
        }

        double sumOfManualShares = 0.0;
        for (final AppUser user in actualParticipantsForSplit) {
          sumOfManualShares += _splitAmounts[user.id] ?? 0.0;
        }

        if ((sumOfManualShares - amount).abs() > 0.01) { // Allow for small floating point inaccuracies
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Total of individual shares (₹${sumOfManualShares.toStringAsFixed(2)}) must match the expense amount (₹${amount.toStringAsFixed(2)}).'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }

        for (final AppUser user in actualParticipantsForSplit) {
          splitDetails.add(SplitShare(
            userId: user.id,
            amount: _splitAmounts[user.id] ?? 0.0,
            paid: user.id == determinedPayerId,
          ));
        }
        break;
    }

    // Add logic to check limits before adding/updating the expense
    final bool dailyExceeded = expenseManager.isDailyLimitExceeded(
        amount, splitDetails, _selectedDate, currentUserId);
    final bool monthlyExceeded = expenseManager.isMonthlyLimitExceeded(
        amount, splitDetails, _selectedDate, currentUserId);

    if (dailyExceeded || monthlyExceeded) {
      // Show alert dialog for limit exceeded
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Limit Exceeded!',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dailyExceeded)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your daily spending limit of ₹${expenseManager.dailyLimit?.toStringAsFixed(0)} has been exceeded!',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (monthlyExceeded)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your monthly spending limit of ₹${expenseManager.monthlyLimit?.toStringAsFixed(0)} has been exceeded!',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Do you still want to add this expense?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Proceed
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add Anyway',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ).then((proceed) {
        if (proceed != true) {
          return; // User cancelled, don't add expense
        }
        // User chose to proceed, continue with adding expense
        _proceedWithSavingExpense(
          expenseManager,
          title,
          amount,
          determinedPayerId,
          splitDetails,
        );
      });
      return; // Exit early, the dialog will handle the rest
    }

    // No limits exceeded, proceed normally
    _proceedWithSavingExpense(
      expenseManager,
      title,
      amount,
      determinedPayerId,
      splitDetails,
    );
  }

  void _proceedWithSavingExpense(
    ExpenseManager expenseManager,
    String title,
    double amount,
    String? determinedPayerId,
    List<SplitShare> splitDetails,
  ) {

    String message = '';
    if (widget.expense == null) {
      // Add new expense
      final Expense newExpense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        payerId: determinedPayerId,
        splitDetails: splitDetails,
      );
      expenseManager.addExpense(newExpense);
      message = 'Expense added successfully!';
    } else {
      // Update existing expense
      final Expense updatedExpense = Expense(
        id: widget.expense!.id,
        title: title,
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        receiptImageUrl: widget.expense!.receiptImageUrl,
        payerId: determinedPayerId,
        splitDetails: splitDetails,
      );
      expenseManager.updateExpense(updatedExpense);
      message = 'Expense updated successfully!';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    if (mounted) {
      if (widget.expense == null && widget.onSaveAndNavigateBack != null) {
        // New expense added from the tab bar, navigate back to dashboard tab
        widget.onSaveAndNavigateBack!();
      } else if (widget.expense != null) {
        // Existing expense edited, was pushed as a new route
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseManager expenseManager = Provider.of<ExpenseManager>(context);
    final AuthManager authManager = Provider.of<AuthManager>(context);
    final AppUser? currentUser = authManager.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.expense == null ? 'Add New Expense' : 'Edit Expense',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.expense != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Title Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    hintText: 'Amount',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.currency_rupee,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid positive amount';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Category Section
              Text(
                'Category',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<ExpenseCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    hintText: 'Select Category',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEEFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedCategory.icon,
                        color: const Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ),
                    suffixIcon: const Icon(Icons.keyboard_arrow_down, size: 24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items: ExpenseCategory.values.map<DropdownMenuItem<ExpenseCategory>>(
                    (ExpenseCategory category) {
                      return DropdownMenuItem<ExpenseCategory>(
                        value: category,
                        child: Row(
                          children: <Widget>[
                            Icon(category.icon, size: 20),
                            const SizedBox(width: 10),
                            Text(category.displayName),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (ExpenseCategory? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Date Field
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFFF59E0B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bill Splitting Method Section
              Text(
                'Bill Splitting Method',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: _SplitOption.values.map<Widget>((_SplitOption option) {
                    String title;
                    IconData icon;
                    Color iconBgColor;
                    Color iconColor;
                    
                    switch (option) {
                      case _SplitOption.iPaidEvenly:
                        title = 'I Paid - Split Equally';
                        icon = Icons.group;
                        iconBgColor = const Color(0xFFE8E3FF);
                        iconColor = const Color(0xFF6366F1);
                        break;
                      case _SplitOption.iAmOwedFullAmount:
                        title = 'I Paid - I am owed full amount (Paid for others)';
                        icon = Icons.account_balance_wallet;
                        iconBgColor = const Color(0xFFD1FAE5);
                        iconColor = const Color(0xFF10B981);
                        break;
                      case _SplitOption.friendPaidEvenly:
                        title = 'A Friend Paid - Split Equally';
                        icon = Icons.group;
                        iconBgColor = const Color(0xFFDCEEFF);
                        iconColor = const Color(0xFF3B82F6);
                        break;
                      case _SplitOption.friendIsOwedFullAmount:
                        title = 'A Friend Paid - Friend is owed full amount (Paid for others)';
                        icon = Icons.receipt_long;
                        iconBgColor = const Color(0xFFFEF3C7);
                        iconColor = const Color(0xFFF59E0B);
                        break;
                      case _SplitOption.manualSplit:
                        title = 'Manual Split (Split Unequally)';
                        icon = Icons.calculate;
                        iconBgColor = const Color(0xFFFCE7F3);
                        iconColor = const Color(0xFFEC4899);
                        break;
                    }

                    final bool isLast = option == _SplitOption.values.last;

                    return Column(
                      children: [
                        RadioListTile<_SplitOption>(
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  icon,
                                  color: iconColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          value: option,
                          groupValue: _selectedSplitOption,
                          activeColor: const Color(0xFF6366F1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          onChanged: (_SplitOption? value) {
                            setState(() {
                              _selectedSplitOption = value;
                              if (value != _SplitOption.manualSplit) {
                                _splitAmounts.clear();
                              }
                              if (value == _SplitOption.iPaidEvenly || 
                                  value == _SplitOption.iAmOwedFullAmount || 
                                  value == _SplitOption.manualSplit && _selectedPayerId == null) {
                                _selectedPayerId = currentUser?.id;
                                _selectedFriendPayerId = null;
                              } else if (value == _SplitOption.friendPaidEvenly || 
                                         value == _SplitOption.friendIsOwedFullAmount) {
                                _selectedPayerId = _selectedFriendPayerId;
                              }
                            });
                          },
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 60,
                            color: Colors.grey.shade200,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              
              // Validator for _selectedSplitOption
              if (_selectedSplitOption == null)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                  child: Text(
                    'Please select a bill splitting method.',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Conditional UI elements based on selected split option
              if (_selectedSplitOption != null) ...<Widget>[
                // "Which friend paid?" dropdown
                if (_selectedSplitOption == _SplitOption.friendPaidEvenly ||
                    _selectedSplitOption == _SplitOption.friendIsOwedFullAmount) ...<Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedFriendPayerId,
                      decoration: InputDecoration(
                        hintText: 'Which friend paid?',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEEFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF3B82F6),
                            size: 24,
                          ),
                        ),
                        suffixIcon: const Icon(Icons.keyboard_arrow_down),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      items: expenseManager.allUsers
                          .where((AppUser user) => user.id != currentUser?.id)
                          .map<DropdownMenuItem<String>>(
                            (AppUser user) {
                              return DropdownMenuItem<String>(
                                value: user.id,
                                child: Text(user.username),
                              );
                            },
                          ).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFriendPayerId = newValue;
                          _selectedPayerId = newValue;
                        });
                      },
                      validator: (String? value) {
                        if ((_selectedSplitOption == _SplitOption.friendPaidEvenly || 
                             _selectedSplitOption == _SplitOption.friendIsOwedFullAmount) && 
                            value == null) {
                          return 'Please select a friend who paid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // "Who paid?" dropdown for manual split
                if (_selectedSplitOption == _SplitOption.manualSplit) ...<Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedPayerId,
                      decoration: InputDecoration(
                        hintText: 'Who paid?',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE7F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFFEC4899),
                            size: 24,
                          ),
                        ),
                        suffixIcon: const Icon(Icons.keyboard_arrow_down),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      items: <DropdownMenuItem<String>>[
                        if (currentUser != null)
                          DropdownMenuItem<String>(
                            value: currentUser.id,
                            child: Text('Me (${currentUser.username})'),
                          ),
                        ...expenseManager.allUsers
                            .where((AppUser user) => currentUser == null || user.id != currentUser.id)
                            .map<DropdownMenuItem<String>>(
                              (AppUser user) {
                                return DropdownMenuItem<String>(
                                  value: user.id,
                                  child: Text(user.username),
                                );
                              },
                            ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPayerId = newValue;
                        });
                      },
                      validator: (String? value) {
                        if (_selectedSplitOption == _SplitOption.manualSplit && value == null) {
                          return 'Please select a payer';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Participant selection sections
                if (_selectedSplitOption == _SplitOption.iAmOwedFullAmount || 
                    _selectedSplitOption == _SplitOption.friendIsOwedFullAmount)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Who owes (splits full amount):',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _selectedSplitUsers.map<Widget>((AppUser user) {
                            return Chip(
                              label: Text(
                                user.username,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: const Color(0xFFE8E3FF),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              deleteIconColor: const Color(0xFF6366F1),
                              onDeleted: () {
                                setState(() {
                                  _selectedSplitUsers.remove(user);
                                  _splitAmounts.remove(user.id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.group_add, size: 20),
                          label: Text(
                            'Add person to owe',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                            side: const BorderSide(color: Color(0xFF6366F1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () async {
                            final List<AppUser> availableUsers = 
                                _getUsersAvailableToAdd(expenseManager, authManager);
                            if (availableUsers.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No more friends to add or you are already splitting with all.'),
                                ),
                              );
                              return;
                            }
                            final AppUser? selectedUser = await showDialog<AppUser>(
                              context: context,
                              builder: (BuildContext context) {
                                return SimpleDialog(
                                  title: Text(
                                    'Select a user to owe',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  children: availableUsers.map<SimpleDialogOption>((AppUser user) {
                                    return SimpleDialogOption(
                                      onPressed: () {
                                        Navigator.pop(context, user);
                                      },
                                      child: Text(
                                        user.id == currentUser?.id
                                            ? 'Me (${user.username})'
                                            : user.username,
                                        style: GoogleFonts.inter(),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            );
                            if (selectedUser != null) {
                              setState(() {
                                _selectedSplitUsers.add(selectedUser);
                                _splitAmounts[selectedUser.id] = 0.0;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Split with (others):',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _selectedSplitUsers.map<Widget>((AppUser user) {
                            return Chip(
                              label: Text(
                                user.username,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: const Color(0xFFDCEEFF),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              deleteIconColor: const Color(0xFF3B82F6),
                              onDeleted: () {
                                setState(() {
                                  _selectedSplitUsers.remove(user);
                                  _splitAmounts.remove(user.id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.group_add, size: 20),
                          label: Text(
                            'Add participant',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            side: const BorderSide(color: Color(0xFF3B82F6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () async {
                            final List<AppUser> availableUsers = 
                                _getUsersAvailableToAdd(expenseManager, authManager);
                            if (availableUsers.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No more friends to add or you are already splitting with all.'),
                                ),
                              );
                              return;
                            }
                            final AppUser? selectedUser = await showDialog<AppUser>(
                              context: context,
                              builder: (BuildContext context) {
                                return SimpleDialog(
                                  title: Text(
                                    'Select a user to split with',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  children: availableUsers.map<SimpleDialogOption>((AppUser user) {
                                    return SimpleDialogOption(
                                      onPressed: () {
                                        Navigator.pop(context, user);
                                      },
                                      child: Text(
                                        user.id == currentUser?.id
                                            ? 'Me (${user.username})'
                                            : user.username,
                                        style: GoogleFonts.inter(),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            );
                            if (selectedUser != null) {
                              setState(() {
                                _selectedSplitUsers.add(selectedUser);
                                _splitAmounts[selectedUser.id] = 0.0;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Individual Shares (only for manual split)
                if (_selectedSplitOption == _SplitOption.manualSplit) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Individual Shares:',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                final double totalAmount =
                                    double.tryParse(_amountController.text) ?? 0.0;
                                final List<AppUser> allParticipants =
                                    _getAllActiveSplitParticipants(expenseManager, authManager);

                                if (totalAmount > 0 && allParticipants.isNotEmpty) {
                                  final double evenShare =
                                      totalAmount / allParticipants.length;
                                  setState(() {
                                    for (final AppUser user in allParticipants) {
                                      _splitAmounts[user.id] =
                                          double.parse(evenShare.toStringAsFixed(2));
                                    }
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF6366F1),
                              ),
                              child: Text(
                                'Fill Evenly',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._buildSplitShareRows(context, expenseManager, authManager),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.expense == null ? Icons.add_circle : Icons.check_circle,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.expense == null ? 'Add Expense' : 'Update Expense',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Split Detail Screen ---
class SplitDetailScreen extends StatelessWidget {
  final String currentUserId;
  final String otherUserId;

  const SplitDetailScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseManager>(
      builder: (BuildContext context, ExpenseManager expenseManager, Widget? child) {
        final AppUser? otherUser = expenseManager.allUsers.firstWhereOrNull(
          (AppUser user) => user.id == otherUserId,
        );

        if (otherUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Split Details')),
            body: const Center(child: Text('User not found.')),
          );
        }

        // Filter relevant expenses where both currentUserId and otherUserId are involved
        // AND there's a DIRECT financial relationship between them (one paid for the other)
        final List<Expense> relevantExpenses =
            expenseManager.expenses.where((Expense expense) {
          final SplitShare? currentUserShare = expense.splitDetails.firstWhereOrNull(
            (SplitShare split) => split.userId == currentUserId,
          );
          final SplitShare? otherUserShare = expense.splitDetails.firstWhereOrNull(
            (SplitShare split) => split.userId == otherUserId,
          );

          // An expense is relevant ONLY if:
          // 1. Both users were part of the split details
          // 2. One of them (current user OR other user) was the payer
          // 3. At least one of their shares is still unpaid
          // This ensures we don't show expenses paid by a third party
          return currentUserShare != null &&
              otherUserShare != null &&
              (expense.payerId == currentUserId || expense.payerId == otherUserId) &&
              (!currentUserShare.paid || !otherUserShare.paid);
        }).toList();

        relevantExpenses.sort(
            (Expense a, Expense b) => b.date.compareTo(a.date)); // Most recent first

        return Scaffold(
          appBar: AppBar(
            title: Text('Splits with ${otherUser.username}'),
          ),
          body: relevantExpenses.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No outstanding splits with ${otherUser.username}.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: relevantExpenses.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Expense expense = relevantExpenses[index];
                    return SplitDetailItem(
                      expense: expense,
                      currentUserId: currentUserId,
                      otherUserId: otherUserId,
                    );
                  },
                ),
        );
      },
    );
  }
}

class SplitDetailItem extends StatelessWidget {
  final Expense expense;
  final String currentUserId;
  final String otherUserId;

  const SplitDetailItem({
    super.key,
    required this.expense,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context) {
    final ExpenseManager expenseManager =
        Provider.of<ExpenseManager>(context, listen: false);
    final AppUser? otherUser = expenseManager.allUsers.firstWhereOrNull(
      (AppUser user) => user.id == otherUserId,
    );
    // The current user must exist, guaranteed by AuthWrapper
    // final AppUser? currentUser = expenseManager.allUsers.firstWhereOrNull(
    //   (AppUser user) => user.id == currentUserId,
    // );

    // Ensure both users are found and their shares exist for this expense.
    // This is already guaranteed by the relevantExpenses filter in SplitDetailScreen.
    final SplitShare currentUserShare = expense.splitDetails.firstWhere(
      (SplitShare split) => split.userId == currentUserId,
    );
    final SplitShare otherUserShare = expense.splitDetails.firstWhere(
      (SplitShare split) => split.userId == otherUserId,
    );

    String actionText = '';
    String amountText = '';
    Color amountColor = Theme.of(context).colorScheme.onSurface;
    bool showMarkAsPaid = false;
    String? markPaidForUserId;

    // Determine the relationship for this specific expense
    // Case 1: Current user paid the expense
    if (expense.payerId == currentUserId) {
      if (!otherUserShare.paid) {
        // Other user owes current user
        actionText = '${otherUser?.username ?? 'Unknown'} owes you';
        amountText = ResponsiveUtils.formatAmountWithK(otherUserShare.amount);
        amountColor = Colors.green.shade700; // Professional green
        showMarkAsPaid = true;
        markPaidForUserId =
            otherUserId; // Mark other user's share as paid TO CURRENT_USER
      } else {
        // Other user has already paid their share to current user. Not outstanding for this specific split.
        return const SizedBox.shrink();
      }
    }
    // Case 2: Other user paid the expense
    else if (expense.payerId == otherUserId) {
      if (!currentUserShare.paid) {
        // Current user owes other user
        actionText = 'You owe ${otherUser?.username ?? 'Unknown'}';
        amountText = ResponsiveUtils.formatAmountWithK(currentUserShare.amount);
        amountColor = Theme.of(context)
            .colorScheme
            .error; // Professional red (theme-aware)
        showMarkAsPaid = true;
        markPaidForUserId =
            currentUserId; // Mark current user's share as paid TO OTHER_USER
      } else {
        // Current user has already paid their share to other user. Not outstanding for this specific split.
        return const SizedBox.shrink();
      }
    }
    // If neither current user nor other user paid (third party paid), this shouldn't appear here
    else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Expense Title and Category
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    expense.category.icon,
                    color: _getCategoryColor(expense.category),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${expense.category.displayName} • ${DateFormat('MMM d, yyyy').format(expense.date)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Total and Paid By Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expense.amount >= 10000
                            ? ResponsiveUtils.formatAmountWithK(expense.amount)
                            : '₹${expense.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Paid by',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expense.payerId == currentUserId 
                            ? 'You' 
                            : (expenseManager.allUsers.firstWhereOrNull((AppUser u) => u.id == expense.payerId)?.username ?? 'Unknown'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Your Share / Amount Owed
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: amountColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    actionText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    amountText,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ),
            
            if (showMarkAsPaid) ...<Widget>[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    expenseManager.markSplitShareAsPaid(expense.id, markPaidForUserId!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment marked as settled!'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    'Mark as Paid',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFF4CAF50);
      case ExpenseCategory.transportation:
        return const Color(0xFF2196F3);
      case ExpenseCategory.housing:
        return const Color(0xFF9C27B0);
      case ExpenseCategory.entertainment:
        return const Color(0xFFFF5722);
      case ExpenseCategory.utilities:
        return const Color(0xFF607D8B);
      case ExpenseCategory.groceries:
        return const Color(0xFF4CAF50);
      case ExpenseCategory.shopping:
        return const Color(0xFFFF9800);
      case ExpenseCategory.health:
        return const Color(0xFFE91E63);
      case ExpenseCategory.education:
        return const Color(0xFF00BCD4);
      case ExpenseCategory.travel:
        return const Color(0xFF795548);
      case ExpenseCategory.other:
        return const Color(0xFF795548);
    }
  }
}

// NEW: OverallSplitLedgerScreen
class OverallSplitLedgerScreen extends StatelessWidget {
  final bool isOwedToMe; // true for "You are owed", false for "You owe"

  const OverallSplitLedgerScreen({
    super.key,
    required this.isOwedToMe,
  });

  @override
  Widget build(BuildContext context) {
    final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
    final String currentUserId = authManager.currentUser?.id ?? 'unknown_user';

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwedToMe ? 'Details: You Are Owed' : 'Details: You Owe'),
      ),
      body: Consumer<ExpenseManager>(
        builder: (BuildContext context, ExpenseManager expenseManager, Widget? child) {
          List<Expense> filteredExpenses = <Expense>[];

          if (isOwedToMe) {
            // Expenses where current user paid and others owe them
            filteredExpenses = expenseManager.expenses.where((Expense expense) {
              if (expense.payerId == currentUserId) {
                // Check if any split share is outstanding (not paid by others to current user)
                return expense.splitDetails.any(
                    (SplitShare split) => split.userId != currentUserId && !split.paid);
              }
              return false;
            }).toList();
          } else {
            // Expenses where current user owes others
            filteredExpenses = expenseManager.expenses.where((Expense expense) {
              if (expense.payerId != currentUserId) {
                // Check if current user has an unpaid share for this expense
                final SplitShare? currentUserShare = expense.splitDetails.firstWhereOrNull(
                    (SplitShare split) => split.userId == currentUserId);
                return currentUserShare != null && !currentUserShare.paid;
              }
              return false;
            }).toList();
          }

          filteredExpenses.sort((Expense a, Expense b) => b.date.compareTo(a.date));

          if (filteredExpenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  isOwedToMe
                      ? 'No outstanding amounts owed to you.'
                      : 'No outstanding amounts you owe.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredExpenses.length,
            itemBuilder: (BuildContext context, int index) {
              final Expense expense = filteredExpenses[index];
              return _OverallLedgerItem(
                expense: expense,
                currentUserId: currentUserId,
                isOwedToMe: isOwedToMe,
              );
            },
          );
        },
      ),
    );
  }
}

// NEW: Helper widget for individual items in OverallSplitLedgerScreen
class _OverallLedgerItem extends StatelessWidget {
  final Expense expense;
  final String currentUserId;
  final bool isOwedToMe;

  const _OverallLedgerItem({
    required this.expense,
    required this.currentUserId,
    required this.isOwedToMe,
  });

  @override
  Widget build(BuildContext context) {
    final ExpenseManager expenseManager =
        Provider.of<ExpenseManager>(context, listen: false);

    String subText = '';
    double relevantAmount = 0.0;
    Color amountColor = Theme.of(context).colorScheme.onSurface;
    bool showMarkAsPaidButton = false;
    List<String> userIdsToMarkAsPaid =
        <String>[]; // List of user IDs whose shares will be marked paid by button

    if (isOwedToMe) {
      // Current user is the payer and is owed money by others for this expense.
      if (expense.payerId != currentUserId) {
        return const SizedBox.shrink(); // This expense is not where I am owed from others paying me.
      }

      final List<SplitShare> sharesOwedToMe = expense.splitDetails
          .where((SplitShare split) => split.userId != currentUserId && !split.paid)
          .toList();

      if (sharesOwedToMe.isEmpty) {
        return const SizedBox.shrink(); // No outstanding shares owed to me for this expense.
      }

      relevantAmount =
          sharesOwedToMe.fold(0.0, (double sum, SplitShare split) => sum + split.amount);
      userIdsToMarkAsPaid.addAll(sharesOwedToMe.map<String>((SplitShare s) => s.userId));

      final List<AppUser> owingUsers = sharesOwedToMe
          .map<AppUser>((SplitShare split) => expenseManager.allUsers.firstWhereOrNull((AppUser u) => u.id == split.userId)!)
          .where((AppUser? u) => u != null)
          .cast<AppUser>()
          .toList();

      subText = 'from ${owingUsers.map<String>((AppUser u) => u.username).join(', ')}';
      amountColor = Colors.green.shade700;
      showMarkAsPaidButton = true;
    } else {
      // Current user owes money to someone for this expense.
      final SplitShare? currentUserShare = expense.splitDetails.firstWhereOrNull(
          (SplitShare split) => split.userId == currentUserId && !split.paid);

      if (currentUserShare == null) {
        return const SizedBox.shrink(); // Current user's share is already paid or not found.
      }

      final AppUser? payerUser = expenseManager.allUsers
          .firstWhereOrNull((AppUser u) => u.id == expense.payerId);

      relevantAmount = currentUserShare.amount;
      userIdsToMarkAsPaid.add(currentUserId);

      subText = 'to ${payerUser?.username ?? 'Unknown'}';
      amountColor = Theme.of(context).colorScheme.error;
      showMarkAsPaidButton = true;
    }

    // Get payer user for display
    final AppUser? payerUser = expenseManager.allUsers
        .firstWhereOrNull((AppUser u) => u.id == expense.payerId);
    final String payerName = payerUser?.username ?? 'Unknown';

    // Format the amount text using K format
    final String formattedAmount = ResponsiveUtils.formatAmountWithK(relevantAmount);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header with icon and title
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    expense.category.icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        expense.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${expense.category.displayName} • ${DateFormat('MMM d, yyyy').format(expense.date)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Total and Paid by section
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ResponsiveUtils.formatAmountWithK(expense.amount),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        'Paid by',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expense.payerId == currentUserId ? 'You' : payerName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Amount owed section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: amountColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          isOwedToMe ? 'You are owed' : 'You owe $payerName',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (isOwedToMe) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            subText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    formattedAmount,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ),
            if (showMarkAsPaidButton) ...<Widget>[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    for (final String userId in userIdsToMarkAsPaid) {
                      expenseManager.markSplitShareAsPaid(expense.id, userId);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(isOwedToMe
                              ? 'All pending shares received for this expense!'
                              : 'Your share for this expense marked as paid!')),
                    );
                  },
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: Text(
                    'Mark as Paid',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Profile Screen (now SettingsPage) ---

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthManager authManager = Provider.of<AuthManager>(context);
    final AppConfig appConfig = Provider.of<AppConfig>(context); // Access AppConfig for theme toggle

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  // MODIFIED: CircleAvatar to display profile picture from AuthManager
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      ProfileUtils.getInitials(authManager.currentUser?.name ?? ''),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    authManager.currentUser?.username ?? 'Guest User',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    authManager.currentUser?.email ?? 'guest@example.com',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // --- Account Section ---
            Text(
              'Account',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              leading: Icon(Icons.person_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              title: Text('My Profile',
                style: GoogleFonts.inter(fontSize: 13)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<Widget>(
                    builder: (BuildContext context) => const MyInfoScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              leading: Icon(Icons.people_alt_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              title: Text('Friends',
                style: GoogleFonts.inter(fontSize: 13)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<Widget>(
                    builder: (BuildContext context) => const FriendsListScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              leading: Icon(Icons.lock_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              title: Text('Change Password',
                style: GoogleFonts.inter(fontSize: 13)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<Widget>(
                    builder: (BuildContext context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            const SizedBox(height: 14),
            // --- App Preferences Section (merged from old SettingsScreen) ---
            Text(
              'App Preferences', // Changed section title
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    appConfig.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  'Theme Mode',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  appConfig.themeMode == ThemeMode.dark ? 'Dark theme enabled' : 'Light theme enabled',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Switch(
                  value: appConfig.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    appConfig.toggleTheme();
                  },
                  thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return const Icon(Icons.dark_mode, size: 16);
                      }
                      return const Icon(Icons.light_mode, size: 16);
                    },
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              leading: Icon(Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              title: Text('About App',
                style: GoogleFonts.inter(fontSize: 13)),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'SplitMaster',
                  applicationVersion: '1.0.0',
                  applicationIcon: Icon(Icons.account_balance_wallet,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary),
                  children: <Widget>[
                    const Text(
                        'SplitMaster helps you efficiently track your daily expenses and manage shared bills.'),
                  ],
                );
              },
            ),
            const Divider(height: 1),
            const SizedBox(height: 18),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    authManager.logout();
                  },
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Text('Logout', style: TextStyle(fontSize: 14)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- My Info Screen ---
class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController; // New controller for username
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _dobController;
  late DateTime _selectedDob;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
    _nameController = TextEditingController(text: authManager.currentUser?.name ?? '');
    _usernameController =
        TextEditingController(text: authManager.currentUser?.username ?? ''); // Initialize username
    _emailController =
        TextEditingController(text: authManager.currentUser?.email ?? '');
    _phoneController =
        TextEditingController(text: authManager.currentUser?.phoneNumber ?? '');
    _countryController = TextEditingController(text: authManager.currentUser?.country ?? '');
    _selectedDob = authManager.currentUser?.dob ?? DateTime.now();
    _dobController =
        TextEditingController(text: DateFormat.yMMMd().format(_selectedDob));
    _selectedGender = authManager.currentUser?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose(); // Dispose username controller
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat.yMMMd().format(_selectedDob);
      });
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
    authManager.updateUserProfile(
      name:
          _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      username:
          _usernameController.text.trim(), // Username is required and validated to be non-empty
      phoneNumber:
          _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      dob: _selectedDob,
      country:
          _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
      gender: _selectedGender,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
    Navigator.pop(context);
  }

  Future<void> _showCountryPicker() async {
    final String? selectedCountry = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // Allow it to take more height
      builder: (BuildContext context) {
        return const CountrySearchBottomSheet();
      },
    );

    if (selectedCountry != null) {
      setState(() {
        _countryController.text = selectedCountry;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF8FAFC),
                      Color(0xFFE0E7FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4F46E5).withOpacity(0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.08),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF4F46E5).withOpacity(0.15),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                        child: Text(
                          ProfileUtils.getInitials(_nameController.text),
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Profile Information',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update your personal details below',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.person_outline),
              const SizedBox(height: 16),
              _buildFormCard([
                _buildModernTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.alternate_email_outlined,
                  keyboardType: TextInputType.text,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: _buildModernTextField(
                      controller: _dobController,
                      label: 'Date of Birth',
                      icon: Icons.calendar_today_outlined,
                      suffixIcon: Icons.arrow_drop_down,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildModernDropdown(),
              ]),
              
              const SizedBox(height: 24),
              
              // Contact Information Section  
              _buildSectionHeader('Contact Information', Icons.contact_mail_outlined),
              const SizedBox(height: 16),
              _buildFormCard([
                _buildModernTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ]),
              
              const SizedBox(height: 24),
              
              // Additional Details Section
              _buildSectionHeader('Additional Details', Icons.info_outline),
              const SizedBox(height: 16),
              _buildFormCard([
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: AbsorbPointer(
                    child: _buildModernTextField(
                      controller: _countryController,
                      label: 'Country',
                      icon: Icons.public_outlined,
                      suffixIcon: Icons.arrow_drop_down,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Profile',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4F46E5),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: readOnly ? const Color(0xFF6B7280) : const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF6B7280),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4F46E5),
          size: 20,
        ),
        suffixIcon: suffixIcon != null
            ? Icon(
                suffixIcon,
                color: const Color(0xFF6B7280),
                size: 20,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4F46E5),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildModernDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
          prefixIcon: const Icon(
            Icons.wc_outlined,
            color: Color(0xFF4F46E5),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dropdownColor: Colors.white,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: Color(0xFF6B7280),
        ),
        items: ['Male', 'Female'].map<DropdownMenuItem<String>>((String gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Row(
              children: <Widget>[
                Icon(
                  gender == 'Male' ? Icons.male : Icons.female,
                  color: const Color(0xFF4F46E5),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  gender,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue;
          });
        },
        isExpanded: true,
      ),
    );
  }


}

// NEW: Friends List Screen
class FriendsListScreen extends StatelessWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
    final String? currentUserId = authManager.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: Consumer<ExpenseManager>(
        builder: (BuildContext context, ExpenseManager expenseManager, Widget? child) {
          final List<AppUser> friends = expenseManager.allUsers
              .where((AppUser user) => user.id != currentUserId) // Exclude current user
              .toList();

          if (friends.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No friends added yet. Tap the "+" button to add your first friend!',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: friends.length,
            itemBuilder: (BuildContext context, int index) {
              final AppUser friend = friends[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Dismissible(
                  key: Key(friend.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (DismissDirection direction) {
                    expenseManager.deleteAppUser(friend.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${friend.username} deleted')),
                    );
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      child: Text(
                        ProfileUtils.getInitials(friend.name),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    title: Text(friend.name),
                    subtitle: Text(friend.email),
                    // Optionally, add onTap to view friend's profile/splits
                    onTap: () {
                      if (currentUserId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute<Widget>(
                            builder: (BuildContext context) => SplitDetailScreen(
                              currentUserId: currentUserId,
                              otherUserId: friend.id,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<Widget>(
              builder: (BuildContext context) => const AddFriendScreen(),
            ),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// NEW: Add Friend Screen (remains mostly the same, but now callable from FriendsListScreen)
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addFriend() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ExpenseManager expenseManager = Provider.of<ExpenseManager>(context, listen: false);

    // Generate a unique ID for the new friend
    final String newFriendId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final String friendName = _nameController.text.trim();
    // Generate a default email if none is provided, as AppUser requires an email
    final String friendEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : '${friendName.toLowerCase().replaceAll(' ', '')}_${newFriendId.substring(newFriendId.length - 4)}@friend.com';

    final AppUser newFriend = AppUser(
      id: newFriendId,
      name: friendName,
      username: friendName, // Using name as username for simplicity
      email: friendEmail,
    );

    expenseManager.addAppUser(newFriend);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${friendName} added as a friend!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Friend'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Friend\'s Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.name,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for your friend.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Friend\'s Email (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                // No validator, as it's optional, but AppUser requires it.
                // The _addFriend method will generate a default if empty.
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addFriend,
                  icon: const Icon(Icons.person_add),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Add Friend',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Country Search Bottom Sheet ---
class CountrySearchBottomSheet extends StatefulWidget {
  const CountrySearchBottomSheet({super.key});

  @override
  State<CountrySearchBottomSheet> createState() => _CountrySearchBottomSheetState();
}

class _CountrySearchBottomSheetState extends State<CountrySearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCountries = CountryData.allCountries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCountries);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries() {
    final String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = CountryData.allCountries
          .where((String country) => country.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Country',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredCountries.length,
                itemBuilder: (BuildContext context, int index) {
                  final String country = _filteredCountries[index];
                  return ListTile(
                    title: Text(country),
                    onTap: () {
                      Navigator.pop(context, country);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- Country Data Helper Class ---
class CountryData {
  static const List<String> allCountries = <String>[
    "Afghanistan", "Albania", "Algeria", "Andorra", "Angola", "Antigua and Barbuda", "Argentina",
    "Armenia", "Australia", "Austria", "Azerbaijan", "Bahamas", "Bahrain", "Bangladesh", "Barbados",
    "Belarus", "Belgium", "Belize", "Benin", "Bhutan", "Bolivia", "Bosnia and Herzegovina", "Botswana",
    "Brazil", "Brunei", "Bulgaria", "Burkina Faso", "Burundi", "Cabo Verde", "Cambodia", "Cameroon",
    "Canada", "Central African Republic", "Chad", "Chile", "China", "Colombia", "Comoros",
    "Congo (Brazzaville)", "Congo (Kinshasa)", "Costa Rica", "Croatia", "Cuba", "Cyprus", "Czechia",
    "Denmark", "Djibouti", "Dominica", "Dominican Republic", "East Timor (Timor-Leste)", "Ecuador",
    "Egypt", "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Eswatini", "Ethiopia", "Fiji",
    "Finland", "France", "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Greece", "Grenada",
    "Guatemala", "Guinea", "Guinea-Bissau", "Guyana", "Haiti", "Honduras", "Hungary", "Iceland",
    "India", "Indonesia", "Iran", "Iraq", "Ireland", "Israel", "Italy", "Ivory Coast", "Jamaica",
    "Japan", "Jordan", "Kazakhstan", "Kenya", "Kiribati", "Korea, North", "Korea, South", "Kosovo",
    "Kuwait", "Kyrgyzstan", "Laos", "Latvia", "Lebanon", " Lesotho", "Liberia", "Libya", "Liechtenstein",
    "Lithuania", "Luxembourg", "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta",
    "Marshall Islands", "Mauritania", "Mauritius", "Mexico", "Micronesia", "Moldova", "Monaco",
    "Mongolia", "Montenegro", "Morocco", "Mozambique", "Myanmar (Burma)", "Namibia", "Nauru", "Nepal",
    "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "North Macedonia", "Norway", "Oman",
    "Pakistan", "Palau", "Palestine", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines",
    "Poland", "Portugal", "Qatar", "Romania", "Russia", "Rwanda", "Saint Kitts and Nevis",
    "Saint Lucia", "Saint Vincent and the Grenadines", "Samoa", "San Marino", "Sao Tome and Principe",
    "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore", "Slovakia",
    "Slovenia", "Solomon Islands", "Somalia", "South Africa", "South Sudan", "Spain", "Sri Lanka",
    "Sudan", "Suriname", "Sweden", "Switzerland", "Syria", "Taiwan", "Tajikistan", "Tanzania",
    "Thailand", "Togo", "Tonga", "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan", "Tuvalu",
    "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay",
    "Uzbekistan", "Vanuatu", "Vatican City", "Venezuela", "Vietnam", "Yemen", "Zambia", "Zimbabwe",
  ];
}

// --- Set Limits Screen ---
class SetLimitsScreen extends StatefulWidget {
  const SetLimitsScreen({super.key});

  @override
  State<SetLimitsScreen> createState() => _SetLimitsScreenState();
}

class _SetLimitsScreenState extends State<SetLimitsScreen> {
  TextEditingController _dailyLimitController = TextEditingController();
  TextEditingController _monthlyLimitController = TextEditingController();
  bool _isDailyLimitEnabled = false;
  bool _isMonthlyLimitEnabled = false;

  @override
  void initState() {
    super.initState();
    final ExpenseManager expenseManager = Provider.of<ExpenseManager>(context, listen: false);
    _dailyLimitController.text = expenseManager.dailyLimit?.toStringAsFixed(2) ?? '';
    _monthlyLimitController.text = expenseManager.monthlyLimit?.toStringAsFixed(2) ?? '';
    _isDailyLimitEnabled = expenseManager.isDailyLimitEnabled;
    _isMonthlyLimitEnabled = expenseManager.isMonthlyLimitEnabled;
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    _monthlyLimitController.dispose();
    super.dispose();
  }

  void _saveLimits() {
    final ExpenseManager expenseManager = Provider.of<ExpenseManager>(context, listen: false);

    double? dailyLimitValue = double.tryParse(_dailyLimitController.text);
    double? monthlyLimitValue = double.tryParse(_monthlyLimitController.text);

    // Validate if enabled but empty/invalid amount
    if (_isDailyLimitEnabled && (dailyLimitValue == null || dailyLimitValue <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid daily limit or disable it.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_isMonthlyLimitEnabled && (monthlyLimitValue == null || monthlyLimitValue <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid monthly limit or disable it.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    expenseManager.setDailyLimit(dailyLimitValue, _isDailyLimitEnabled);
    expenseManager.setMonthlyLimit(monthlyLimitValue, _isMonthlyLimitEnabled);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense limits saved successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Limits'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Daily Spending Limit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _dailyLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Daily Limit (₹)', // Re-added (₹)
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee), // Re-added rupee icon
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: _isDailyLimitEnabled, // Enable/disable based on switch
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: _isDailyLimitEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _isDailyLimitEnabled = value;
                      if (!value) {
                        _dailyLimitController.clear(); // Clear value if disabled
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Monthly Spending Limit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _monthlyLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Limit (₹)', // Re-added (₹)
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee), // Re-added rupee icon
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: _isMonthlyLimitEnabled,
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: _isMonthlyLimitEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _isMonthlyLimitEnabled = value;
                      if (!value) {
                        _monthlyLimitController.clear(); // Clear value if disabled
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50, // Added a fixed height to "resize" it consistently
              child: ElevatedButton(
                onPressed: _saveLimits,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero, // Padding is now handled by SizedBox height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
                child: Text(
                  'Save Limits',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Change Password Screen ---

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
    final String currentPassword = _currentPasswordController.text;
    final String newPassword = _newPasswordController.text;

    // Additional validation
    if (currentPassword == newPassword) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('New password must be different from current password'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final String? errorMessage = await authManager.changePassword(currentPassword, newPassword);

    setState(() {
      _isLoading = false;
    });

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  // Enhanced password validation
  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }
    
    if (value.contains(' ')) {
      return 'Password cannot contain spaces';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Update your password to keep your account secure',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Current password field
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  hintText: 'Enter your current password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                obscureText: !_isCurrentPasswordVisible,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Current password is required';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // New password field
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter your new password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                obscureText: !_isNewPasswordVisible,
                validator: _validateNewPassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // Confirm new password field
              TextFormField(
                controller: _confirmNewPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  hintText: 'Re-enter your new password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                obscureText: !_isConfirmPasswordVisible,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              
              // Password requirements
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Requirements:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordRequirement('At least 8 characters long'),
                    _buildPasswordRequirement('One uppercase letter (A-Z)'),
                    _buildPasswordRequirement('One lowercase letter (a-z)'),
                    _buildPasswordRequirement('One number (0-9)'),
                    _buildPasswordRequirement('No spaces allowed'),
                    _buildPasswordRequirement('Different from current password'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Change password button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.security),
                            const SizedBox(width: 8),
                            Text(
                              'Change Password',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirement(String requirement) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            requirement,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// --- All Splits Screen ---
class AllSplitsScreen extends StatelessWidget {
  const AllSplitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Splits',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Consumer<ExpenseManager>(
        builder: (context, expenseManager, child) {
          final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
          final String currentUserId = authManager.currentUser?.id ?? 'unknown_user';
          final Map<String, double> netOwed = expenseManager.getOwedAmounts(currentUserId);
          
          // Get all friends with balances
          final List<AppUser> allFriends = expenseManager.allUsers
              .where((AppUser user) => user.id != currentUserId)
              .where((AppUser user) => (netOwed[user.id] ?? 0.0) != 0.0) // Only show friends with non-zero balances
              .toList();

          // Sort friends by balance amount (descending - highest amounts first)
          allFriends.sort((AppUser a, AppUser b) {
            final double balanceA = (netOwed[a.id] ?? 0.0).abs();
            final double balanceB = (netOwed[b.id] ?? 0.0).abs();
            return balanceB.compareTo(balanceA);
          });

          if (allFriends.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.balance_outlined,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Settled!',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You have no outstanding balances with your friends.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD), // Very light blue background
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Split Summary',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A8A), // Dark blue for better contrast
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              context,
                              'You Owe',
                              netOwed.values
                                  .where((amount) => amount < 0)
                                  .fold(0.0, (sum, amount) => sum + amount.abs()),
                              const Color(0xFFFF6B6B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryItem(
                              context,
                              'You Are Owed',
                              netOwed.values
                                  .where((amount) => amount > 0)
                                  .fold(0.0, (sum, amount) => sum + amount),
                              const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Friends List Section
                Text(
                  'Outstanding Balances',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allFriends.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final AppUser friend = allFriends[index];
                    final double balance = netOwed[friend.id] ?? 0.0;
                    final bool youOwe = balance < 0;
                    final double absBalance = balance.abs();

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<Widget>(
                                builder: (context) => SplitDetailScreen(
                                  currentUserId: currentUserId,
                                  otherUserId: friend.id,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Friend Avatar
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    ProfileUtils.getInitials(friend.name),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Friend Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friend.username,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            youOwe ? Icons.arrow_upward : Icons.arrow_downward,
                                            size: 14,
                                            color: youOwe ? const Color(0xFFFF6B6B) : const Color(0xFF10B981),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            youOwe ? 'You owe' : 'Owes you',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Amount and Arrow
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      ResponsiveUtils.formatAmountWithK(absBalance),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: youOwe ? const Color(0xFFFF6B6B) : const Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ResponsiveUtils.formatAmountWithK(amount),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}