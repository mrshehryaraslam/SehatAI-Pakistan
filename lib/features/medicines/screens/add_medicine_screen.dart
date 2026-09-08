import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/medicine_reminder_model.dart';
import '../../../services/medicine_service.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController(text: '1 Tablet (500mg)');
  final _instructionsController = TextEditingController(text: 'Take after meals with water');

  String _selectedFrequency = 'Twice Daily (Morning & Evening)';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  final List<String> _frequencies = [
    'Once Daily (Morning)',
    'Twice Daily (Morning & Evening)',
    'Three Times Daily (After meals)',
    'Every 8 Hours',
    'Once at Bedtime',
    'As Needed (SOS)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _saveMedicine() async {
    if (_formKey.currentState?.validate() ?? false) {
      final formattedTime = _selectedTime.format(context);
      final reminder = MedicineReminderModel(
        id: 'med_${DateTime.now().millisecondsSinceEpoch}',
        medicineName: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _selectedFrequency,
        timeOfDay: formattedTime,
        startDate: _startDate,
        endDate: _endDate,
        instructions: _instructionsController.text.trim(),
      );

      final success = await MedicineService().addMedicine(reminder);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medicine reminder scheduled for ${_nameController.text}.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        // Real API failure — do not pretend the reminder was saved.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save medicine reminder. Please check your connection and try again.'),
            backgroundColor: AppColors.emergency,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Medicine Reminder'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  label: 'Medicine Name',
                  hintText: 'e.g. Panadol, Augmentin, Risek',
                  controller: _nameController,
                  prefixIcon: Icons.medication_rounded,
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Enter medicine name' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Dosage / Strength',
                  hintText: 'e.g. 1 Tablet, 500mg, 5ml Syrup',
                  controller: _dosageController,
                  prefixIcon: Icons.straighten_rounded,
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Enter dosage' : null,
                ),
                const SizedBox(height: 16),

                const Text(
                  'Frequency',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedFrequency,
                      items: _frequencies.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFrequency = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reminder Time
                const Text(
                  'Primary Dose Time',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                    if (picked != null) setState(() => _selectedTime = picked);
                  },
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedTime.format(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const Icon(Icons.access_time_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Start & End Date
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _startDate = picked);
                            },
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(Formatters.formatDate(_startDate), style: const TextStyle(fontSize: 13)),
                                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: _startDate,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _endDate = picked);
                            },
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(Formatters.formatDate(_endDate), style: const TextStyle(fontSize: 13)),
                                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Instructions & Notes',
                  hintText: 'e.g. Take after breakfast, avoid dairy products',
                  controller: _instructionsController,
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 28),

                AppButton(
                  text: 'Save Medicine Reminder',
                  leadingIcon: Icons.alarm_add_rounded,
                  onPressed: _saveMedicine,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
