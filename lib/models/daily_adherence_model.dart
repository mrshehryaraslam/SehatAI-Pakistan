/// Model for the daily adherence response from GET /api/medicines/adherence.
class DailyAdherenceModel {
  final String date;
  final int totalActive;
  final int taken;
  final int missed;
  final int pending;
  final int adherencePercent;
  final List<MedicineIntakeStatus> medicines;

  const DailyAdherenceModel({
    required this.date,
    required this.totalActive,
    required this.taken,
    required this.missed,
    required this.pending,
    required this.adherencePercent,
    required this.medicines,
  });

  factory DailyAdherenceModel.fromJson(Map<String, dynamic> json) {
    final medsList = (json['medicines'] as List?)
            ?.map((m) => MedicineIntakeStatus.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    return DailyAdherenceModel(
      date: json['date']?.toString() ?? '',
      totalActive: (json['total_active'] as num?)?.toInt() ?? 0,
      taken: (json['taken'] as num?)?.toInt() ?? 0,
      missed: (json['missed'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      adherencePercent: (json['adherence_percent'] as num?)?.toInt() ?? 0,
      medicines: medsList,
    );
  }
}

/// Per-medicine intake status within a daily adherence response.
class MedicineIntakeStatus {
  final int reminderId;
  final String medicineName;
  final String dosage;
  final String frequency;
  final String timeOfDay;

  /// One of: 'taken', 'missed', 'pending'
  final String intakeStatus;

  const MedicineIntakeStatus({
    required this.reminderId,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.timeOfDay,
    required this.intakeStatus,
  });

  factory MedicineIntakeStatus.fromJson(Map<String, dynamic> json) {
    return MedicineIntakeStatus(
      reminderId: (json['reminder_id'] as num?)?.toInt() ?? 0,
      medicineName: json['medicine_name']?.toString() ?? 'Medicine',
      dosage: json['dosage']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      timeOfDay: json['time_of_day']?.toString() ?? '',
      intakeStatus: json['intake_status']?.toString() ?? 'pending',
    );
  }

  bool get isTaken => intakeStatus == 'taken';
  bool get isMissed => intakeStatus == 'missed';
  bool get isPending => intakeStatus == 'pending';
}
