import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/risk_indicator_badge.dart';
import '../../../models/consultation_model.dart';
import '../../../models/medicine_reminder_model.dart';
import '../../../models/medical_record_model.dart';
import '../../../services/consultation_service.dart';
import '../../../services/medicine_service.dart';
import '../../../services/medical_records_service.dart';
import '../../../services/auth_service.dart';
import '../../consultation/screens/consultation_screen.dart';
import '../../health_continuity/widgets/patient_brief_card.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final ConsultationModel consultation;

  const DoctorPatientDetailScreen({super.key, required this.consultation});

  @override
  State<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> {
  final MedicineService _medicineService = MedicineService();
  final MedicalRecordsService _recordsService = MedicalRecordsService();
  List<MedicineReminderModel> _medicines = [];
  List<MedicalRecordModel> _records = [];
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Always request the explicitly selected patient's data — never a
    // server-side demo patient default.
    final patientId = int.tryParse(widget.consultation.patient.id);
    final meds = await _medicineService.fetchMedicines(patientId: patientId);
    final recs = await _recordsService.fetchRecords(patientId: patientId);
    if (mounted) {
      setState(() {
        _medicines = meds.take(2).toList();
        _records = recs.take(2).toList();
        _loadError = (_medicineService.hasError && meds.isEmpty) ||
            (_recordsService.hasError && recs.isEmpty);
      });
    }
  }

  Future<void> _handleStartConsultation() async {
    if (AuthService().verificationStatus != 'verified') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Unverified doctors cannot start consultations.'),
          backgroundColor: AppColors.emergency,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final success = await ConsultationService().acceptConsultation(widget.consultation.id);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConsultationScreen(consultation: widget.consultation),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start consultation session.'),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.consultation.patient;
    final triage = widget.consultation.triageSummary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${patient.fullName}\'s Medical File'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Demographic Card
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryContainer,
                      child: const Icon(Icons.person, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.fullName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${patient.gender ?? 'Male'}, ${patient.age ?? 34} yrs • Blood Group: ${patient.bloodGroup ?? 'B+'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Location: ${patient.city ?? 'Gilgit District'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI Triage Summary Card
              if (triage != null) ...[
                const Text(
                  'AI Triage & Risk Assessment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: triage.riskLevel == TriageRiskLevel.high
                      ? AppColors.emergencyLight
                      : AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RiskIndicatorBadge(riskLevel: triage.riskLevel, isLarge: true),
                          Text(
                            Formatters.formatDateTime(triage.timestamp),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Reported Complaint: "${triage.primaryComplaint}"',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 6),
                      const Text(
                        'Detected Clinical Indicators:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      ...triage.detectedSymptoms.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $s', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // AI Patient Brief (Health Continuity Engine)
              AiPatientBriefCard(
                consultationId: int.tryParse(widget.consultation.id) ?? 0,
              ),
              const SizedBox(height: 20),

              // Data load error (real API failure — no demo fallback)
              if (_loadError) ...[
                AppCard(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: AppColors.emergencyLight,
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 20, color: AppColors.emergency),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Could not load this patient\'s medicines & records. Check your connection and retry.',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadData,
                        child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Current Medications
              const Text(
                'Current Prescribed Medications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ..._medicines.map(
                (med) => AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.medicineName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text('${med.dosage} • ${med.frequency}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                    ],
                  ),
                ),
              ),
              if (_medicines.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: const Center(
                    child: Text('No medications on record.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ),
              const SizedBox(height: 20),

              // Recent Lab Reports & History
              const Text(
                'Recent Medical History & Diagnostic Reports',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ..._records.map(
                (rec) => AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(rec.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(Formatters.formatDate(rec.date), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(rec.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              if (_records.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: const Center(
                    child: Text('No medical history on record.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ),
              const SizedBox(height: 28),

              // Start Consultation CTA
              AppButton(
                text: 'Start Consultation Session',
                leadingIcon: Icons.chat_rounded,
                onPressed: _handleStartConsultation,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
