import '../models/consultation_model.dart';
import '../models/triage_model.dart';
import '../core/widgets/risk_indicator_badge.dart';
import 'mock_patients.dart';
import 'mock_doctors.dart';

class MockConsultations {
  static List<ConsultationModel> sampleConsultations = [
    ConsultationModel(
      id: 'cons_201',
      patient: MockPatients.currentPatient,
      doctor: MockDoctors.doctors[0],
      symptoms: 'High fever, sore throat and dry cough for 3 days',
      status: ConsultationStatus.inProgress,
      requestedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      triageSummary: TriageModel(
        id: 'tr_101',
        riskLevel: TriageRiskLevel.moderate,
        primaryComplaint: 'Persistent fever (102°F) and productive cough',
        detectedSymptoms: [
          'Fever > 101°F',
          'Sore throat',
          'Mild chest discomfort',
          'Fatigue'
        ],
        generalGuidance:
            'Maintain strict hydration, rest, and isolate if viral respiratory symptoms worsen.',
        nextSteps:
            'Doctor consultation recommended within 24 hours to review throat infection.',
        emergencyAction:
            'If shortness of breath occurs, seek immediate emergency care.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
      ),
      chatMessages: [
        ChatMessageModel(
          id: 'm1',
          senderId: 'system',
          senderName: 'SehatAI Triage',
          isFromAi: true,
          message:
              '⚠️ SehatAI Preliminary Assessment: Moderate Risk level detected. Connected with Dr. Ayesha Siddiqui.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
          isEmergencyNotice: false,
        ),
        ChatMessageModel(
          id: 'm2',
          senderId: 'p_101',
          senderName: 'Ali Raza Khan',
          message: 'Assalam o Alaikum Doctor Sahiba. Mujhe 3 din se tez bukhar hai aur gala bohot dukh raha hai.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
        ),
        ChatMessageModel(
          id: 'm3',
          senderId: 'doc_1',
          senderName: 'Dr. Ayesha Siddiqui',
          isFromDoctor: true,
          message:
              'Wa Alaikum Assalam Ali. I have reviewed your AI triage summary. Have you checked your temperature with a thermometer, and do you have any difficulty swallowing water?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        ChatMessageModel(
          id: 'm4',
          senderId: 'p_101',
          senderName: 'Ali Raza Khan',
          message: 'Ji doctor, subha 102°F tha. Pani peete waqt thora dard hota hai.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
        ChatMessageModel(
          id: 'm5',
          senderId: 'doc_1',
          senderName: 'Dr. Ayesha Siddiqui',
          isFromDoctor: true,
          message:
              'Understood. Please keep taking Paracetamol 500mg (Panadol) after food, stay hydrated with warm fluids. I am sending an electronic prescription summary shortly.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
      ],
    ),
    ConsultationModel(
      id: 'cons_202',
      patient: MockPatients.samplePatients[1], // Zainab Bibi
      doctor: MockDoctors.doctors[1], // Dr. Bilal (Emergency)
      symptoms: 'Sudden acute abdominal pain and nausea in remote Thar area',
      status: ConsultationStatus.pending,
      requestedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      triageSummary: TriageModel(
        id: 'tr_102',
        riskLevel: TriageRiskLevel.high,
        primaryComplaint: 'Severe right lower quadrant abdominal pain',
        detectedSymptoms: [
          'Acute severe abdominal pain',
          'Nausea and vomiting',
          'Inability to stand straight'
        ],
        generalGuidance:
            'Potential acute surgical emergency (e.g. appendicitis). Do NOT administer solid food or laxatives.',
        nextSteps:
            'Immediate emergency evaluation required. Nearest rural health center notified.',
        emergencyAction:
            'Contact Rescue 1122 or local basic health unit ambulance immediately.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
        requiresImmediateDoctor: true,
      ),
    ),
  ];
}
