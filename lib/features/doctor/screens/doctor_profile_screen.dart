import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../models/doctor_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_service.dart';
import '../../auth/screens/login_screen.dart';

class DoctorSelfProfileScreen extends StatefulWidget {
  const DoctorSelfProfileScreen({super.key});

  @override
  State<DoctorSelfProfileScreen> createState() => _DoctorSelfProfileScreenState();
}

class _DoctorSelfProfileScreenState extends State<DoctorSelfProfileScreen> {
  final DoctorService _doctorService = DoctorService();
  DoctorModel? _doctorProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _doctorService.fetchDoctorProfile();
    if (mounted) {
      setState(() {
        _doctorProfile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isOnline = _doctorService.isDoctorOnline;
    final verificationStatus = AuthService().verificationStatus ?? 'pending';

    // Use live doctor profile when available, otherwise fall back to user data
    final doctorName = _doctorProfile?.name ?? user.fullName;
    final specialization = _doctorProfile?.specialization ?? 'General Physician';
    final qualification = _doctorProfile?.qualification ?? 'MBBS';
    final pmdcNumber = _doctorProfile?.pmdcNumber ?? 'PMDC-Pending';
    final experienceYears = _doctorProfile?.experienceYears ?? 0;
    final languages = _doctorProfile?.languages ?? const ['Urdu', 'English'];
    final consultationFee = _doctorProfile?.consultationFee ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor Profile & Credentials'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProfile,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading && _doctorProfile == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  // Header Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primaryContainer,
                          child: const Icon(Icons.person, size: 44, color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          doctorName,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialization,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          qualification,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildVerificationBadge(verificationStatus),
                            const SizedBox(width: 8),
                            if (isOnline) StatusBadge.online() else StatusBadge.offline(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pending Verification Warning
                  if (verificationStatus == 'pending')
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      backgroundColor: AppColors.warningLight,
                      borderColor: AppColors.warning.withOpacity(0.3),
                      child: const Row(
                        children: [
                          Icon(Icons.pending_actions_rounded, color: AppColors.warningDark, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your PMDC credentials are pending Admin verification. Consultation acceptance is disabled until approved.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warningDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (verificationStatus == 'rejected')
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      backgroundColor: AppColors.emergencyLight,
                      borderColor: AppColors.emergency.withOpacity(0.3),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: AppColors.emergencyDark, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your PMDC verification was rejected. Please contact Admin support to resolve this issue.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.emergencyDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (verificationStatus == 'pending' || verificationStatus == 'rejected')
                    const SizedBox(height: 20),

                  // Professional Credentials Card
                  const Text(
                    'PMDC Registration & Credentials',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildRow('PMDC License #', pmdcNumber),
                        const Divider(height: 16),
                        _buildRow('Verification Status', _verificationLabel(verificationStatus)),
                        const Divider(height: 16),
                        _buildRow('Clinical Experience', '$experienceYears Years'),
                        const Divider(height: 16),
                        _buildRow('Consultation Fee', Formatters.formatCurrencyPKR(consultationFee)),
                        const Divider(height: 16),
                        _buildRow('Languages', languages.join(', ')),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Sign Out
                AppCard(
                  onTap: () async {
                    final confirmed = await ConfirmationDialog.show(
                      context,
                      title: 'Sign Out?',
                      message: 'Are you sure you want to exit Doctor Portal?',
                      confirmText: 'Sign Out',
                      isDangerous: true,
                    );
                    if (confirmed == true && mounted) {
                      await AuthService().logout();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.emergency, size: 20),
                      SizedBox(width: 8),
                      Text('Sign Out Doctor Session', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.emergency)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(String status) {
    if (status == 'verified') {
      return StatusBadge.verifiedDoctor();
    } else if (status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.emergencyLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.emergency.withOpacity(0.3)),
        ),
        child: const Text(
          'PMDC Rejected',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emergencyDark),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: const Text(
          'PMDC Pending',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warningDark),
        ),
      );
    }
  }

  String _verificationLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verified Active (PMDC Green Badge)';
      case 'rejected':
        return 'Rejected — Contact Admin';
      default:
        return 'Pending Admin Review';
    }
  }

  Widget _buildRow(String label, String val) {
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
            val,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
