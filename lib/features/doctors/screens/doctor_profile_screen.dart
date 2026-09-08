import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/doctor_model.dart';
import '../../../services/consultation_service.dart';

class DoctorProfileScreen extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorProfileScreen({super.key, required this.doctor});

  /// Submits a real consultation request to the API. No local/demo
  /// consultation is created — failures surface as a real error.
  Future<void> _requestConsultation(BuildContext context) async {
    final success = await ConsultationService().requestConsultation(
      symptoms: 'Online telemedicine consultation requested',
      doctorId: doctor.id,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Consultation request sent to ${doctor.name}. You will be notified once it is accepted.'
            : 'Failed to send consultation request. Please check your connection and try again.'),
        backgroundColor: success ? AppColors.success : AppColors.emergency,
        duration: const Duration(seconds: 3),
      ),
    );

    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.primaryContainer,
                            child: const Icon(Icons.person, size: 54, color: AppColors.primary),
                          ),
                          if (doctor.isOnline)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.surface, width: 3),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.qualification,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StatusBadge.verifiedDoctor(),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: AppColors.warningDark),
                              const SizedBox(width: 4),
                              Text(
                                '${doctor.rating} (${doctor.reviewCount} reviews)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Key Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Experience', '${doctor.experienceYears}+ Years', Icons.work_outline),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('License', doctor.pmdcNumber, Icons.verified_user_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Fee', Formatters.formatCurrencyPKR(doctor.consultationFee), Icons.payments_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // About Doctor
              const Text(
                'About Doctor',
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
                      doctor.about,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Hospital / Institution:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.hospitalAffiliation,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Languages & Availability
              const Text(
                'Languages & Consultation Hours',
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
                        const Icon(Icons.language_rounded, size: 18, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Languages: ${doctor.languages.join(", ")}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          doctor.availability,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Request Consultation CTA Button
              AppButton(
                text: 'Request Consultation (${Formatters.formatCurrencyPKR(doctor.consultationFee)})',
                leadingIcon: Icons.video_call_rounded,
                onPressed: () => _requestConsultation(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
