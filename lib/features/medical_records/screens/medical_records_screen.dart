import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../models/medical_record_model.dart';
import '../../../services/medical_records_service.dart';
import '../../prescriptions/screens/prescription_scanner_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MedicalRecordsService _recordsService = MedicalRecordsService();
  bool _isLoading = false;

  final List<String> _tabs = [
    'All Records',
    'Consultations',
    'Prescriptions',
    'Lab Reports',
    'Allergies',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    await _recordsService.fetchRecords();
    if (mounted) setState(() => _isLoading = false);
  }

  List<MedicalRecordModel> _getFilteredRecords(int tabIndex) {
    final records = _recordsService.records;
    switch (tabIndex) {
      case 1: // Consultations
        return records.where((r) => r.category == RecordCategory.consultation).toList();
      case 2: // Prescriptions
        return records.where((r) => r.category == RecordCategory.prescription).toList();
      case 3: // Lab Reports
        return records.where((r) => r.category == RecordCategory.labReport).toList();
      case 4: // Allergies
        return records.where((r) => r.category == RecordCategory.allergy).toList();
      default:
        return records;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Digital Medical Records'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRecords,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
            tooltip: 'Scan Prescription',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrescriptionScannerScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          onTap: (_) => setState(() {}),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _recordsService.hasError
                ? _buildErrorState()
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(_tabs.length, (index) {
                      final list = _getFilteredRecords(index);
                      if (list.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text('No records found in this category.',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final record = list[i];
                            return _buildTimelineRecordCard(record);
                          },
                        ),
                      );
                    }),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Scan Document'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PrescriptionScannerScreen(),
            ),
          );
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
            'Could not load your medical records.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _recordsService.errorMessage ?? 'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRecords,
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

  Widget _buildTimelineRecordCard(MedicalRecordModel record) {
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (record.category) {
      case RecordCategory.labReport:
        icon = Icons.biotech_outlined;
        iconBg = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0284C7);
        break;
      case RecordCategory.consultation:
        icon = Icons.medical_services_outlined;
        iconBg = AppColors.primaryContainer;
        iconColor = AppColors.primary;
        break;
      case RecordCategory.allergy:
        icon = Icons.warning_amber_rounded;
        iconBg = AppColors.emergencyLight;
        iconColor = AppColors.emergency;
        break;
      case RecordCategory.prescription:
        icon = Icons.receipt_long_outlined;
        iconBg = AppColors.secondaryContainer;
        iconColor = AppColors.secondary;
        break;
      default:
        icon = Icons.history_rounded;
        iconBg = AppColors.surfaceVariant;
        iconColor = AppColors.textPrimary;
    }

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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.doctorOrLab} • ${Formatters.formatDate(record.date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (record.diagnosis != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Clinical Note: ${record.diagnosis}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          if (record.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: record.tags.map((tag) {
                return Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.surfaceVariant,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
