import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Import main.dart to access existing classes

// --- Professional Settings Page ---
class ProfessionalSettingsPage extends StatelessWidget {
  const ProfessionalSettingsPage({super.key});

  // Helper method to get initials from name
  String _getInitials(String name) {
    final List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return 'G';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final AuthManager authManager = Provider.of<AuthManager>(context);
    final AppConfig appConfig = Provider.of<AppConfig>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // User Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          const Color(0xFF4F46E5),
                          const Color(0xFF7C3AED),
                        ]
                      : [
                          const Color(0xFFF8FAFC),
                          const Color(0xFFE0E7FF),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Theme.of(context).brightness == Brightness.light
                    ? Border.all(
                        color: const Color(0xFF4F46E5).withOpacity(0.12),
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF4F46E5).withOpacity(0.2)
                        : const Color(0xFF4F46E5).withOpacity(0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.15)
                          : const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFF4F46E5).withOpacity(0.15),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFF4F46E5).withOpacity(0.1),
                      child: Text(
                        _getInitials(authManager.currentUser?.name ?? authManager.currentUser?.username ?? 'G'),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authManager.currentUser?.username ?? 'Guest User',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authManager.currentUser?.email ?? 'guest@example.com',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.8)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Account Section
            _buildSectionHeader(context, 'Account', Icons.person_outline_rounded),
            const SizedBox(height: 16),
            _buildSettingsCard(
              context,
              [
                _buildSettingsTile(
                  context,
                  'My Profile',
                  'Edit your personal information',
                  Icons.person_outline_rounded,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<Widget>(
                        builder: (BuildContext context) => const MyInfoScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  'Friends',
                  'Manage your friends list',
                  Icons.group_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<Widget>(
                        builder: (BuildContext context) => const FriendsListScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  'Change Password',
                  'Update your account password',
                  Icons.lock_outline_rounded,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<Widget>(
                        builder: (BuildContext context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // App Preferences Section
            _buildSectionHeader(context, 'App Preferences', Icons.tune_rounded),
            const SizedBox(height: 16),
            _buildSettingsCard(
              context,
              [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme Mode',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appConfig.themeMode == ThemeMode.dark ? 'Dark mode enabled' : 'Light mode enabled',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
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
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Support Section
            _buildSectionHeader(context, 'Support & Information', Icons.help_outline_rounded),
            const SizedBox(height: 16),
            _buildSettingsCard(
              context,
              [
                _buildSettingsTile(
                  context,
                  'Help & Support',
                  'Get help and contact support',
                  Icons.help_outline_rounded,
                  () {
                    _showHelpDialog(context);
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  'About App',
                  'App version and information',
                  Icons.info_outline_rounded,
                  () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'SplitMaster',
                      applicationVersion: '1.0.0',
                      applicationIcon: Icon(Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.primary),
                      children: <Widget>[
                        const Text(
                            'SplitMaster helps you efficiently track your daily expenses and manage shared bills with friends and family.'),
                      ],
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  'Privacy Policy',
                  'Read our privacy policy',
                  Icons.privacy_tip_outlined,
                  () {
                    _showPrivacyDialog(context);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, String title, String subtitle, 
      IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
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
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey.withOpacity(0.2),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text(
            'For support and assistance:\n\n'
            '• Email: 23aiml066@charusat.edu.in\n'
            '• Email: 23aiml067@charusat.edu.in\n'
            '• Response time: 24-48 hours'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'SplitMaster Privacy Policy\n\n'
              'We respect your privacy and are committed to protecting your personal data. '
              'This privacy policy explains how we collect, use, and protect your information.\n\n'
              '• Data Collection: We only collect necessary data for app functionality\n'
              '• Data Usage: Your data is used solely for providing expense tracking services\n'
              '• Data Security: We implement industry-standard security measures\n'
              '• Data Sharing: We do not share your personal data with third parties'
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
