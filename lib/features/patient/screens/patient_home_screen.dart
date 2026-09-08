import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/risk_indicator_badge.dart';
import '../../../services/auth_service.dart';
import '../../../services/consultation_service.dart';
import '../../../models/consultation_model.dart';
import '../../../services/medicine_service.dart';
import '../../../services/health_continuity_service.dart';
import '../../../models/care_plan_model.dart';
import '../../emergency/screens/emergency_screen.dart';
import '../../ai/screens/ai_chat_screen.dart';
import '../../doctors/screens/doctor_list_screen.dart';
import '../../prescriptions/screens/prescription_scanner_screen.dart';
import '../../medicines/screens/medicines_screen.dart';
import '../../consultation/screens/consultation_screen.dart';
import '../../health_continuity/screens/care_plan_detail_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const PatientHomeScreen({super.key, this.onNavigateTab});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final MedicineService _medicineService = MedicineService();
  final HealthContinuityService _continuityService = HealthContinuityService();
  CarePlanModel? _latestCarePlan;
  bool _isLoading = false;
  String? _loadError;

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
        AuthService().refreshProfile(),
        _consultationService.fetchPatientConsultations(),
        _medicineService.fetchMedicines(),
      ]);
      // Try loading care plan for the latest completed consultation
      final completedConsultations = _consultationService.consultations
          .where((c) => c.status == ConsultationStatus.completed)
          .toList();
      if (completedConsultations.isNotEmpty) {
        final plan = await _continuityService.fetchCarePlan(
          int.tryParse(completedConsultations.first.id) ?? 0,
        );
        if (mounted) setState(() => _latestCarePlan = plan);
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load health data. Pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = AuthService().currentUser;
    final firstName = patient.fullName.trim().isNotEmpty
        ? patient.fullName.trim().split(' ').first
        : 'Patient';
    final consultations = _consultationService.consultations;
    final medicines = _medicineService.medicines;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hello, $firstName 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'How are you feeling today?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.onNavigateTab != null) widget.onNavigateTab!(4);
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryContainer,
                        child: const Icon(Icons.person, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Error State
                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      backgroundColor: AppColors.emergencyLight,
                      borderColor: AppColors.emergency.withOpacity(0.3),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyDark, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _loadError!,
                              style: const TextStyle(fontSize: 12, color: AppColors.emergencyDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loading indicator
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                // Hero Emergency Card (SOS)
                AppCard(
                  backgroundColor: AppColors.emergencyLight,
                  borderColor: AppColors.emergency.withOpacity(0.35),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.emergency,
                              shape: BoxShape.circle,
                            ),
                            child:
                                const Icon(Icons.emergency_rounded, color: AppColors.textWhite, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '🆘 EMERGENCY HELP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: AppColors.emergencyDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Need urgent medical assistance or fast symptom triage in your area?',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.emergencyDark,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      EmergencyButton(
                        label: 'Get Emergency Help',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const EmergencyScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // AI Assistant Card
                AppCard(
                  backgroundColor: AppColors.surface,
                  borderColor: AppColors.primaryLight.withOpacity(0.3),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              '🤖 Talk to SehatAI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Urdu / English',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.secondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        AppStrings.aiCardSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(1);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const AiChatScreen()),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Start AI Assessment',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions Grid
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildQuickActionTile(
                      title: 'Check Symptoms',
                      icon: Icons.health_and_safety_outlined,
                      color: AppColors.primary,
                      bgColor: AppColors.primaryContainer,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const EmergencyScreen()),
                        );
                      },
                    ),
                    _buildQuickActionTile(
                      title: 'Find Doctor',
                      icon: Icons.person_search_outlined,
                      color: AppColors.secondary,
                      bgColor: AppColors.secondaryContainer,
                      onTap: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(2);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const DoctorListScreen()),
                          );
                        }
                      },
                    ),
                    _buildQuickActionTile(
                      title: 'Scan Prescription',
                      icon: Icons.document_scanner_outlined,
                      color: const Color(0xFF7C3AED),
                      bgColor: const Color(0xFFEDE9FE),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const PrescriptionScannerScreen()),
                        );
                      },
                    ),
                    _buildQuickActionTile(
                      title: 'Medicines',
                      icon: Icons.medication_outlined,
                      color: const Color(0xFF059669),
                      bgColor: AppColors.successLight,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const MedicinesScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Health Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Health Activity',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (widget.onNavigateTab != null) widget.onNavigateTab!(3);
                      },
                      child: const Text('View All',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Recent Consultation Card
                if (consultations.isNotEmpty) ...[
                  AppCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ConsultationScreen(consultation: consultations.first),
                        ),
                      );
                    },
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              const Icon(Icons.video_chat_outlined, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    consultations.first.doctor.name,
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                  if (consultations.first.triageSummary != null)
                                    RiskIndicatorBadge(
                                        riskLevel: consultations.first.triageSummary!.riskLevel),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                consultations.first.symptoms,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // AI Care Plan Card (Health Continuity Engine)
                if (_latestCarePlan != null) ...[                  AppCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CarePlanDetailScreen(carePlan: _latestCarePlan!),
                        ),
                      );
                    },
                    padding: const EdgeInsets.all(14),
                    backgroundColor: AppColors.secondaryContainer.withOpacity(0.4),
                    borderColor: AppColors.secondary.withOpacity(0.2),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.healing_outlined, color: AppColors.secondary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'AI Care Plan Ready',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  if (_latestCarePlan!.daysUntilFollowUp != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _latestCarePlan!.daysUntilFollowUp! <= 2
                                            ? AppColors.warningLight
                                            : AppColors.successLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_latestCarePlan!.daysUntilFollowUp}d follow-up',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _latestCarePlan!.daysUntilFollowUp! <= 2
                                              ? AppColors.warningDark
                                              : AppColors.successDark,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_latestCarePlan!.medicineGuidance.length} medicines • ${_latestCarePlan!.warningSigns.length} warning signs',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Next Dose Reminder Card
                if (medicines.isNotEmpty) ...[
                  AppCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const MedicinesScreen()),
                      );
                    },
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              const Icon(Icons.alarm_on_rounded, color: AppColors.secondary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Next Dose: ${medicines.first.medicineName}',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    medicines.first.timeOfDay,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${medicines.first.dosage} • ${medicines.first.instructions}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
