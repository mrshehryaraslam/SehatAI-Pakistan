class MockAiConversation {
  final String userQuery;
  final String aiResponse;
  final String language;
  final String riskCategory;
  final List<String> suggestions;

  const MockAiConversation({
    required this.userQuery,
    required this.aiResponse,
    required this.language,
    required this.riskCategory,
    this.suggestions = const [],
  });
}

class MockAiResponses {
  static const List<MockAiConversation> sampleConversations = [
    MockAiConversation(
      userQuery: 'Mujhe 2 din se tez bukhar hai aur sar mein dard hai.',
      aiResponse:
          'Aap ke bataye hue symptoms (tez bukhar aur shadeed sar dard) viral infection ya bacterial pharyngitis ki nishani ho sakte hain.\n\n'
          '⚠️ **Fori Hidayat:**\n'
          '1. Bukhar kam karne ke liye Paracetamol (Panadol) le sakte hain.\n'
          '2. Pani, soup aur garam fluids ka kasrat se istemal karein.\n'
          '3. Agar bukhar 102°F se upar jaye ya gardan mein akad mahsoos ho to foran doctor se rujoo karein.\n\n'
          'SehatAI Risk Level: **MODERATE RISK**\n'
          'Kiya aap online doctor se mashwara karna chahte hain?',
      language: 'Roman Urdu',
      riskCategory: 'moderate',
      suggestions: [
        'Doctor se mashwara karein',
        'Bukhar kam karne ke gharelu totkay',
        'Dengue ke symptoms kya hain?'
      ],
    ),
    MockAiConversation(
      userQuery: 'I have severe chest pain radiating to my left arm and sweating.',
      aiResponse:
          '🚨 **CRITICAL WARNING: HIGH RISK DETECTED**\n\n'
          'Chest pain radiating to the left arm with profuse sweating are classic warning indicators of a potential cardiac emergency (such as Acute Coronary Syndrome / Heart Attack).\n\n'
          '**IMMEDIATE ACTIONS:**\n'
          '1. Stop all physical activity and sit in a comfortable upright position.\n'
          '2. Call Rescue 1122 or have someone drive you to the nearest emergency hospital immediately.\n'
          '3. If advised by a physician and not allergic, chew one Aspirin 300mg / Disprin tablet.\n\n'
          'SehatAI does NOT replace emergency emergency services. Please tap the red Emergency button below.',
      language: 'English',
      riskCategory: 'high',
      suggestions: [
        'Call Rescue 1122',
        'Connect Emergency Doctor',
        'Share Current GPS Location'
      ],
    ),
    MockAiConversation(
      userQuery: 'مجھے پچھلے دو گھنٹوں سے سینے میں شدید درد اور سانس لینے میں دشواری ہو رہی ہے۔',
      aiResponse:
          '🚨 **اہم تنبیہ: ہنگامی طبی صورتحال (High Risk)**\n\n'
          'سینے میں شدید درد اور سانس کی تنگی فوری ہنگامی طبی امداد کی متقاضی ہے۔ یہ دل کے عارضے کی علامت ہو سکتی ہے۔\n\n'
          '**فوری اقدامات:**\n'
          '۱. فوری طور پر ایمبولینس (1122) کو کال کریں یا قریبی ایمرجنسی ہسپتال جائیں۔\n'
          '۲. آرام دہ حالت میں ٹیک لگا کر بیٹھ جائیں۔\n'
          '۳. غیر ضروری گھبراہٹ سے بچیں اور کسی فرد کو اپنے پاس رکھیں۔',
      language: 'Urdu',
      riskCategory: 'high',
      suggestions: [
        'ایمرجنسی کال کریں',
        'قریبی ہسپتال تلاش کریں',
        'ڈاکٹر سے رابطہ کریں'
      ],
    ),
    MockAiConversation(
      userQuery: 'Khana khane ke baad seene mein jalan hoti hai aur acid banta hai.',
      aiResponse:
          'Ye symptoms GERD (Acid Reflux / Heartburn) ki taraf ishara karte hain.\n\n'
          '**Mamooli Hidayat:**\n'
          '1. Khane ke foran baad letne se guraiz karein, 2-3 ghante seedhe baithain.\n'
          '2. Teekhi, tali hui aur masala-daar ghizaon se parhez karein.\n'
          '3. Thora thora kar ke khana khayein.\n\n'
          'SehatAI Risk Level: **LOW RISK**\n'
          'Agar jalan musalsal rahe to kisi General Physician se mashwara le sakte hain.',
      language: 'Roman Urdu',
      riskCategory: 'low',
      suggestions: [
        'Acid reflux ke parhez',
        'Antacid tablet ki maloomat',
        'Diet plan dekhein'
      ],
    ),
  ];

  // =================================================================
  // Health Continuity Engine — Mock Data for Offline Fallbacks
  // =================================================================

  /// Mock AI Patient Brief (offline template fallback)
  static const Map<String, dynamic> mockPatientBrief = {
    'brief_text':
        '**Patient Brief (Offline)**\n\n'
        '• **Chief Complaint:** Fever with body aches for 3 days\n'
        '• **AI Risk Level:** MODERATE\n'
        '• **Allergies:** None known\n'
        '• **Chronic Conditions:** None reported\n'
        '• **Active Medications:** None on record\n\n'
        '**Suggested Focus:** Review presenting symptoms, check for infection markers, '
        'assess hydration status.',
    'structured_data': {
      'chief_complaint': 'Fever with body aches for 3 days',
      'symptom_timeline': 'Symptoms present for approximately 3 days',
      'risk_factors': ['Moderate risk triage', 'No chronic conditions'],
      'relevant_history': 'No recent medical records on file',
      'current_medications_summary': 'No active medications on record',
      'allergies_and_contraindications': 'None known',
      'ai_triage_assessment': 'Risk: MODERATE — Viral infection suspected',
      'suggested_focus_areas': [
        'Review presenting symptoms',
        'Check for infection markers',
        'Assess hydration status',
      ],
    },
  };

  /// Mock AI Care Plan (offline template fallback)
  static const Map<String, dynamic> mockCarePlan = {
    'care_plan_text':
        '# Your Care Plan\n\n'
        '## Medicines\n'
        '- **Paracetamol 500mg**: Take 1 tablet every 6 hours for fever\n'
        '- **ORS Sachets**: Mix in 1 litre water, sip throughout the day\n\n'
        '## Warning Signs\n'
        '- If fever persists beyond 3 days, contact your doctor\n'
        '- If symptoms worsen, seek immediate advice\n'
        '- 🚨 If you experience chest pain, severe breathing difficulty — contact Rescue 1122\n\n'
        '## Lifestyle\n'
        '- Rest and hydrate well\n'
        '- Monitor temperature every 4-6 hours\n\n'
        '## Follow-up: 7 days',
    'structured_data': {
      'medication_guidance': [
        {
          'medicine': 'Paracetamol 500mg',
          'how_to_take': 'Take 1 tablet every 6 hours with water, after meals',
          'side_effects_watch': 'Rare: skin rash, nausea. Stop and consult doctor if occurs.',
        },
        {
          'medicine': 'ORS Sachets',
          'how_to_take': 'Mix 1 sachet in 1 litre of boiled/cooled water. Sip throughout the day.',
          'side_effects_watch': 'Generally safe. If vomiting increases, consult doctor.',
        },
      ],
      'warning_signs': [
        'If fever persists beyond 3 days, contact your doctor',
        'If symptoms worsen or new symptoms appear, seek immediate advice',
        '🚨 If you experience chest pain, severe breathing difficulty, unconsciousness — contact Rescue 1122 immediately.',
      ],
      'lifestyle_recommendations': [
        'Get adequate rest and maintain balanced nutrition',
        'Increase fluid intake (water, ORS, warm soups)',
        'Avoid cold drinks and oily foods',
      ],
      'home_monitoring': [
        'Record body temperature every 4-6 hours',
        'Note any changes in symptoms or new symptoms',
      ],
    },
    'follow_up_date': '2026-09-09',
  };
}
