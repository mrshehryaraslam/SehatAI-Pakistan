import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/risk_indicator_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../services/consultation_service.dart';
import '../../../models/consultation_model.dart';
import '../../health_continuity/widgets/care_plan_card.dart';
import 'chat_screen.dart';

class ConsultationScreen extends StatefulWidget {
  final ConsultationModel consultation;

  const ConsultationScreen({super.key, required this.consultation});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  bool _isEnding = false;

  ConsultationModel get consultation => widget.consultation;

  Future<void> _handleEndConsultation() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'End Consultation Session?',
      message: 'Are you sure you want to conclude this telemedicine session? '
          'Your digital records and prescription summary will be saved.',
      confirmText: 'End Session',
      isDangerous: false,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isEnding = true);

    final intId = int.tryParse(consultation.id);
    if (intId == null) {
      setState(() => _isEnding = false);
      return;
    }

    final success = await ConsultationService().updateConsultationStatus(
      intId,
      'completed',
    );

    if (!mounted) return;
    setState(() => _isEnding = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation session ended successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to end consultation. Please retry.'),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  Future<void> _handleCancelConsultation() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cancel Consultation?',
      message: 'Are you sure you want to cancel this consultation request?',
      confirmText: 'Cancel Request',
      isDangerous: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isEnding = true);

    final intId = int.tryParse(consultation.id);
    if (intId == null) {
      setState(() => _isEnding = false);
      return;
    }

    final success = await ConsultationService().updateConsultationStatus(
      intId,
      'cancelled',
    );

    if (!mounted) return;
    setState(() => _isEnding = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation cancelled.'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel consultation. Please retry.'),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation Session'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All consultations are encrypted and PMDC telemedicine regulated.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isEnding
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Consultation Status Banner — dynamic based on actual status
              _buildStatusBanner(),
              const SizedBox(height: 20),

              // Doctor Information Card
              const Text(
                'Attending Doctor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryContainer,
                      child: const Icon(Icons.person, size: 32, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consultation.doctor.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            consultation.doctor.specialization,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StatusBadge.verifiedDoctor(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Patient Info & Reported Symptoms
              const Text(
                'Patient & Symptoms Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          consultation.patient.fullName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${consultation.patient.gender ?? 'Male'}, ${consultation.patient.age ?? 34} yrs',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Location: ${consultation.patient.city ?? 'Gilgit / Rural District'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Primary Complaint:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      consultation.symptoms,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI Triage Summary
              if (consultation.triageSummary != null) ...[
                const Text(
                  'AI Triage Assessment Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: consultation.triageSummary!.riskLevel == TriageRiskLevel.high
                      ? AppColors.emergencyLight
                      : AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RiskIndicatorBadge(riskLevel: consultation.triageSummary!.riskLevel),
                          Text(
                            'AI Confidence: High',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        consultation.triageSummary!.generalGuidance,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // AI Care Plan (Health Continuity Engine) — visible when consultation is completed
              if (consultation.status == ConsultationStatus.completed) ...[                AiCarePlanCard(
                  consultationId: int.tryParse(consultation.id) ?? 0,
                ),
                const SizedBox(height: 20),
              ],

              // Actions Panel — context-sensitive based on status
              if (consultation.status == ConsultationStatus.inProgress ||
                  consultation.status == ConsultationStatus.pending) ...[
              const Text(
                'Consultation Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Chat Action (Primary)
              AppButton(
                text: 'Open Doctor Chat (${consultation.chatMessages.length} Messages)',
                leadingIcon: Icons.chat_bubble_outline_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(consultation: consultation),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Audio & Video Call Placeholders
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Audio Call',
                      variant: AppButtonVariant.outlined,
                      leadingIcon: Icons.phone_outlined,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📞 Secure audio call placeholder (Available in Phase 2).'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Video Call',
                      variant: AppButtonVariant.outlined,
                      leadingIcon: Icons.videocam_outlined,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📹 WebRTC video call placeholder (Available in Phase 2).'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // End / Cancel Consultation Button
              if (consultation.status == ConsultationStatus.inProgress)
                AppButton(
                  text: 'End Consultation',
                  variant: AppButtonVariant.text,
                  onPressed: _handleEndConsultation,
                )
              else if (consultation.status == ConsultationStatus.pending)
                AppButton(
                  text: 'Cancel Consultation Request',
                  variant: AppButtonVariant.text,
                  onPressed: _handleCancelConsultation,
                ),
              const SizedBox(height: 20),
              ], // close Actions Panel spread
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    IconData icon;
    String title;
    String subtitle;
    Color bgColor;
    Color borderColor;
    Color iconBg;

    switch (consultation.status) {
      case ConsultationStatus.pending:
        icon = Icons.hourglass_top_rounded;
        title = 'Pending Consultation Request';
        subtitle = 'Waiting for doctor to accept your consultation request.';
        bgColor = AppColors.warningLight;
        borderColor = AppColors.warning.withOpacity(0.3);
        iconBg = AppColors.warning;
        break;
      case ConsultationStatus.inProgress:
        icon = Icons.check_circle_rounded;
        title = 'Active Telehealth Consultation';
        subtitle = 'Connected to PMDC registered medical practitioner.';
        bgColor = AppColors.primaryContainer.withOpacity(0.5);
        borderColor = AppColors.primaryLight.withOpacity(0.4);
        iconBg = AppColors.primary;
        break;
      case ConsultationStatus.completed:
        icon = Icons.task_alt_rounded;
        title = 'Consultation Completed';
        subtitle = 'This telemedicine session has been concluded.';
        bgColor = AppColors.successLight;
        borderColor = AppColors.success.withOpacity(0.3);
        iconBg = AppColors.success;
        break;
      case ConsultationStatus.cancelled:
        icon = Icons.cancel_rounded;
        title = 'Consultation Cancelled';
        subtitle = 'This consultation request was cancelled.';
        bgColor = AppColors.emergencyLight;
        borderColor = AppColors.emergency.withOpacity(0.3);
        iconBg = AppColors.emergency;
        break;
    }

    return AppCard(
      backgroundColor: bgColor,
      borderColor: borderColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textWhite, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
