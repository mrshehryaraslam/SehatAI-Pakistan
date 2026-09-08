enum RecordCategory {
  history,
  consultation,
  prescription,
  labReport,
  allergy,
  medication,
}

class MedicalRecordModel {
  final String id;
  final String title;
  final RecordCategory category;
  final DateTime date;
  final String doctorOrLab;
  final String description;
  final String? diagnosis;
  final List<String> tags;
  final String? attachmentUrl;

  const MedicalRecordModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.doctorOrLab,
    required this.description,
    this.diagnosis,
    this.tags = const [],
    this.attachmentUrl,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    RecordCategory cat = RecordCategory.consultation;
    final catStr = json['category']?.toString().toLowerCase();
    if (catStr == 'lab_report' || catStr == 'labreport') {
      cat = RecordCategory.labReport;
    } else if (catStr == 'prescription') {
      cat = RecordCategory.prescription;
    } else if (catStr == 'allergy') {
      cat = RecordCategory.allergy;
    } else if (catStr == 'history') {
      cat = RecordCategory.history;
    } else if (catStr == 'medication') {
      cat = RecordCategory.medication;
    }

    return MedicalRecordModel(
      id: json['id']?.toString() ?? '0',
      title: json['title'] ?? 'Medical Record',
      category: cat,
      date: DateTime.tryParse(json['date']?.toString() ?? json['record_date']?.toString() ?? '') ?? DateTime.now(),
      doctorOrLab: json['doctor_or_lab'] ?? 'SehatAI Health Facility',
      description: json['description'] ?? '',
      diagnosis: json['diagnosis']?.toString().isNotEmpty == true ? json['diagnosis'].toString() : null,
      tags: json['tags'] is List
          ? List<String>.from(json['tags'])
          : [json['category']?.toString() ?? 'Record'],
      attachmentUrl: json['attachment_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'date': date.toIso8601String().split('T').first,
      'doctor_or_lab': doctorOrLab,
      'description': description,
      'diagnosis': diagnosis,
      'tags': tags,
      'attachment_url': attachmentUrl,
    };
  }
}

