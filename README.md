# SehatAI Pakistan — Phase 1: Mobile App Foundation + UI/UX

> **"When healthcare is far away, help shouldn't be."**  
> *جب صحت کی دیکھ بھال دور ہو، تو مدد دور نہیں ہونی چاہیے۔*

An AI-powered emergency healthcare mobile application engineered specifically for underserved and remote regions of Pakistan (e.g. Gilgit-Baltistan, Tharparkar, Khuzdar, Chitral, Swat, and rural districts).

---

## 🌟 Key Capabilities Implemented in Phase 1

### 1. 🆘 Dedicated Emergency Mode (Hero Feature)
- **Rapid Symptom Triage**: Interactive voice and text input with quick-select emergency indicators (*Chest pain & sweating*, *Difficulty breathing*, *Snake bite / Poison*, *Severe bleeding*).
- **Three-Tier AI Triage Risk States**:
  - 🟢 **LOW RISK**: Self-care tips, OTC guidelines, observation timeline.
  - 🟡 **MODERATE RISK**: Clinical precautions, tele-doctor consult recommended within 24 hours.
  - 🔴 **HIGH RISK**: Critical alert banner, 1-tap **Rescue 1122 dispatch simulation**, on-call emergency doctor instant routing, and live GPS clinic sharing.
- **Strict Medical Safety Disclaimer**: Complies with healthcare regulations — emphasizes preliminary triage rather than definitive medical diagnosis.

### 2. 🤖 Multilingual AI Health Assistant
- Interactive conversational AI assistant supporting:
  - **English**
  - **Roman Urdu** (*"Mujhe 2 din se bukhar hai"*)
  - **Urdu** (*"مجھے دو دن سے بخار ہے"*)
- Dynamic clinical analysis with risk indicators, follow-up suggestion chips, voice placeholder, and emergency escalation.

### 3. 👨‍⚕️ PMDC Verified Doctor Directory & Teleconsultation
- Filterable doctor database by specialty (General Physician, Emergency Medicine, Cardiology, Pediatrics, Gynecology) and online availability.
- Doctor detail profile with PMDC credentials, consultation fees in PKR, languages spoken, and institutional affiliations.
- Active Consultation room with patient history overview, triage score, WebRTC audio/video call placeholders, and encrypted live doctor chat.

### 4. 📄 AI Prescription Scanner (OCR) & 💊 My Medicines
- Camera & Gallery upload simulator for handwritten doctor prescriptions.
- Structured OCR extraction (Medicine name, dosage, frequency, duration, instructions) with mandatory user verification disclaimer.
- Medication manager with active dose schedules, frequencies, and SMS/push reminder toggles.

### 5. 📂 Digital Medical Records Timeline
- Organized health record categories: Medical History, Tele-Consultations, Prescriptions, Lab Reports (CBC, Dengue NS1), and Drug Allergies (e.g. Penicillin).

### 6. 👥 Complete Multi-Role Portal Architecture
- **Patient Experience**: Full 5-tab navigation (Home, AI Assistant, Doctors, Records, Profile).
- **Doctor Portal**: Morning overview, online/offline status toggle, priority triage queue, clinical patient medical file view with Accept/Decline actions.
- **Admin Command Portal**: Real-time KPI metrics (Patients, Verified Doctors, Pending Approvals, Emergency Alerts), PMDC doctor license verification queue.
- **Instant Role Switcher**: Built into the Profile screen and Auth flow for instant testing across all 3 roles.

---

## 📁 Project Architecture & Directory Structure

```
lib/
├── main.dart                          # App Entrypoint & Theme Config
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # Medical Blue, Teal, Emergency Red, Amber, Green
│   │   ├── app_strings.dart           # Localized Strings & Medical Disclaimers
│   │   └── app_typography.dart        # Clean Healthcare Typography Scale
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 Medical Theme
│   ├── utils/
│   │   ├── responsive.dart            # Responsive Breakpoints & Dimensions
│   │   └── formatters.dart            # PKR Currency, Date & Phone Formatters
│   └── widgets/
│       ├── app_button.dart            # Primary, Secondary, Outlined & Danger Buttons
│       ├── emergency_button.dart      # Pulsing SOS CTA Button
│       ├── app_card.dart              # Elevation & Rounded Card Component
│       ├── custom_text_field.dart     # Input Fields with Medical Icons & Validation
│       ├── risk_indicator_badge.dart  # Low / Moderate / High Risk Badges
│       ├── status_badge.dart          # PMDC Verified & Online Badges
│       ├── language_selector.dart     # English / Roman Urdu / Urdu Selector
│       ├── custom_app_bar.dart        # Header with SOS Shortcut
│       └── confirmation_dialog.dart   # Modals for Safety Confirmations
├── data/
│   ├── mock_patients.dart             # Realistic Remote Pakistani Demographic Data
│   ├── mock_doctors.dart              # PMDC Registered Doctors & Specialists
│   ├── mock_consultations.dart        # Active & Past Telehealth Sessions
│   ├── mock_prescriptions.dart        # OCR Extracted Prescriptions & Dosages
│   ├── mock_medicines.dart            # Scheduled Medication Reminders
│   ├── mock_medical_records.dart      # Categorized Patient Records & Lab Reports
│   └── mock_ai_responses.dart         # Multilingual Triage Dialogues
├── models/
│   ├── user_model.dart                # Patient, Doctor, Admin User Schemas
│   ├── doctor_model.dart              # Doctor Qualifications, PMDC & Availability
│   ├── triage_model.dart              # AI Triage & Risk Evaluation Schema
│   ├── consultation_model.dart        # Teleconsultation Session & Chat Messages
│   ├── prescription_model.dart        # Scanned Prescription Schema
│   ├── medicine_reminder_model.dart   # Dosage Timers & Frequency Schema
│   └── medical_record_model.dart      # Patient Medical Timeline Schema
├── services/
│   ├── navigation_service.dart        # Route Handling & State Switching
│   ├── mock_triage_service.dart       # Local Symptom Analyzer Engine
│   └── mock_data_service.dart         # State Repository Simulating Future Backend
└── features/
    ├── auth/                          # Splash, 3-Step Onboarding, Login, Register
    ├── patient/                       # Patient 5-Tab Wrapper & Home Dashboard
    ├── emergency/                     # "What is happening?", Voice & Triage Results
    ├── ai/                            # Multilingual AI Health Assistant Chat
    ├── doctors/                       # Filterable Doctor Directory & Profiles
    ├── consultation/                  # Active Telehealth Session & Doctor Chat
    ├── medical_records/               # Categorized History, Reports & Allergies
    ├── prescriptions/                 # Camera/Gallery OCR Prescription Scanner
    ├── medicines/                     # My Medicines List & Reminder Scheduler
    ├── profile/                       # Patient Profile & Live Role Switcher
    ├── doctor/                        # Doctor Portal Dashboard, Queue & Patient File
    └── admin/                         # Admin National Dashboard & PMDC Verifications
```

---

## 🚀 Recommended Phase 2 Integration Roadmap

When starting Phase 2, integrate in this exact logical order:

1. **PHP 8+ REST API & MySQL Database**:
   - Patient authentication (JWT / Bearer token).
   - Doctor verification registry with PMDC validation.
   - Medical records, prescriptions, and reminder sync.
2. **Gemini API Integration**:
   - Connect Gemini 1.5 Flash for low-latency multilingual Urdu / Roman Urdu / English symptom triage.
   - Prompt engineering with medical safety guardrails.
3. **WebRTC / Agora Video & Audio Calling**:
   - Real-time teleconsultation between patient and verified doctor.
4. **Rescue 1122 & Local Basic Health Unit (BHU) API**:
   - Geolocation-based ambulance dispatch integration.
