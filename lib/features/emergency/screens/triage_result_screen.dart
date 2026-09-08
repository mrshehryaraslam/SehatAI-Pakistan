import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/risk_indicator_badge.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../models/triage_model.dart';
import '../../doctors/screens/doctor_list_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/consultation_service.dart';
import '../../../services/emergency_actions_service.dart';
import '../../../services/emergency_service.dart';

class TriageResultScreen extends StatelessWidget {
  final TriageModel triage;

  const TriageResultScreen({super.key, required this.triage});

  @override
  Widget build(BuildContext context) {
    Color headerBg;
    Color headerFg;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    switch (triage.riskLevel) {
      case TriageRiskLevel.high:
        headerBg = AppColors.emergencyLight;
        headerFg = AppColors.emergencyDark;
        statusIcon = Icons.warning_rounded;
        statusTitle = 'HIGH-RISK SYMPTOMS DETECTED';
        statusSubtitle = 'Immediate professional medical attention is urgently recommended.';
        break;
      case TriageRiskLevel.moderate:
        headerBg = AppColors.warningLight;
        headerFg = AppColors.warningDark;
        statusIcon = Icons.info_rounded;
        statusTitle = 'MODERATE RISK DETECTED';
        statusSubtitle = 'Professional medical consultation advised within 24 hours.';
        break;
      case TriageRiskLevel.low:
        headerBg = AppColors.successLight;
        headerFg = AppColors.successDark;
        statusIcon = Icons.check_circle_rounded;
        statusTitle = 'LOW RISK ASSESSMENT';
        statusSubtitle = 'Self-care and routine symptom observation recommended.';
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Triage Assessment'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Status Card
              AppCard(
                backgroundColor: headerBg,
                borderColor: headerFg.withOpacity(0.3),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: headerFg.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, color: headerFg, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RiskIndicatorBadge(riskLevel: triage.riskLevel, isLarge: true),
                              const SizedBox(height: 6),
                              Text(
                                statusTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: headerFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: headerFg,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Complaint Summary
              const Text(
                'Reported Symptoms',
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
                    Text(
                      '"${triage.primaryComplaint}"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Identified Clinical Indicators:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...triage.detectedSymptoms.map((symptom) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4, right: 8),
                                child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                              ),
                              Expanded(
                                child: Text(
                                  symptom,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Clinical Guidance Card
              const Text(
                'Preliminary Guidance & Recommended Action',
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
                      children: [
                        const Icon(Icons.medical_information_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'General Guidance',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      triage.generalGuidance,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.next_plan_outlined, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Next Steps',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      triage.nextSteps,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons based on Risk State
              if (triage.riskLevel == TriageRiskLevel.high) ...[
                // High Risk Action Suite
                AppButton(
                  text: 'Call Rescue 1122 (Emergency)',
                  variant: AppButtonVariant.danger,
                  leadingIcon: Icons.phone_in_talk_rounded,
                  onPressed: () {
                    ConfirmationDialog.show(
                      context,
                      title: 'Call Rescue 1122?',
                      message:
                          'This will place an emergency call to Pakistan Rescue 1122 and share your GPS location.',
                      confirmText: 'Call 1122',
                      isDangerous: true,
                      icon: Icons.phone_in_talk_rounded,
                    ).then((confirmed) {
                      if (confirmed == true && context.mounted) {
                        _callRescue1122(context);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Connect On-Call Emergency Doctor',
                  variant: AppButtonVariant.primary,
                  leadingIcon: Icons.video_camera_front_outlined,
                  onPressed: () => _connectImmediateDoctor(context),
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Share Location with Nearby Clinic',
                  variant: AppButtonVariant.outlined,
                  leadingIcon: Icons.location_on_outlined,
                  onPressed: () => _shareLocationWithClinic(context),
                ),
              ] else if (triage.riskLevel == TriageRiskLevel.moderate) ...[
                // Moderate Risk Action Suite
                AppButton(
                  text: 'Find & Consult Available Doctor',
                  variant: AppButtonVariant.primary,
                  leadingIcon: Icons.person_search_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DoctorListScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Ask SehatAI Additional Questions',
                  variant: AppButtonVariant.outlined,
                  leadingIcon: Icons.chat_bubble_outline_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ] else ...[
                // Low Risk Action Suite
                AppButton(
                  text: 'Back to Home Dashboard',
                  variant: AppButtonVariant.primary,
                  leadingIcon: Icons.home_rounded,
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Browse Online Doctors',
                  variant: AppButtonVariant.outlined,
                  leadingIcon: Icons.medical_services_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DoctorListScreen(),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),

              // Mandatory Medical Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.medicalDisclaimer,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Places a REAL emergency call to Rescue 1122 through the OS dialer
  /// (tel:1122) and records a REAL SOS alert — with the live GPS location
  /// when available — in the backend via POST /emergency/sos.
  ///
  /// The dialer is opened first so the emergency call is never delayed or
  /// blocked by location or network failures; every failure is reported
  /// honestly — nothing is simulated.
  Future<void> _callRescue1122(BuildContext context) async {
    final patient = AuthService().currentUser;

    // 1. Safety first — place the actual call.
    final callPlaced = await EmergencyActionsService().callRescue1122();

    // 2. Record the SOS alert with the real location when available.
    final location = await EmergencyActionsService().getCurrentLocation();
    final sosResult = await EmergencyService().sendSos(
      symptoms: triage.primaryComplaint,
      riskLevel: 'high',
      city: patient.city,
      latitude: location?.latitude,
      longitude: location?.longitude,
    );

    if (!context.mounted) return;

    final bool sosOk = sosResult['success'] == true;
    final alertId = sosOk ? (sosResult['data'] as Map)['alert_id'] : null;

    String message;
    Color color;
    if (callPlaced && sosOk) {
      message = 'Calling Rescue 1122… SOS alert #$alertId registered'
          '${location != null ? ' with your live GPS location' : ''}.';
      color = AppColors.success;
    } else if (callPlaced) {
      message =
          'Calling Rescue 1122… but the SOS alert failed: ${sosResult['message']}';
      color = AppColors.emergency;
    } else if (sosOk) {
      message =
          'SOS alert #$alertId registered, but the phone dialer could not open. '
          'Please dial 1122 manually NOW.';
      color = AppColors.emergency;
    } else {
      message =
          'Could not open the phone dialer and the SOS alert failed. '
          'Please dial 1122 manually NOW.';
      color = AppColors.emergency;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  /// Shares the patient's REAL location via the OS share sheet so it can be
  /// sent to a nearby clinic or rescuer. GPS coordinates are only included
  /// when the device location could actually be read — never fabricated.
  Future<void> _shareLocationWithClinic(BuildContext context) async {
    final patient = AuthService().currentUser;

    final location = await EmergencyActionsService().getCurrentLocation();
    final shared = await EmergencyActionsService().shareEmergencyLocation(
      patientName: patient.fullName,
      city: patient.city,
      symptoms: triage.primaryComplaint,
      location: location,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shared
              ? (location != null
                  ? 'Emergency location share opened with your live GPS coordinates.'
                  : 'Location share opened — live GPS unavailable (permission denied or GPS off).')
              : 'Could not open the location share sheet. Please share your location manually.',
        ),
        backgroundColor: shared ? AppColors.primary : AppColors.emergency,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Sends a real emergency SOS and a real consultation request via the API.
  /// No local/demo consultation is created and SOS failures are surfaced as
  /// real errors — success is never simulated.
  Future<void> _connectImmediateDoctor(BuildContext context) async {
    final patient = AuthService().currentUser;

    // Real device location when available — never fabricated coordinates.
    final location = await EmergencyActionsService().getCurrentLocation();

    final sosResult = await EmergencyService().sendSos(
      symptoms: triage.primaryComplaint,
      riskLevel: 'high',
      city: patient.city,
      latitude: location?.latitude,
      longitude: location?.longitude,
    );

    if (!context.mounted) return;

    if (sosResult['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sosResult['message']?.toString() ??
                'Emergency SOS failed. Please call 1122 directly.',
          ),
          backgroundColor: AppColors.emergency,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    final consultSuccess = await ConsultationService().requestConsultation(
      symptoms: triage.primaryComplaint,
      riskLevel: 'high',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(consultSuccess
            ? 'Emergency alert sent. A verified on-call doctor has been notified and will respond shortly.'
            : 'Emergency alert recorded, but the consultation request failed. Please try again.'),
        backgroundColor: consultSuccess ? AppColors.success : AppColors.emergency,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
