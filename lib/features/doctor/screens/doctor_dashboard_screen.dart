import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/risk_indicator_badge.dart';
import '../../../models/consultation_model.dart';
import '../../../services/consultation_service.dart';
import '../../../services/doctor_service.dart';
import '../../../services/auth_service.dart';
import 'doctor_patient_detail_screen.dart';
import '../../consultation/screens/consultation_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DoctorDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final DoctorService _doctorService = DoctorService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _consultationService.fetchDoctorConsultations();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleAccept(ConsultationModel req) async {
    if (AuthService().verificationStatus != 'verified') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access Denied: Unverified doctors cannot accept consultations until PMDC credentials are approved by Admin.',
          ),
          backgroundColor: AppColors.emergency,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    final success = await _consultationService.acceptConsultation(req.id);
    if (mounted) {
      if (success) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation accepted. Session started.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept consultation.'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  Future<void> _handleDecline(String consultationId) async {
    final success = await _consultationService.rejectConsultation(consultationId);
    if (mounted) {
      if (success) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation declined.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decline consultation.'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorUser = AuthService().currentUser;
    final consultations = _consultationService.consultations;
    final pendingRequests = consultations.where((c) => c.status == ConsultationStatus.pending).toList();
    final activeConsultations = consultations.where((c) => c.status == ConsultationStatus.inProgress).toList();
    final isOnline = _doctorService.isDoctorOnline;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Dr. ${doctorUser.fullName.split(' ').first}\'s Portal'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isOnline ? AppColors.successDark : AppColors.textMuted,
                  ),
                ),
                Switch(
                  value: isOnline,
                  activeColor: AppColors.success,
                  onChanged: (_) async {
                    await _doctorService.toggleOnlineStatus();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Good morning, ${doctorUser.fullName} 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Review incoming patient triage requests & active telemedicine sessions.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),

                      // KPI Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Pending Triage',
                              '${pendingRequests.length}',
                              Icons.notifications_active_outlined,
                              AppColors.emergency,
                              AppColors.emergencyLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              'Active Consults',
                              '${activeConsultations.length}',
                              Icons.video_camera_front_outlined,
                              AppColors.primary,
                              AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              'Total Patients',
                              '${consultations.length}',
                              Icons.groups_outlined,
                              AppColors.secondary,
                              AppColors.secondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Urgent Pending Requests Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Incoming Triage Requests',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (widget.onNavigateTab != null)
                            TextButton(
                              onPressed: () => widget.onNavigateTab!(1),
                              child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (pendingRequests.isEmpty)
                        AppCard(
                          padding: const EdgeInsets.all(20),
                          child: const Center(
                            child: Text('No pending triage requests at the moment.',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      else
                        ...pendingRequests.map((req) => _buildRequestCard(req)),

                      const SizedBox(height: 24),

                      // Active Consultations Section
                      const Text(
                        'Active Consultations',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (activeConsultations.isEmpty)
                        AppCard(
                          padding: const EdgeInsets.all(20),
                          child: const Center(
                            child: Text('No ongoing consultation sessions.',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      else
                        ...activeConsultations.map((consult) => _buildActiveConsultCard(consult)),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String count, IconData icon, Color color, Color bg) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(ConsultationModel req) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${req.patient.fullName} (${req.patient.age ?? 28} yrs, ${req.patient.gender ?? "Female"})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (req.triageSummary != null)
                RiskIndicatorBadge(riskLevel: req.triageSummary!.riskLevel),
            ],
          ),
          const SizedBox(height: 4),
          Text('Region: ${req.patient.city ?? "Tharparkar"}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text('Symptoms: ${req.symptoms}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleDecline(req.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DoctorPatientDetailScreen(consultation: req),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('View Patient', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAccept(req),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                  child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveConsultCard(ConsultationModel consult) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConsultationScreen(consultation: consult),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryContainer,
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consult.patient.fullName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  consult.symptoms,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
