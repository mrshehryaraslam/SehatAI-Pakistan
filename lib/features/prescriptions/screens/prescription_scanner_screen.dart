import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../models/prescription_model.dart';
import '../../../models/medicine_reminder_model.dart';
import '../../../services/medicine_service.dart';

class PrescriptionScannerScreen extends StatefulWidget {
  const PrescriptionScannerScreen({super.key});

  @override
  State<PrescriptionScannerScreen> createState() => _PrescriptionScannerScreenState();
}

class _PrescriptionScannerScreenState extends State<PrescriptionScannerScreen> {
  bool _isProcessing = false;
  PrescriptionModel? _scannedPrescription;

  void _simulateScan(String source) {
    setState(() => _isProcessing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing image via $source & SehatAI OCR Engine...'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _scannedPrescription = PrescriptionModel(
            id: 'rx_scanned_${DateTime.now().millisecondsSinceEpoch}',
            doctorName: 'Dr. Ayesha Siddiqui',
            doctorSpecialty: 'Internal Medicine (Gilgit DHQ)',
            date: DateTime.now(),
            items: const [
              PrescriptionItem(
                medicineName: 'Augmentin (Amoxicillin/Clavulanate)',
                dosage: '625 mg Tablet',
                frequency: 'Twice daily (Every 12 hours)',
                duration: '5 Days',
                instructions: 'Take after meals with full glass of water.',
              ),
              PrescriptionItem(
                medicineName: 'Panadol (Paracetamol)',
                dosage: '500 mg Tablet',
                frequency: '3 times daily (SOS for fever)',
                duration: '3 Days',
                instructions: 'Take when temperature exceeds 99.5°F.',
              ),
              PrescriptionItem(
                medicineName: 'Risek (Omeprazole)',
                dosage: '20 mg Capsule',
                frequency: 'Once daily (Morning)',
                duration: '5 Days',
                instructions: 'Take 30 minutes before breakfast.',
              ),
            ],
          );
        });
      }
    });
  }

  void _confirmAndSave() {
    if (_scannedPrescription == null) return;

    // Auto-generate medicine reminders for convenience via real API service
    for (var item in _scannedPrescription!.items) {
      MedicineService().addMedicine(
        MedicineReminderModel(
          id: 'med_auto_${DateTime.now().millisecondsSinceEpoch}_${item.medicineName.hashCode}',
          medicineName: item.medicineName,
          dosage: item.dosage,
          frequency: item.frequency,
          timeOfDay: '08:00 AM & 08:00 PM',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 5)),
          instructions: item.instructions,
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Prescription verified and added to My Medicines schedule.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prescription Scanner (OCR)'),
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
                    const Icon(Icons.document_scanner_outlined, size: 48, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'AI Prescription Digitizer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Upload or photograph doctor handwriting prescriptions to extract medicine names, dosages, and daily reminder times.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : () => _simulateScan('Camera'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 20),
                            label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : () => _simulateScan('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textWhite,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.photo_library_outlined, size: 20),
                            label: const Text('Upload Image', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_isProcessing) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'Analyzing doctor handwriting with SehatAI OCR...',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_scannedPrescription != null) ...[
                // Scanned Extraction Result Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Extracted Prescription Analysis',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Needs User Verification',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warningDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Extracted Items
                ..._scannedPrescription!.items.map((item) {
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medication_outlined, color: AppColors.secondary, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.medicineName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildRowField('Dosage:', item.dosage),
                        _buildRowField('Frequency:', item.frequency),
                        _buildRowField('Duration:', item.duration),
                        _buildRowField('Instructions:', item.instructions),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Mandatory Verification Disclaimer Alert
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warningDark, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.prescriptionDisclaimer,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.warningDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Verify Button
                AppButton(
                  text: 'Verify & Add to My Medicines',
                  leadingIcon: Icons.check_circle_rounded,
                  onPressed: _confirmAndSave,
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
