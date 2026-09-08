import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../models/medicine_reminder_model.dart';
import '../../../models/daily_adherence_model.dart';
import '../../../services/medicine_service.dart';
import 'add_medicine_screen.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final MedicineService _medicineService = MedicineService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _medicineService.fetchMedicines(),
      _medicineService.fetchDailyAdherence(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleReminder(String id) async {
    await _medicineService.toggleReminder(id);
    if (mounted) setState(() {});
  }

  Future<void> _markIntake(String id, String status) async {
    final ok = await _medicineService.markIntake(id, status: status);
    if (mounted) {
      setState(() {});
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as $status.'),
            backgroundColor: status == 'taken' ? AppColors.success : AppColors.warning,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _deleteMedicine(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Remove "$name" from your medicine list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.emergency)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await _medicineService.deleteMedicine(id);
      if (mounted) {
        setState(() {});
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete reminder.'), backgroundColor: AppColors.emergency),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicines = _medicineService.medicines;
    final adherence = _medicineService.adherence;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Medicines & Reminders'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _medicineService.hasError
                ? _buildErrorState()
                : medicines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medication_liquid_outlined, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text(
                              'No medicines scheduled.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Add daily medicines to receive reminders.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          children: [
                            if (adherence != null && adherence.totalActive > 0)
                              _buildAdherenceCard(adherence),
                            ...medicines.map((med) => _buildMedicineCard(med, adherence)),
                          ],
                        ),
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medicine'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddMedicineScreen(),
            ),
          );
          _loadData();
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Could not load your medicines.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _medicineService.errorMessage ?? 'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard(DailyAdherenceModel adherence) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Adherence',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _adherenceStat(Icons.check_circle_rounded, '${adherence.taken}', 'Taken', AppColors.success),
              ),
              Expanded(
                child: _adherenceStat(Icons.cancel_rounded, '${adherence.missed}', 'Missed', AppColors.emergency),
              ),
              Expanded(
                child: _adherenceStat(Icons.schedule_rounded, '${adherence.pending}', 'Pending', AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: adherence.totalActive > 0 ? adherence.taken / adherence.totalActive : 0,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${adherence.adherencePercent}% adherence today',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _adherenceStat(IconData icon, String count, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  /// Resolves the intake status for a given medicine from adherence data.
  String _intakeStatusFor(MedicineReminderModel med, DailyAdherenceModel? adherence) {
    if (adherence == null) return 'pending';
    final match = adherence.medicines.where((m) => m.reminderId.toString() == med.id).toList();
    return match.isNotEmpty ? match.first.intakeStatus : 'pending';
  }

  Widget _buildMedicineCard(MedicineReminderModel med, DailyAdherenceModel? adherence) {
    final intakeStatus = _intakeStatusFor(med, adherence);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: med.isReminderActive ? AppColors.primaryContainer : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: med.isReminderActive ? AppColors.primary : AppColors.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.medicineName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dosage: ${med.dosage}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
                onSelected: (val) {
                  if (val == 'delete') _deleteMedicine(med.id, med.medicineName);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete Reminder')),
                ],
              ),
              Switch(
                value: med.isReminderActive,
                activeColor: AppColors.primary,
                onChanged: (val) => _toggleReminder(med.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    med.timeOfDay,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.repeat_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    med.frequency,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Until ${Formatters.formatDate(med.endDate)} \u2022 ${med.instructions}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Taken / Missed buttons (only for active reminders)
          if (med.isReminderActive) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _intakeButton(
                    label: 'Taken',
                    icon: Icons.check_circle_outline_rounded,
                    isActive: intakeStatus == 'taken',
                    color: AppColors.success,
                    onPressed: () => _markIntake(med.id, 'taken'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _intakeButton(
                    label: 'Missed',
                    icon: Icons.cancel_outlined,
                    isActive: intakeStatus == 'missed',
                    color: AppColors.emergency,
                    onPressed: () => _markIntake(med.id, 'missed'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _intakeButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive ? Colors.white : color,
        backgroundColor: isActive ? color : Colors.transparent,
        side: BorderSide(color: color, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
