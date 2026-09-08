import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../models/care_plan_model.dart';
import '../../../services/health_continuity_service.dart';
import '../screens/care_plan_detail_screen.dart';

/// AI Care Plan card — displayed on the patient's consultation screen when
/// a consultation is completed. Shows a summary with medication guidance,
/// warning signs, and follow-up date. Tap opens the full care plan detail screen.
class AiCarePlanCard extends StatefulWidget {
  final int consultationId;

  const AiCarePlanCard({
    super.key,
    required this.consultationId,
  });

  @override
  State<AiCarePlanCard> createState() => _AiCarePlanCardState();
}

class _AiCarePlanCardState extends State<AiCarePlanCard> {
  final HealthContinuityService _service = HealthContinuityService();
  CarePlanModel? _carePlan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCarePlan();
  }

  Future<void> _loadCarePlan() async {
    setState(() => _isLoading = true);
    final plan = await _service.fetchCarePlan(widget.consultationId);
    if (mounted) {
      setState(() {
        _carePlan = plan;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppCard(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.secondary),
              ),
              SizedBox(height: 10),
              Text(
                'Generating AI Care Plan...',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_carePlan == null) {
      return const SizedBox.shrink();
    }

    final plan = _carePlan!;
    final daysUntil = plan.daysUntilFollowUp;

    return AppCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.secondaryContainer.withOpacity(0.4),
      borderColor: AppColors.secondary.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.healing_outlined, size: 18, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                'Your AI Care Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Follow-up countdown
          if (daysUntil != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: daysUntil <= 2
                    ? AppColors.warningLight
                    : AppColors.successLight,
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
                          ? 'Follow-up is today!'
                          : 'Follow-up in $daysUntil day${daysUntil == 1 ? '' : 's'}',
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
            const SizedBox(height: 12),
          ],

          // Medication Guidance (top 3)
          if (plan.medicineGuidance.isNotEmpty) ...[
            _buildSectionLabel('Medication Guidance'),
            const SizedBox(height: 6),
            ...plan.medicineGuidance.take(3).map(
              (mg) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medication_outlined, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mg.medicineName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            mg.howToTake,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (plan.medicineGuidance.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '+ ${plan.medicineGuidance.length - 3} more medicines',
                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 8),
          ],

          // Warning Signs (top 2)
          if (plan.warningSigns.isNotEmpty) ...[
            _buildSectionLabel('Warning Signs'),
            const SizedBox(height: 6),
            ...plan.warningSigns.take(2).map(
              (ws) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      ws.contains('1122') ? Icons.warning_amber_rounded : Icons.info_outline,
                      size: 14,
                      color: ws.contains('1122') ? AppColors.emergency : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ws,
                        style: TextStyle(
                          fontSize: 11,
                          color: ws.contains('1122') ? AppColors.emergencyDark : AppColors.textSecondary,
                          fontWeight: ws.contains('1122') ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // View Full Care Plan Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CarePlanDetailScreen(carePlan: plan),
                  ),
                );
              },
              icon: const Icon(Icons.article_outlined, size: 18),
              label: const Text('View Full Care Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Source badge
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: plan.source == 'google_gemini_api'
                    ? AppColors.successLight
                    : AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                plan.source == 'google_gemini_api' ? 'AI Generated' : 'Offline Template',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: plan.source == 'google_gemini_api'
                      ? AppColors.successDark
                      : AppColors.warningDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}
