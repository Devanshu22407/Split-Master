import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'all_expenses_screen.dart';
import 'profile_screen.dart';
import 'professional_settings_screen.dart';

// --- Data Models ---

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
  final String? profileImageUrl;
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
    this.profileImageUrl,
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
    String? profileImageUrl,
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
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
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
    // Simulate initial login status (e.g., from stored token)
    _isAuthenticated = false; // Start unauthenticated
  }

  void login(String email, String password) {
    // Input validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    
    // Email format validation
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(email.trim())) {
      throw Exception('Please enter a valid email address');
    }
    
    // Simulate authentication logic
    if (email.trim() == 'user@example.com' && password == _dummyPassword) {
      _isAuthenticated = true;
      _currentUser = AppUser(
        id: 'user_1',
        name: 'John Doe',
        username: 'johndoe',
        email: email.trim(),
        dob: null,
        country: null,
        gender: null,
        phoneNumber: null,
        profileImageUrl:
            'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
      );
      notifyListeners();
    } else {
      throw Exception('Invalid email or password');
    }
  }

  void signup(String name, String email, String password) {
    // Input validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }
    
    // Name validation
    if (name.trim().length < 2) {
      throw Exception('Name must be at least 2 characters long');
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name.trim())) {
      throw Exception('Name can only contain letters and spaces');
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
    
    // Simulate signup logic
    _isAuthenticated = true;
    _currentUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      username: name.trim().toLowerCase().replaceAll(' ', ''),
      email: email.trim(),
      dob: null,
      country: null,
      gender: null,
      phoneNumber: null,
      profileImageUrl:
          'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
    );
    _dummyPassword = password; // Set the new password
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    _dummyPassword = 'password'; // Reset dummy password on logout, or keep it.
    notifyListeners();
  }

  String? changePassword(String currentPassword, String newPassword) {
    if (_currentUser == null) {
      return 'No user logged in to change password.';
    }
    
    // Validate current password
    if (currentPassword.isEmpty) {
      return 'Current password is required.';
    }
    
    if (currentPassword != _dummyPassword) {
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
    _dummyPassword = newPassword;
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
    String? profileImageUrl,
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
      profileImageUrl: profileImageUrl,
    );
    notifyListeners();
  }
}

class AppConfig extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default to light theme for professional look

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class ExpenseManager extends ChangeNotifier {
  final List<Expense> _expenses = <Expense>[];
  final List<AppUser> _allUsers = <AppUser>[
    AppUser(
        id: 'user_1',
        name: 'John Doe',
        email: 'john@example.com',
        username: 'johndoe',
        profileImageUrl:
            'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg'),
    AppUser(
        id: 'user_2',
        name: 'Jane Smith',
        email: 'jane@example.com',
        username: 'janesmith',
        profileImageUrl:
            'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg'),
    AppUser(
        id: 'user_3',
        name: 'Bob Johnson',
        email: 'bob@example.com',
        username: 'bobjohnson',
        profileImageUrl:
            'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg'),
  ];

  double? _dailyLimit;
  double? _monthlyLimit;
  bool _isDailyLimitEnabled = false;
  bool _isMonthlyLimitEnabled = false;

  List<Expense> get expenses => List<Expense>.unmodifiable(_expenses);
  List<AppUser> get allUsers => List<AppUser>.unmodifiable(_allUsers);

  double? get dailyLimit => _dailyLimit;
  double? get monthlyLimit => _monthlyLimit;
  bool get isDailyLimitEnabled => _isDailyLimitEnabled;
  bool get isMonthlyLimitEnabled => _isMonthlyLimitEnabled;

  ExpenseManager() {
    // Initialize with dummy data
    _expenses.addAll(<Expense>[
      Expense(
        id: 'e1',
        title: 'Groceries',
        amount: 55.75,
        category: ExpenseCategory.groceries,
        date: DateTime.now().subtract(const Duration(days: 2)),
        payerId: 'user_1',
      ),
      Expense(
        id: 'e2',
        title: 'Dinner with friends',
        amount: 120.00,
        category: ExpenseCategory.food,
        date: DateTime.now().subtract(const Duration(days: 5)),
        payerId: 'user_2', // Jane paid
        splitDetails: <SplitShare>[
          SplitShare(userId: 'user_1', amount: 40.0, paid: false), // John owes Jane
          SplitShare(
              userId: 'user_2', amount: 40.0, paid: true), // Jane (payer) has paid her share
          SplitShare(userId: 'user_3', amount: 40.0, paid: false), // Bob owes Jane
        ],
      ),
      Expense(
        id: 'e3',
        title: 'Bus Ticket',
        amount: 2.50,
        category: ExpenseCategory.transportation,
        date: DateTime.now().subtract(const Duration(days: 1)),
        payerId: 'user_1',
      ),
      Expense(
        id: 'e4',
        title: 'Movie Tickets',
        amount: 30.00,
        category: ExpenseCategory.entertainment,
        date: DateTime.now().subtract(const Duration(days: 3)),
        payerId: 'user_3', // Bob paid
        splitDetails: <SplitShare>[
          SplitShare(userId: 'user_1', amount: 15.0, paid: false), // John owes Bob
          SplitShare(
              userId: 'user_3', amount: 15.0, paid: true), // Bob (payer) has paid his share
        ],
      ),
      Expense(
        id: 'e5',
        title: 'Electricity Bill',
        amount: 80.00,
        category: ExpenseCategory.utilities,
        date: DateTime.now().subtract(const Duration(days: 10)),
        payerId: 'user_1',
      ),
      Expense(
        id: 'e6',
        title: 'Lunch with Jane',
        amount: 25.00,
        category: ExpenseCategory.food,
        date: DateTime.now().subtract(const Duration(days: 1)),
        payerId: 'user_1', // John paid
        splitDetails: <SplitShare>[
          SplitShare(
              userId: 'user_1', amount: 12.50, paid: true), // John paid his half to himself
          SplitShare(userId: 'user_2', amount: 12.50, paid: false), // Jane owes John
        ],
      ),
      Expense(
        id: 'e7',
        title: 'House Rent',
        amount: 900.00,
        category: ExpenseCategory.housing,
        date: DateTime.now().subtract(const Duration(days: 7)),
        payerId: 'user_3', // Bob paid
        splitDetails: <SplitShare>[
          SplitShare(userId: 'user_1', amount: 300.0, paid: false), // John owes Bob
          SplitShare(userId: 'user_2', amount: 300.0, paid: false), // Jane owes Bob
          SplitShare(
              userId: 'user_3', amount: 300.0, paid: true), // Bob (payer) has paid his share
        ],
      ),
    ]);
    _dailyLimit = null;
    _monthlyLimit = null;
    _isDailyLimitEnabled = false;
    _isMonthlyLimitEnabled = false;
  }

  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  void updateExpense(Expense updatedExpense) {
    final int index =
        _expenses.indexWhere((Expense expense) => expense.id == updatedExpense.id);
    if (index != -1) {
      _expenses[index] = updatedExpense;
      notifyListeners();
    }
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((Expense expense) => expense.id == id);
    notifyListeners();
  }

  // NEW: Method to add a new AppUser (friend)
  void addAppUser(AppUser user) {
    // In a real app, you might want to check for duplicate IDs or emails
    if (!_allUsers.any((AppUser existingUser) => existingUser.id == user.id)) {
      _allUsers.add(user);
      notifyListeners();
    }
  }

  // NEW: Method to delete an AppUser (friend)
  void deleteAppUser(String userId) {
    _allUsers.removeWhere((AppUser user) => user.id == userId);
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

  void markSplitShareAsPaid(String expenseId, String userId) {
    final int expenseIndex =
        _expenses.indexWhere((Expense expense) => expense.id == expenseId);
    if (expenseIndex != -1) {
      final Expense expense = _expenses[expenseIndex];
      final int splitIndex =
          expense.splitDetails.indexWhere((SplitShare split) => split.userId == userId);
      if (splitIndex != -1) {
        expense.splitDetails[splitIndex].paid = true;
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

void main() {
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthManager authManager = Provider.of<AuthManager>(context);

    if (authManager.isAuthenticated) {
      return const MainAppShell();
    } else {
      return const AuthScreen();
    }
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
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _authenticate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final AuthManager authManager = Provider.of<AuthManager>(context, listen: false);
    
    try {
      if (_isLogin) {
        authManager.login(_emailController.text.trim(), _passwordController.text);
      } else {
        authManager.signup(
            _nameController.text.trim(), 
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 60,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to SplitMaster',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Sign in to your account' : 'Create your account',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
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
                    ),
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
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
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
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
                  const SizedBox(height: 16),
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
                    ),
                    obscureText: !_isConfirmPasswordVisible,
                    validator: _validateConfirmPassword,
                    textInputAction: TextInputAction.done,
                  ),
                ],
                
                // Password requirements for signup
                if (!_isLogin) ...<Widget>[
                  const SizedBox(height: 16),
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
                        _buildPasswordRequirement('At least 8 characters'),
                        _buildPasswordRequirement('One uppercase letter (A-Z)'),
                        _buildPasswordRequirement('One lowercase letter (a-z)'),
                        _buildPasswordRequirement('One number (0-9)'),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Login/Signup button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _authenticate,
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
                              Icon(_isLogin ? Icons.login : Icons.app_registration),
                              const SizedBox(width: 8),
                              Text(
                                _isLogin ? 'Login' : 'Sign Up',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Toggle between login and signup
                TextButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isLogin = !_isLogin;
                      // Clear form when switching
                      _emailController.clear();
                      _passwordController.clear();
                      _nameController.clear();
                      _confirmPasswordController.clear();
                      _formKey.currentState?.reset();
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      text: _isLogin
                          ? 'Don\'t have an account? '
                          : 'Already have an account? ',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: _isLogin ? 'Sign Up' : 'Login',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.primary,
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

// --- Main App Shell (with Bottom Navigation) ---

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
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
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
          const InsightsScreen(), // NEW: Insights screen
          AddExpenseScreen(onSaveAndNavigateBack: () {
            _pageController.jumpToPage(0); // Go to Home tab
            setState(() {
              _selectedIndex = 0; // Update bottom nav bar
            });
          }),
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
            icon: Icon(Icons.analytics_outlined), // NEW: Icon for Insights
            selectedIcon: Icon(Icons.analytics), // NEW: Icon for Insights
            label: 'Insights', // NEW: Label for Insights
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Professional Welcome Header
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              const Color(0xFF4F46E5), // Professional indigo
                              const Color(0xFF7C3AED), // Professional purple
                            ]
                          : [
                              const Color(0xFFE0E7FF), // Very light indigo
                              const Color(0xFFF3F4F6), // Light gray
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Theme.of(context).brightness == Brightness.light
                        ? Border.all(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4F46E5).withOpacity(0.2)
                            : const Color(0xFF4F46E5).withOpacity(0.08),
                        offset: const Offset(0, 8),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
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
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<Widget>(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.15)
                                    : const Color(0xFF4F46E5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.2)
                                      : const Color(0xFF4F46E5).withOpacity(0.15),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : const Color(0xFF4F46E5).withOpacity(0.1),
                                child: Text(
                                  (authManager.currentUser?.username ?? 'G').substring(0, 1).toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : const Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back!',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withOpacity(0.9)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    authManager.currentUser?.username ?? 'Guest',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : const Color(0xFF4F46E5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.9)
                                    : const Color(0xFF4F46E5),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OverallSplitSummaryCards(
                    expenseManager: expenseManager, currentUserId: currentUserId),
                const SizedBox(height: 24),
                // NEW: Friends Balances List
                FriendsBalancesList(
                    expenseManager: expenseManager, currentUserId: currentUserId),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Recent Expenses',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
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
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View All'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RecentExpensesList(expenseManager: expenseManager),
              ],
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

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: <Widget>[
        _buildSummaryCard(
          context,
          'You Owe',
          '₹${totalIOwe.toStringAsFixed(2)}',
          Icons.trending_down_rounded,
          const Color(0xFFFF6B6B), // Soft red
          false, // isOwedToMe: false (I owe)
        ),
        _buildSummaryCard(
          context,
          'You Are Owed',
          '₹${totalOwedToMe.toStringAsFixed(2)}',
          Icons.trending_up_rounded,
          const Color(0xFF10B981), // Soft green
          true, // isOwedToMe: true (Others owe me)
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value,
      IconData icon, Color accentColor, bool isOwedToMe) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
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

    // Now showing all friends, regardless of balance
    final List<AppUser> friendsToDisplay = expenseManager.allUsers
        .where((AppUser user) => user.id != currentUserId) // Exclude current user
        .toList();

    // Sort friends for consistent display, e.g., alphabetically by username
    friendsToDisplay.sort((AppUser a, AppUser b) => a.username.compareTo(b.username));

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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.people_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Friends & Balances',
                  style: GoogleFonts.inter(
                    fontSize: 18,
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
                        builder: (BuildContext context) => const FriendsListScreen(),
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
            const SizedBox(height: 16),
            if (friendsToDisplay.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No friends added yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add friends to start splitting expenses together',
                      style: GoogleFonts.inter(
                        fontSize: 14,
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
                  IconData balanceIcon;

                  if (balance == 0.0) {
                    balanceText = 'Settled';
                    balanceColor = Theme.of(context).colorScheme.onSurfaceVariant;
                    balanceIcon = Icons.check_circle_outline;
                  } else {
                    final bool youOwe = balance < 0;
                    final String balancePrefix = youOwe ? 'You owe' : 'Owes you';
                    balanceText =
                        '${balancePrefix} ₹${balance.abs().toStringAsFixed(2)}';
                    balanceColor = youOwe ? 
                        (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFF87171) // Brighter red for dark theme
                            : const Color(0xFFFF6B6B)) : 
                        (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4ADE80) // Brighter green for dark theme
                            : const Color(0xFF00D2FF));
                    balanceIcon = youOwe ? Icons.arrow_upward : Icons.arrow_downward;
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
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
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              backgroundImage: friend.profileImageUrl != null
                                  ? NetworkImage(friend.profileImageUrl!)
                                  : null,
                              child: friend.profileImageUrl == null
                                  ? Text(
                                      friend.username.substring(0, 1).toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend.username,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        balanceIcon,
                                        size: 14,
                                        color: balanceColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        balanceText,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: balanceColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ],
                        ),
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
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Trends'),
      ),
      body: Consumer<ExpenseManager>(
        builder: (BuildContext context, ExpenseManager expenseManager, Widget? child) {
          final AuthManager authManager =
              Provider.of<AuthManager>(context, listen: false);
          final String currentUserId = authManager.currentUser?.id ?? 'unknown_user';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DashboardSummaryCards(
                    expenseManager: expenseManager, currentUserId: currentUserId),
                const SizedBox(height: 24),
                ExpensesByCategoryChart(expenseManager: expenseManager),
                const SizedBox(height: 24),
                MonthlySpendTrendChart(expenseManager: expenseManager),
              ],
            ),
          );
        },
      ),
    );
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
            '₹${todayPersonalSpend.toStringAsFixed(2)}',
            Icons.today,
            valueColor: usedMoneyColor),
        _buildSummaryCard(
            context,
            'This Month',
            '₹${currentMonthPersonalSpend.toStringAsFixed(2)}',
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
                          '₹${entry.value.abs().toStringAsFixed(2)}',
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
                          '₹${totalOwedToMe.toStringAsFixed(2)}',
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
                          '₹${entry.value.abs().toStringAsFixed(2)}',
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
                          '₹${totalIOwe.toStringAsFixed(2)}',
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
                          '₹${rod.toY.toStringAsFixed(2)}',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      expense.category.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              expense.category.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              ' • ',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, yyyy').format(expense.date),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFF87171).withOpacity(0.2) // Lighter background in dark theme
                              : const Color(0xFFFF6B6B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-₹${expense.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFF87171) // Brighter red in dark theme
                                : const Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
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

  void _saveExpense() {
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
      String limitWarningMessage = '';
      if (dailyExceeded) {
        limitWarningMessage += 'Daily limit exceeded! ';
      }
      if (monthlyExceeded) {
        limitWarningMessage += 'Monthly limit exceeded! ';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(limitWarningMessage.trim()),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            textColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      );
    }

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
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add New Expense' : 'Edit Expense'),
        leading: widget.expense != null // Only show back button if editing (pushed)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpenseCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
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
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                    'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              const SizedBox(height: 24),
              // NEW: Bill Splitting Method section
              Text(
                'Bill Splitting Method',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Column(
                children: _SplitOption.values.map<Widget>((_SplitOption option) {
                  String title;
                  switch (option) {
                    case _SplitOption.iPaidEvenly:
                      title = 'I Paid - Split Equally';
                      break;
                    case _SplitOption.iAmOwedFullAmount:
                      title = 'I Paid - I am owed full amount (Paid for others)';
                      break;
                    case _SplitOption.friendPaidEvenly:
                      title = 'A Friend Paid - Split Equally';
                      break;
                    case _SplitOption.friendIsOwedFullAmount:
                      title = 'A Friend Paid - Friend is owed full amount (Paid for others)';
                      break;
                    case _SplitOption.manualSplit:
                      title = 'Manual Split (Split Unequally)';
                      break;
                  }

                  return RadioListTile<_SplitOption>(
                    title: Text(title),
                    value: option,
                    groupValue: _selectedSplitOption,
                    onChanged: (_SplitOption? value) {
                      setState(() {
                        _selectedSplitOption = value;
                        // Clear manual split amounts if switching away
                        if (value != _SplitOption.manualSplit) {
                          _splitAmounts.clear();
                        }

                        // Determine payer based on selected option
                        if (value == _SplitOption.iPaidEvenly || value == _SplitOption.iAmOwedFullAmount || value == _SplitOption.manualSplit && _selectedPayerId == null) {
                          _selectedPayerId = currentUser?.id;
                          _selectedFriendPayerId = null;
                        } else if (value == _SplitOption.friendPaidEvenly || value == _SplitOption.friendIsOwedFullAmount) {
                          _selectedPayerId = _selectedFriendPayerId; // Will be null initially if no friend selected
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              // Validator for _selectedSplitOption
              Builder(
                builder: (BuildContext context) {
                  if (_selectedSplitOption == null) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                      child: Text(
                        'Please select a bill splitting method.',
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),

              // Conditional UI elements based on selected split option
              if (_selectedSplitOption != null) ...<Widget>[
                // "Which friend paid?" dropdown, only for friend-paid scenarios
                if (_selectedSplitOption == _SplitOption.friendPaidEvenly ||
                    _selectedSplitOption == _SplitOption.friendIsOwedFullAmount) ...<Widget>[
                  DropdownButtonFormField<String>(
                    value: _selectedFriendPayerId,
                    decoration: const InputDecoration(
                      labelText: 'Which friend paid?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
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
                        _selectedPayerId = newValue; // Sync with the general payer ID
                      });
                    },
                    validator: (String? value) {
                      if ((_selectedSplitOption == _SplitOption.friendPaidEvenly || _selectedSplitOption == _SplitOption.friendIsOwedFullAmount) && value == null) {
                        return 'Please select a friend who paid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // "Who paid?" dropdown, only for manual split
                if (_selectedSplitOption == _SplitOption.manualSplit) ...<Widget>[
                  DropdownButtonFormField<String>(
                    value: _selectedPayerId,
                    decoration: const InputDecoration(
                      labelText: 'Who paid?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: <DropdownMenuItem<String>>[
                      if (currentUser != null) // Always include current user if logged in
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
                  const SizedBox(height: 16),
                ],

                // The problematic `if` / `else if` block
                if (_selectedSplitOption == _SplitOption.iAmOwedFullAmount || _selectedSplitOption == _SplitOption.friendIsOwedFullAmount)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Who owes (splits full amount):',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Wrap(
                        spacing: 8.0,
                        children: _selectedSplitUsers.map<Widget>((AppUser user) {
                          return Chip(
                            label: Text(user.username),
                            onDeleted: () {
                              setState(() {
                                _selectedSplitUsers.remove(user);
                                _splitAmounts.remove(user.id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.group_add),
                        label: const Text('Add person to owe'),
                        onPressed: () async {
                          final List<AppUser> availableUsers = _getUsersAvailableToAdd(expenseManager, authManager);
                           if (availableUsers.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('No more friends to add or you are already splitting with all.')));
                            return;
                          }
                          final AppUser? selectedUser = await showDialog<AppUser>(
                            context: context,
                            builder: (BuildContext context) {
                              return SimpleDialog(
                                title: const Text('Select a user to owe'),
                                children: availableUsers
                                    .map<SimpleDialogOption>((AppUser user) {
                                  return SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.pop(context, user);
                                    },
                                    child: Text(user.id == currentUser?.id
                                        ? 'Me (${user.username})'
                                        : user.username),
                                  );
                                }).toList(),
                              );
                            },
                          );
                          if (selectedUser != null) {
                            setState(() {
                              _selectedSplitUsers.add(selectedUser);
                              _splitAmounts[selectedUser.id] = 0.0; // Initialize with zero
                            });
                          }
                        },
                      ),
                    ],
                  )
                else // This 'else' correctly covers all other _SplitOption cases where participants split with the payer
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Split with (others):',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Wrap(
                        spacing: 8.0,
                        children: _selectedSplitUsers.map<Widget>((AppUser user) {
                          return Chip(
                            label: Text(user.username),
                            onDeleted: () {
                              setState(() {
                                _selectedSplitUsers.remove(user);
                                _splitAmounts.remove(user.id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.group_add),
                        label: const Text('Add participant'),
                        onPressed: () async {
                          final List<AppUser> availableUsers = _getUsersAvailableToAdd(expenseManager, authManager);
                           if (availableUsers.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('No more friends to add or you are already splitting with all.')));
                            return;
                          }
                          final AppUser? selectedUser = await showDialog<AppUser>(
                            context: context,
                            builder: (BuildContext context) {
                              return SimpleDialog(
                                title: const Text('Select a user to split with'),
                                children: availableUsers
                                    .map<SimpleDialogOption>((AppUser user) {
                                  return SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.pop(context, user);
                                    },
                                    child: Text(user.id == currentUser?.id
                                        ? 'Me (${user.username})'
                                        : user.username),
                                  );
                                }).toList(),
                              );
                            },
                          );
                          if (selectedUser != null) {
                            setState(() {
                              _selectedSplitUsers.add(selectedUser);
                              _splitAmounts[selectedUser.id] = 0.0; // Initialize with zero
                            });
                          }
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Individual Shares (only for manual split)
                if (_selectedSplitOption == _SplitOption.manualSplit) ...<Widget>[
                  Text(
                    'Individual Shares:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ..._buildSplitShareRows(context, expenseManager, authManager),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
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
                      child: const Text('Fill Evenly'), // Helper for manual split
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveExpense,
                  icon: Icon(widget.expense == null ? Icons.add_task : Icons.save),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      widget.expense == null ? 'Add Expense' : 'Update Expense',
                      style: const TextStyle(fontSize: 18),
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
        // AND at least one of their shares is still unpaid.
        final List<Expense> relevantExpenses =
            expenseManager.expenses.where((Expense expense) {
          final SplitShare? currentUserShare = expense.splitDetails.firstWhereOrNull(
            (SplitShare split) => split.userId == currentUserId,
          );
          final SplitShare? otherUserShare = expense.splitDetails.firstWhereOrNull(
            (SplitShare split) => split.userId == otherUserId,
          );

          // An expense is relevant if both users were part of its split details
          // AND at least one of their shares is still unpaid.
          return currentUserShare != null &&
              otherUserShare != null &&
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
        amountText = '₹${otherUserShare.amount.toStringAsFixed(2)}';
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
        amountText = '₹${currentUserShare.amount.toStringAsFixed(2)}';
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
    // Case 3: A third party paid the expense
    else if (expense.payerId != null) {
      final AppUser? payerUser = expenseManager.allUsers
          .firstWhereOrNull((AppUser u) => u.id == expense.payerId);
      if (payerUser == null) {
        return const SizedBox.shrink(); // Payer not found, or invalid payerId
      }

      if (!currentUserShare.paid) {
        // Current user owes the third party
        actionText = 'You owe ${payerUser.username} (for ${expense.title})';
        amountText = '₹${currentUserShare.amount.toStringAsFixed(2)}';
        amountColor = Theme.of(context)
            .colorScheme
            .error; // Professional red (theme-aware)
        showMarkAsPaid = true;
        markPaidForUserId =
            currentUserId; // Mark current user's share as paid TO PAYER
      } else if (!otherUserShare.paid) {
        // Other user owes the third party (displayed for context)
        actionText =
            '${otherUser?.username ?? 'Unknown'} owes ${payerUser.username} (for ${expense.title})';
        amountText = '₹${otherUserShare.amount.toStringAsFixed(2)}';
        amountColor = Theme.of(context)
            .colorScheme
            .onSurfaceVariant; // Neutral color for informational display
        showMarkAsPaid = false; // Current user cannot mark other user's debt to a third party as paid directly
      } else {
        // Both current user's and other user's shares are settled with the third party payer.
        return const SizedBox.shrink();
      }
    } else {
      // Should not be reached if expense.payerId is always set for split expenses
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              expense.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${expense.category.displayName} - ${DateFormat.yMMMd().format(expense.date)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Total: ₹${expense.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Paid by: ${expense.payerId == currentUserId ? 'You' : expenseManager.allUsers.firstWhereOrNull((AppUser u) => u.id == expense.payerId)?.username ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    actionText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  amountText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (showMarkAsPaid && markPaidForUserId != null) ...<Widget>[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    expenseManager.markSplitShareAsPaid(expense.id, markPaidForUserId!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Split for ${otherUser?.username ?? 'Unknown user'} marked as paid!')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Paid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green.shade700, // Professional green for button
                    foregroundColor: Colors.white, // Ensure good contrast
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

    String mainActionText = '';
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

      mainActionText = 'You are owed: ₹${relevantAmount.toStringAsFixed(2)}';
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

      mainActionText = 'You owe: ₹${relevantAmount.toStringAsFixed(2)}';
      subText = 'to ${payerUser?.username ?? 'Unknown'}';
      amountColor = Theme.of(context).colorScheme.error;
      showMarkAsPaidButton = true;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              expense.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${expense.category.displayName} - ${DateFormat.yMMMd().format(expense.date)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Total expense: ₹${expense.amount.toStringAsFixed(2)}', // Clarify "Total"
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Paid by: ${expense.payerId == currentUserId ? 'You' : expenseManager.allUsers.firstWhereOrNull((AppUser u) => u.id == expense.payerId)?.username ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        mainActionText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: amountColor, // Apply color to the main action text
                            ),
                      ),
                      Text(
                        subText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showMarkAsPaidButton) ...<Widget>[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
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
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Paid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  // MODIFIED: CircleAvatar to display profile picture from AuthManager
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: authManager.currentUser?.profileImageUrl != null
                        ? NetworkImage(authManager.currentUser!.profileImageUrl!)
                        : null,
                    child: authManager.currentUser?.profileImageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 70,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authManager.currentUser?.username ?? 'Guest User',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // --- Account Section ---
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<Widget>(
                    builder: (BuildContext context) => const MyInfoScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.people_alt_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              title: const Text('Friends'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<Widget>(
                    builder: (BuildContext context) => const FriendsListScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.lock_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<Widget>(
                    builder: (BuildContext context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            const SizedBox(height: 24),
            // --- App Preferences Section (merged from old SettingsScreen) ---
            Text(
              'App Preferences', // Changed section title
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    appConfig.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Theme Mode',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  appConfig.themeMode == ThemeMode.dark ? 'Dark theme enabled' : 'Light theme enabled',
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
            const Divider(),
            ListTile(
              leading: Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              title: const Text('About App'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'SplitMaster',
                  applicationVersion: '1.0.0',
                  applicationIcon: Icon(Icons.account_balance_wallet,
                      color: Theme.of(context).colorScheme.primary),
                  children: <Widget>[
                    const Text(
                        'SplitMaster helps you efficiently track your daily expenses and manage shared bills.'),
                  ],
                );
              },
            ),
            const Divider(),
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    authManager.logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Logout', style: TextStyle(fontSize: 18)),
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
  String? _profileImageUrl; // NEW: State variable for profile image URL

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
    _profileImageUrl =
        authManager.currentUser?.profileImageUrl; // NEW: Initialize from current user
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
      profileImageUrl: _profileImageUrl, // NEW: Pass the updated image URL
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

  // NEW: Method to handle profile picture upload/removal
  void _uploadProfilePicture() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo (Simulated)'),
              onTap: () {
                setState(() {
                  _profileImageUrl =
                      'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery (Simulated)'),
              onTap: () {
                setState(() {
                  _profileImageUrl =
                      'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg';
                });
                Navigator.pop(context);
              },
            ),
            if (_profileImageUrl != null) // Only show remove option if an image exists
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Photo'),
                onTap: () {
                  setState(() {
                    _profileImageUrl = null;
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight, // Position the camera icon
                  children: <Widget>[
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      // NEW: Display network image if URL is available, otherwise default icon
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? Icon(
                              Icons.person,
                              size: 70,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            )
                          : null,
                    ),
                    // NEW: Camera icon for uploading profile picture
                    GestureDetector(
                      onTap: _uploadProfilePicture, // Call the new method
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.text,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items: <DropdownMenuItem<String>>[
                  ...(['Male', 'Female']).map<DropdownMenuItem<String>>((String gender) {
                    IconData iconData;
                    if (gender == 'Male') {
                      iconData = Icons.male;
                    } else {
                      iconData = Icons.female;
                    }
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Row(
                        children: <Widget>[
                          Icon(iconData),
                          const SizedBox(width: 10),
                          Text(gender),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                isExpanded: true,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showCountryPicker,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    keyboardType: TextInputType.text,
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    foregroundColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text(
                    'Save Profile',
                    style: Theme.of(context).textTheme.titleMedium,
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
                      backgroundImage: friend.profileImageUrl != null
                          ? NetworkImage(friend.profileImageUrl!)
                          : null,
                      child: friend.profileImageUrl == null
                          ? Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            )
                          : null,
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
      profileImageUrl: null, // No profile image for new friends by default
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

  void _changePassword() {
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

    final String? errorMessage = authManager.changePassword(currentPassword, newPassword);

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