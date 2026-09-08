import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/risk_indicator_badge.dart';
import '../../../models/consultation_model.dart';
import '../../../services/consultation_service.dart';
import '../../../services/auth_service.dart';
import 'doctor_patient_detail_screen.dart';

class DoctorRequestsScreen extends StatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen> {
  final ConsultationService _consultationService = ConsultationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    await _consultationService.fetchDoctorConsultations();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleAccept(String consultationId) async {
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
    final success = await _consultationService.acceptConsultation(consultationId);
    if (mounted) {
      if (success) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation accepted successfully.'),
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

  @override
  Widget build(BuildContext context) {
    final allRequests = _consultationService.consultations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Consultation Requests'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : allRequests.isEmpty
                ? const Center(
                    child: Text('No consultation requests found.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRequests,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allRequests.length,
                      itemBuilder: (context, index) {
                        final req = allRequests[index];
                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      req.patient.fullName,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  if (req.triageSummary != null)
                                    RiskIndicatorBadge(riskLevel: req.triageSummary!.riskLevel),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${req.patient.gender ?? 'Male'}, ${req.patient.age ?? 30} yrs • ${req.patient.city ?? 'Remote Clinic'}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Symptoms: ${req.symptoms}',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Requested: ${Formatters.formatDateTime(req.requestedAt)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DoctorPatientDetailScreen(consultation: req),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: const Text('View Full History',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                  if (req.status == ConsultationStatus.pending) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _handleAccept(req.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.textWhite,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          elevation: 0,
                                        ),
                                        child: const Text('Accept',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
