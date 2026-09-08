import '../models/medical_record_model.dart';

class MockMedicalRecords {
  static final List<MedicalRecordModel> sampleRecords = [
    MedicalRecordModel(
      id: 'rec_1',
      title: 'Complete Blood Count (CBC) & Dengue NS1',
      category: RecordCategory.labReport,
      date: DateTime.now().subtract(const Duration(days: 3)),
      doctorOrLab: 'Chughtai Lab - Gilgit Branch',
      description: 'Platelets count: 185,000 /uL (Normal), Dengue NS1 Antigen: Negative. Mild leukocytosis observed.',
      diagnosis: 'Viral Upper Respiratory Infection',
      tags: ['CBC', 'Dengue Negative', 'Blood Test'],
    ),
    MedicalRecordModel(
      id: 'rec_2',
      title: 'Telemedicine Consultation Summary',
      category: RecordCategory.consultation,
      date: DateTime.now().subtract(const Duration(days: 3)),
      doctorOrLab: 'Dr. Ayesha Siddiqui (Internal Med)',
      description: 'Patient presented with acute pharyngitis and febrile illness. Prescribed Augmentin and symptomatic relief.',
      diagnosis: 'Acute Bacterial Pharyngitis',
      tags: ['Telehealth', 'Prescription Issued'],
    ),
    MedicalRecordModel(
      id: 'rec_3',
      title: 'Penicillin Allergy Warning',
      category: RecordCategory.allergy,
      date: DateTime.now().subtract(const Duration(days: 120)),
      doctorOrLab: 'Civil Hospital Gilgit',
      description: 'Patient developed mild urticaria and skin itching after Ampicillin injection 2 years ago. Penicillin derivatives flagged.',
      diagnosis: 'Drug Hypersensitivity',
      tags: ['Allergy Alert', 'Penicillin'],
    ),
    MedicalRecordModel(
      id: 'rec_4',
      title: 'ECG & Cardiology Checkup',
      category: RecordCategory.history,
      date: DateTime.now().subtract(const Duration(days: 90)),
      doctorOrLab: 'Dr. Farhan Qureshi (NICVD)',
      description: 'Routine resting 12-lead ECG normal sinus rhythm. Blood pressure controlled at 125/80 mmHg.',
      diagnosis: 'Stage 1 Essential Hypertension (Well Controlled)',
      tags: ['Cardiology', 'ECG', 'Hypertension'],
    ),
    MedicalRecordModel(
      id: 'rec_5',
      title: 'Chest X-Ray (PA View)',
      category: RecordCategory.labReport,
      date: DateTime.now().subtract(const Duration(days: 180)),
      doctorOrLab: 'Aga Khan Diagnostic Center',
      description: 'Lungs are clear of active infiltrates, consolidation or pleural effusion. Normal cardiothoracic ratio.',
      diagnosis: 'Clear Lung Fields',
      tags: ['Radiology', 'X-Ray'],
    ),
  ];
}
