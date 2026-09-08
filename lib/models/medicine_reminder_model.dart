class MedicineReminderModel {
  final String id;
  final String medicineName;
  final String dosage;
  final String frequency; // e.g. "Twice daily", "After meals"
  final String timeOfDay; // e.g. "08:00 AM", "08:00 PM"
  final DateTime startDate;
  final DateTime endDate;
  final bool isReminderActive;
  final String instructions;

  const MedicineReminderModel({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.timeOfDay,
    required this.startDate,
    required this.endDate,
    this.isReminderActive = true,
    required this.instructions,
  });

  factory MedicineReminderModel.fromJson(Map<String, dynamic> json) {
    return MedicineReminderModel(
      id: json['id']?.toString() ?? '0',
      medicineName: json['medicine_name'] ?? 'Medicine',
      dosage: json['dosage'] ?? '1 Tablet',
      frequency: json['frequency'] ?? 'Once daily',
      timeOfDay: json['time_of_day'] ?? '08:00 AM',
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      isReminderActive: json['is_active'] == true || json['is_active'] == 1,
      instructions: json['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicine_name': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'time_of_day': timeOfDay,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'is_active': isReminderActive,
      'instructions': instructions,
    };
  }

  MedicineReminderModel copyWith({
    String? id,
    String? medicineName,
    String? dosage,
    String? frequency,
    String? timeOfDay,
    DateTime? startDate,
    DateTime? endDate,
    bool? isReminderActive,
    String? instructions,
  }) {
    return MedicineReminderModel(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isReminderActive: isReminderActive ?? this.isReminderActive,
      instructions: instructions ?? this.instructions,
    );
  }
}

