class PrescriptionItem {
  final String medicineName;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  const PrescriptionItem({
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      medicineName: json['medicine_name'] ?? json['name'] ?? 'Medicine',
      dosage: json['dosage'] ?? '1 Tablet',
      frequency: json['frequency'] ?? 'Once daily',
      duration: json['duration'] ?? '7 days',
      instructions: json['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine_name': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }
}

class PrescriptionModel {
  final String id;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime date;
  final List<PrescriptionItem> items;
  final bool isVerifiedByUser;
  final String? imageUrl;

  const PrescriptionModel({
    required this.id,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.date,
    required this.items,
    this.isVerifiedByUser = false,
    this.imageUrl,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? json['medicines'] as List? ?? [];
    return PrescriptionModel(
      id: json['id']?.toString() ?? '0',
      doctorName: json['doctor_name'] ?? 'Dr. Unknown',
      doctorSpecialty: json['doctor_specialty'] ?? json['doctor_speciality'] ?? 'General Medicine',
      date: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      items: rawItems.map((i) => PrescriptionItem.fromJson(i as Map<String, dynamic>)).toList(),
      isVerifiedByUser: json['is_verified'] == true || json['is_verified'] == 1,
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_name': doctorName,
      'doctor_specialty': doctorSpecialty,
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'is_verified': isVerifiedByUser,
      'image_url': imageUrl,
    };
  }
}

