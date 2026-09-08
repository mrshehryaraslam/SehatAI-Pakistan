import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  AppLanguage _selectedLang = AppLanguage.english;
  bool _smsAlerts = true;

  void _logout() {
    ConfirmationDialog.show(
      context,
      title: 'Sign Out?',
      message: 'Are you sure you want to sign out of SehatAI?',
      confirmText: 'Sign Out',
      isDangerous: true,
      icon: Icons.logout_rounded,
    ).then((confirmed) async {
      if (confirmed == true) {
        await AuthService().logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.primaryContainer,
                      child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.phone.isNotEmpty ? user.phone : user.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${user.city ?? 'Gilgit'} \u2022 Age ${user.age ?? 30}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Emergency Contact Section
              const Text(
                'Emergency Contact & Medical Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Emergency Contact', user.emergencyContact?.isNotEmpty == true ? user.emergencyContact! : 'Not provided'),
                    const Divider(height: 16),
                    _buildInfoRow('Blood Group', user.bloodGroup?.isNotEmpty == true ? user.bloodGroup! : 'Not specified'),
                    const Divider(height: 16),
                    _buildInfoRow('Known Allergies', user.allergies?.isNotEmpty == true ? user.allergies! : 'None reported'),
                    const Divider(height: 16),
                    _buildInfoRow('Chronic Conditions', user.chronicConditions?.isNotEmpty == true ? user.chronicConditions! : 'None reported'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Preferences & Settings
              const Text(
                'App Preferences',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Language (\u0632\u0628\u0627\u0646)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        LanguageSelector(
                          selectedLanguage: _selectedLang,
                          onLanguageChanged: (lang) => setState(() => _selectedLang = lang),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SMS & Medicine Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('Receive offline SMS for remote areas', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        Switch(
                          value: _smsAlerts,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _smsAlerts = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout Button
              AppCard(
                onTap: _logout,
                padding: const EdgeInsets.all(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.emergency, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emergency,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
