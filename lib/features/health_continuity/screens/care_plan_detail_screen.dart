import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../models/care_plan_model.dart';
import '../../emergency/screens/emergency_screen.dart';

/// Full-screen view of an AI Care Plan — shows all medication guidance,
/// warning signs, lifestyle tips, and home monitoring sections.
/// Includes action buttons to contact the doctor or trigger emergency SOS.
class CarePlanDetailScreen extends StatelessWidget {
  final CarePlanModel carePlan;

  const CarePlanDetailScreen({super.key, required this.carePlan});

  @override
  Widget build(BuildContext context) {
    final daysUntil = carePlan.daysUntilFollowUp;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Care Plan'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_outlined, color: AppColors.emergency),
            tooltip: 'Emergency SOS',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmergencyScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor & Follow-up Header
              AppCard(
                padding: const EdgeInsets.all(16),
                backgroundColor: AppColors.secondaryContainer.withOpacity(0.4),
                borderColor: AppColors.secondary.withOpacity(0.25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.healing_rounded, color: AppColors.secondary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Personalized Care Plan',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Prescribed by ${carePlan.doctorName ?? 'Your Doctor'}'
                                '${carePlan.doctorSpecialty != null ? ' (${carePlan.doctorSpecialty})' : ''}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (daysUntil != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: daysUntil <= 2 ? AppColors.warningLight : AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: daysUntil <= 2 ? AppColors.warningDark : AppColors.successDark,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                daysUntil == 0
                                    ? 'Follow-up appointment is today'
                                    : 'Follow-up in $daysUntil day${daysUntil == 1 ? '' : 's'}'
                                        '${carePlan.followUpDate != null ? ' — ${_formatDate(carePlan.followUpDate!)}' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: daysUntil <= 2 ? AppColors.warningDark : AppColors.successDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Medication Guidance Section
              if (carePlan.medicineGuidance.isNotEmpty) ...[
                _buildSectionHeader(Icons.medication_outlined, 'Medication Guidance', AppColors.primary),
                const SizedBox(height: 8),
                ...carePlan.medicineGuidance.map(
                  (mg) => AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mg.medicineName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                mg.howToTake,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.visibility_outlined, size: 14, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                mg.sideEffectsWatch,
                                style: const TextStyle(fontSize: 12, color: AppColors.warningDark, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Warning Signs Section
              if (carePlan.warningSigns.isNotEmpty) ...[
                _buildSectionHeader(Icons.warning_amber_rounded, 'Warning Signs', AppColors.emergency),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: AppColors.emergencyLight.withOpacity(0.3),
                  borderColor: AppColors.emergency.withOpacity(0.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: carePlan.warningSigns.map(
                      (ws) {
                        final isEmergency = ws.contains('1122') || ws.contains('emergency');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isEmergency ? Icons.warning_amber_rounded : Icons.info_outline,
                                size: 16,
                                color: isEmergency ? AppColors.emergency : AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ws,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isEmergency ? AppColors.emergencyDark : AppColors.textPrimary,
                                    fontWeight: isEmergency ? FontWeight.w700 : FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Lifestyle Recommendations Section
              if (carePlan.lifestyleRecommendations.isNotEmpty) ...[
                _buildSectionHeader(Icons.favorite_outline, 'Lifestyle Recommendations', AppColors.success),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: carePlan.lifestyleRecommendations.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Home Monitoring Section
              if (carePlan.homeMonitoring.isNotEmpty) ...[
                _buildSectionHeader(Icons.monitor_heart_outlined, 'Home Monitoring', AppColors.secondary),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: carePlan.homeMonitoring.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined, size: 16, color: AppColors.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Emergency Button
              AppButton(
                text: 'Emergency? Contact Rescue 1122',
                variant: AppButtonVariant.danger,
                leadingIcon: Icons.warning_amber_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Source badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: carePlan.source == 'google_gemini_api'
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    carePlan.source == 'google_gemini_api'
                        ? 'Powered by AI (Gemini)'
                        : 'Offline Template',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: carePlan.source == 'google_gemini_api'
                          ? AppColors.successDark
                          : AppColors.warningDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'This care plan is for guidance only and does not replace professional medical advice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
