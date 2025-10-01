import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Import main.dart to access existing classes
import 'professional_settings_screen.dart';

// --- Profile Screen ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _getInitials(String name) {
    if (name.isEmpty) return 'G';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer2<AuthManager, ExpenseManager>(
        builder: (context, authManager, expenseManager, child) {
          final user = authManager.currentUser;

          return SafeArea(
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getResponsiveScreenPadding(context),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, small: 20, normal: 28)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              const Color(0xFF4F46E5), // Professional indigo
                              const Color(0xFF7C3AED), // Professional purple
                            ]
                          : [
                              const Color(0xFFF8FAFC), // Very light slate
                              const Color(0xFFE0E7FF), // Light indigo
                            ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    borderRadius: BorderRadius.circular(24),
                    border: Theme.of(context).brightness == Brightness.light
                        ? Border.all(
                            color: const Color(0xFF4F46E5).withOpacity(0.12),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4F46E5).withOpacity(0.25)
                            : const Color(0xFF4F46E5).withOpacity(0.08),
                        offset: const Offset(0, 12),
                        blurRadius: 32,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, small: 4, normal: 6)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.15)
                              : const Color(0xFF4F46E5).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.2)
                                : const Color(0xFF4F46E5).withOpacity(0.12),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black.withOpacity(0.2)
                                  : const Color(0xFF4F46E5).withOpacity(0.08),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: ResponsiveUtils.isSmallScreen(context) ? 24 : 30,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFF4F46E5).withOpacity(0.08),
                          child: Text(
                            _getInitials(user?.name ?? user?.username ?? 'G'),
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        user?.username ?? 'Guest User',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFF4F46E5).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.15)
                                : const Color(0xFF4F46E5).withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          user?.email ?? 'guest@example.com',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.9)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                // Financial Management Options
                _buildProfileOption(
                  context,
                  'Set Spending Limits',
                  'Manage your budget and spending limits',
                  Icons.trending_up_rounded,
                  () {
                    _showLimitsSettings(context);
                  },
                ),
                
                const SizedBox(height: 12),
                
                _buildProfileOption(
                  context,
                  'Settings',
                  'App preferences and configuration',
                  Icons.settings_rounded,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<Widget>(
                        builder: (context) => const ProfessionalSettingsPage(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                
                _buildProfileOption(
                  context,
                  'Sign Out',
                  'Sign out of your account',
                  Icons.logout_rounded,
                  () {
                    _showSignOutDialog(context, authManager);
                  },
                  isDestructive: true,
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, String title, String subtitle, 
      IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDestructive 
              ? const Color(0xFFFF6B6B).withOpacity(0.15)
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive 
                        ? const Color(0xFFFF6B6B).withOpacity(0.12)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive 
                        ? const Color(0xFFFF6B6B)
                        : Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive 
                              ? const Color(0xFFFF6B6B)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthManager authManager) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Sign Out',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out of your account?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                authManager.logout();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B6B),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  void _showLimitsSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _LimitsModalBottomSheet();
      },
    );
  }
}

class _LimitsModalBottomSheet extends StatefulWidget {
  @override
  _LimitsModalBottomSheetState createState() => _LimitsModalBottomSheetState();
}

class _LimitsModalBottomSheetState extends State<_LimitsModalBottomSheet> {
  bool _dailyLimitEnabled = false;
  bool _monthlyLimitEnabled = false;
  final _dailyLimitController = TextEditingController();
  final _monthlyLimitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load saved limits from ExpenseManager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseManager = Provider.of<ExpenseManager>(context, listen: false);
      
      setState(() {
        _dailyLimitEnabled = expenseManager.isDailyLimitEnabled;
        _monthlyLimitEnabled = expenseManager.isMonthlyLimitEnabled;
        
        if (expenseManager.dailyLimit != null) {
          _dailyLimitController.text = expenseManager.dailyLimit!.toStringAsFixed(0);
        }
        
        if (expenseManager.monthlyLimit != null) {
          _monthlyLimitController.text = expenseManager.monthlyLimit!.toStringAsFixed(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    _monthlyLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Spending Limits',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Daily Limit Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.today_rounded,
                                      color: const Color(0xFF4F46E5),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Daily Limit',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Set maximum daily spending limit',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _dailyLimitEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _dailyLimitEnabled = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_dailyLimitEnabled) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _dailyLimitController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Daily Limit Amount (₹)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.currency_rupee),
                                  ),
                                  onChanged: (value) {
                                    // Value is handled by the controller
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Monthly Limit Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.calendar_month_rounded,
                                      color: const Color(0xFF10B981),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Monthly Limit',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Set maximum monthly spending limit',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _monthlyLimitEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _monthlyLimitEnabled = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_monthlyLimitEnabled) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _monthlyLimitController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Monthly Limit Amount (₹)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.currency_rupee),
                                  ),
                                  onChanged: (value) {
                                    // Value is handled by the controller
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Save Button
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final expenseManager = Provider.of<ExpenseManager>(context, listen: false);
                              
                              // Validate if at least one limit is enabled
                              if (!_dailyLimitEnabled && !_monthlyLimitEnabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Please enable at least one limit to save'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              
                              // Validate input values
                              if (_dailyLimitEnabled && _dailyLimitController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Please enter daily limit amount'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              
                              if (_monthlyLimitEnabled && _monthlyLimitController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Please enter monthly limit amount'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              // Parse and save limits
                              double? dailyLimit;
                              double? monthlyLimit;
                              
                              if (_dailyLimitEnabled) {
                                dailyLimit = double.tryParse(_dailyLimitController.text);
                                if (dailyLimit == null || dailyLimit <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Please enter a valid daily limit'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                              }
                              
                              if (_monthlyLimitEnabled) {
                                monthlyLimit = double.tryParse(_monthlyLimitController.text);
                                if (monthlyLimit == null || monthlyLimit <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Please enter a valid monthly limit'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                              }

                              // Save to ExpenseManager
                              expenseManager.setDailyLimit(dailyLimit, _dailyLimitEnabled);
                              expenseManager.setMonthlyLimit(monthlyLimit, _monthlyLimitEnabled);

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Spending limits updated successfully!'),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Save Limits',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
  }
}