import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  String? _loadError;
  List<Map<String, dynamic>> _emergencyLogs = [];
  bool _isUpdatingAlert = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await Future.wait([
        _adminService.fetchMetrics(),
        _adminService.fetchDoctors(status: 'pending'),
      ]);
      final logs = await _adminService.fetchEmergencyLogs();
      if (mounted) {
        setState(() {
          _emergencyLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load admin data. Pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVerifyDoctor(int doctorId, String status) async {
    setState(() => _isLoading = true);
    final success = await _adminService.verifyDoctor(doctorId: doctorId, status: status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (status == 'verified'
                    ? 'Doctor PMDC credentials approved & verified successfully!'
                    : 'Doctor PMDC verification rejected.')
                : 'Failed to update doctor verification. Please try again.',
          ),
          backgroundColor: success
              ? (status == 'verified' ? AppColors.success : AppColors.emergency)
              : AppColors.textSecondary,
        ),
      );
      // Refresh all data after verification change
      await _loadData();
    }
  }

  Future<void> _handleUpdateAlertStatus(int alertId, String status) async {
    if (_isUpdatingAlert) return;
    setState(() => _isUpdatingAlert = true);
    final success = await _adminService.updateEmergencyAlertStatus(
      alertId: alertId,
      status: status,
    );
    if (mounted) {
      setState(() => _isUpdatingAlert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Alert #$alertId marked as ${status.toUpperCase()}.'
                : 'Could not update alert status.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.emergency,
        ),
      );
      if (success) {
        // Refresh logs to reflect updated status
        final logs = await _adminService.fetchEmergencyLogs();
        if (mounted) setState(() => _emergencyLogs = logs);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _adminService.metrics;
    final pendingDoctors = _adminService.doctors.where((d) => d.verificationStatus == 'pending').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Administration Control'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh Metrics',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Telehealth System Command',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'National Health Network Monitoring & Doctor PMDC Verification Gate',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // Loading / Error states
                if (_isLoading && metrics == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_loadError != null && metrics == null)
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    backgroundColor: AppColors.emergencyLight,
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.emergency, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.emergencyDark, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // System Overview KPI Cards
                  const Text(
                    'National System Metrics (Live MySQL Database)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.3,
                      children: [
                        _buildMetricTile(
                          'Total Patients',
                          '${metrics?.totalPatients ?? 0}',
                          Icons.people_alt_outlined,
                          AppColors.primary,
                          AppColors.primaryContainer,
                        ),
                        _buildMetricTile(
                          'Verified Doctors',
                          '${metrics?.verifiedDoctors ?? 0}',
                          Icons.medical_services_outlined,
                          AppColors.secondary,
                          AppColors.secondaryContainer,
                        ),
                        _buildMetricTile(
                          'Pending PMDC Queue',
                          '${metrics?.pendingVerifications ?? pendingDoctors.length}',
                          Icons.pending_actions_rounded,
                          AppColors.warning,
                          AppColors.warningLight,
                        ),
                        _buildMetricTile(
                          'Active Consultations',
                          '${metrics?.activeConsultations ?? 0}',
                          Icons.video_call_outlined,
                          AppColors.success,
                          AppColors.successLight,
                        ),
                        _buildMetricTile(
                          'Emergency SOS Alerts',
                          '${metrics?.totalEmergencyAlerts ?? 0}',
                          Icons.emergency_rounded,
                          AppColors.emergency,
                          AppColors.emergencyLight,
                        ),
                        _buildMetricTile(
                          'Pending Emergencies',
                          '${metrics?.pendingEmergencies ?? 0}',
                          Icons.warning_amber_rounded,
                          const Color(0xFF7C3AED),
                          const Color(0xFFEDE9FE),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Pending Doctor Verification Queue
                  Text(
                    'Doctor PMDC Verification Queue (${pendingDoctors.length} Pending)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading && pendingDoctors.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (pendingDoctors.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No pending doctor verifications. All PMDC credentials verified.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...pendingDoctors.map((doc) => _buildDoctorCard(doc)),

                  const SizedBox(height: 24),

                  // Emergency SOS Audit Logs
                  Text(
                    'Emergency SOS Audit Logs (${_emergencyLogs.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  if (_emergencyLogs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No emergency alerts recorded.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._emergencyLogs.take(10).map((log) => _buildEmergencyLogTile(log)),

                  const SizedBox(height: 20),
                ],

                // Sign Out
                AppCard(
                  onTap: () async {
                    final confirmed = await ConfirmationDialog.show(
                      context,
                      title: 'Sign Out Admin?',
                      message: 'Exit Admin command portal?',
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
                      Text('Sign Out Admin Session', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.emergency)),
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

  Widget _buildMetricTile(String title, String value, IconData icon, Color color, Color bg) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(AdminDoctorModel doc) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(doc.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(6)),
                child: const Text('Pending Verification', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warningDark)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${doc.qualification} \u2022 ${doc.specialization}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('PMDC: ${doc.pmdcNumber} \u2022 ${doc.hospital}, ${doc.city}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => _handleVerifyDoctor(doc.id, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emergency,
                    side: const BorderSide(color: AppColors.emergency),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Reject License', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleVerifyDoctor(doc.id, 'verified'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                  child: const Text('Approve & Verify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyLogTile(Map<String, dynamic> log) {
    final riskLevel = log['risk_level']?.toString().toLowerCase() ?? 'moderate';
    final isHigh = riskLevel == 'high';
    final status = log['status']?.toString() ?? 'pending';
    final alertId = int.tryParse(log['id']?.toString() ?? '0') ?? 0;
    final isResolved = status == 'resolved';
    final isReviewed = status == 'reviewed';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  log['patient_name']?.toString() ?? 'Unknown Patient',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isHigh ? AppColors.emergencyLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  riskLevel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isHigh ? AppColors.emergencyDark : AppColors.warningDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log['symptom_description']?.toString() ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${log['city'] ?? "Unknown"} \u2022 ${log['patient_phone'] ?? ""}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isResolved
                      ? AppColors.successLight
                      : isReviewed
                          ? AppColors.primaryContainer
                          : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isResolved
                        ? AppColors.successDark
                        : isReviewed
                            ? AppColors.primaryDark
                            : AppColors.warningDark,
                  ),
                ),
              ),
            ],
          ),
          // Acknowledge / Resolve actions (only for non-resolved alerts)
          if (!isResolved && alertId > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (!isReviewed)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUpdatingAlert
                          ? null
                          : () => _handleUpdateAlertStatus(alertId, 'reviewed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      child: const Text('Acknowledge', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (!isReviewed) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUpdatingAlert
                        ? null
                        : () => _handleUpdateAlertStatus(alertId, 'resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 0,
                    ),
                    child: const Text('Resolve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
