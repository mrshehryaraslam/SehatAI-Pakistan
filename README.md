# 🇵🇰 SehatAI Pakistan

> **"When healthcare is far away, help shouldn't be."**
> *جب صحت کی دیکھ بھال دور ہو، تو مدد دور نہیں ہونی چاہیے۔*

**SehatAI Pakistan** is an AI-powered healthcare and emergency assistance platform designed specifically for Pakistan, with a focus on underserved, remote, and low-access communities.

The platform combines **AI-powered symptom triage, multilingual health assistance, doctor consultation, emergency assistance, digital medical records, prescriptions, medication management, and role-based healthcare portals** into one integrated ecosystem.

The project is being engineered with a **Flutter mobile application, PHP REST API, MySQL database, and Google Gemini AI**.

---

## 🌟 Project Overview

Access to qualified healthcare can be difficult in many remote and underserved regions of Pakistan, including areas such as:

* Gilgit-Baltistan
* Tharparkar
* Khuzdar
* Chitral
* Swat
* Rural Punjab
* Rural Sindh
* Rural Balochistan
* Other underserved districts

SehatAI Pakistan aims to provide a digital first point of assistance by allowing users to:

* Describe their symptoms in natural language
* Receive preliminary AI-powered triage
* Understand the urgency of their situation
* Find suitable doctors
* Request teleconsultation
* Maintain digital medical records
* Manage prescriptions and medicines
* Trigger emergency assistance
* Communicate with healthcare professionals

> ⚠️ **Medical Safety Disclaimer:** SehatAI Pakistan is designed for preliminary health assistance and triage. It is not intended to replace a qualified medical professional, emergency department, or official emergency service. AI-generated information should not be considered a definitive medical diagnosis.

---

# 🚀 Current Technology Stack

## Mobile Application

* **Flutter**
* Dart
* Material 3
* Responsive mobile UI
* REST API integration
* HTTPS communication
* JWT/Bearer authentication
* Local session persistence

## Backend

* **PHP 8+**
* REST API architecture
* JWT/Bearer authentication
* Controller-based API structure
* Central API router
* CORS handling
* Environment configuration
* Secure API responses

## Database

* **MySQL**
* Relational healthcare data model
* Patient records
* Doctor records
* Consultations
* Chat messages
* Prescriptions
* Medicines
* Medical records
* Emergency logs
* Administrative data

## Artificial Intelligence

* **Google Gemini API**
* Multilingual health assistance
* AI symptom triage
* Patient brief generation
* AI care-plan generation
* English
* Roman Urdu
* Urdu

## Development Environment

* Flutter SDK
* PHP 8+
* MySQL
* XAMPP
* Android Studio / compatible Flutter development environment
* Git & GitHub

---

# 🏗️ System Architecture

```text
┌───────────────────────────────────────────────┐
│              SehatAI Pakistan                 │
│             Flutter Mobile App               │
└───────────────────────┬───────────────────────┘
                        │
                        │ HTTPS / REST API
                        ▼
┌───────────────────────────────────────────────┐
│                 PHP 8+ API                    │
│                                               │
│  Authentication                               │
│  Doctors                                      │
│  Consultations                                │
│  Chat                                          │
│  Medicines                                    │
│  Prescriptions                                │
│  Medical Records                              │
│  Emergency                                    │
│  Administration                               │
│  AI / Health Continuity                       │
└───────────────┬───────────────────┬───────────┘
                │                   │
                ▼                   ▼
       ┌────────────────┐   ┌──────────────────┐
       │     MySQL      │   │  Google Gemini   │
       │    Database    │   │       API        │
       └────────────────┘   └──────────────────┘
```

---

# 📱 Mobile Application Features

## 1. 🆘 Emergency Mode

Emergency Mode is one of the core features of SehatAI Pakistan.

Users can quickly describe emergency symptoms through text-based interaction and select common emergency indicators such as:

* Chest pain and sweating
* Difficulty breathing
* Snake bite / poisoning
* Severe bleeding
* Other critical symptoms

The system supports three preliminary risk levels:

### 🟢 LOW RISK

Provides:

* General self-care guidance
* Observation recommendations
* Appropriate precautions
* Safety disclaimer

### 🟡 MODERATE RISK

Provides:

* Clinical precautions
* Recommendation to consult a doctor
* Follow-up guidance
* Escalation recommendations when symptoms worsen

### 🔴 HIGH RISK

Provides:

* Critical warning
* Emergency escalation
* Rescue 1122 assistance workflow
* Emergency doctor routing
* Location/clinic assistance where supported

> Emergency functionality is designed as an assistance and escalation system and does not replace official emergency services.

---

# 🤖 2. AI Health Assistant

SehatAI includes an AI-powered conversational health assistant powered by Google Gemini.

Users can communicate naturally in:

* English
* Roman Urdu
* Urdu

Example:

```text
English:
"I have had fever for two days."

Roman Urdu:
"Mujhe 2 din se bukhar hai."

Urdu:
"مجھے دو دن سے بخار ہے۔"
```

The AI assistant can provide:

* Preliminary symptom understanding
* Risk indicators
* Follow-up questions
* General health guidance
* Emergency escalation
* Doctor consultation recommendations

The AI system is designed with medical-safety constraints and should not be treated as a diagnostic authority.

---

# 👨‍⚕️ 3. Doctor Directory & Teleconsultation

The platform includes a doctor discovery and consultation system.

Users can search and filter doctors by:

* General Physician
* Emergency Medicine
* Cardiology
* Pediatrics
* Gynecology
* Availability
* Specialty

Doctor profiles can include:

* Doctor name
* Specialty
* PMDC information
* Qualifications
* Languages
* Consultation fee
* Institution/affiliation
* Online availability
* Verification status

Patients can request consultations with available doctors.

---

# 💬 4. Doctor Consultation & Chat

The consultation system supports the healthcare communication workflow.

A consultation can contain:

```text
Patient
   ↓
Consultation Request
   ↓
Doctor Review
   ↓
Accept / Reject
   ↓
Consultation
   ↓
Secure Chat
   ↓
Prescription / Medical Record
```

The consultation architecture supports:

* Patient history overview
* AI triage information
* Consultation status
* Doctor acceptance/rejection
* Patient-doctor chat
* Prescription generation
* Consultation history

Video/audio calling architecture can be extended through a suitable WebRTC/telemedicine provider.

---

# 📄 5. AI Prescription Scanner

The application includes a prescription scanning workflow.

Users can upload/capture prescription images through:

* Camera
* Gallery

The system is designed to extract structured information such as:

* Medicine name
* Dosage
* Frequency
* Duration
* Instructions

Example:

```text
Medicine:
Paracetamol

Dosage:
500 mg

Frequency:
2 times daily

Duration:
3 days
```

All extracted prescription information must be verified by the user/qualified professional before being relied upon.

---

# 💊 6. My Medicines

Users can manage their medications through the medicine management module.

Features include:

* Active medicines
* Dosage
* Frequency
* Duration
* Intake tracking
* Medication reminders
* Reminder status
* Adherence information

---

# 📂 7. Digital Medical Records

SehatAI provides a centralized medical record timeline.

Supported record categories include:

* Medical history
* Teleconsultations
* Prescriptions
* Laboratory reports
* Allergies
* Other healthcare documents

Example:

```text
Medical Record Timeline
│
├── Medical History
├── Consultation
├── Prescription
├── Lab Report
└── Allergy Information
```

This allows the patient's healthcare information to be organized in one place.

---

# 🚑 8. Emergency & SOS System

The backend provides dedicated emergency APIs for handling SOS events and emergency alerts.

The emergency system is designed to support:

* SOS logging
* Emergency alerts
* Emergency status updates
* Patient emergency information
* Emergency escalation workflow

Future integrations can include official emergency-service APIs and location-aware healthcare facilities where technically and legally available.

---

# 🧠 9. Health Continuity Engine

SehatAI includes a Health Continuity Engine designed to maintain continuity between patient interactions.

The backend supports AI-generated:

### Patient Brief

A structured summary of relevant patient information for healthcare workflows.

### AI Care Plan

A structured care-plan generation workflow based on available patient information and consultation context.

Available API routes include:

```text
POST /ai/patient-brief
GET  /ai/patient-brief/{id}

POST /ai/care-plan
GET  /ai/care-plan/{id}
```

---

# 🔐 10. Authentication & Security

The backend uses an API-oriented authentication architecture.

Security-related components include:

* JWT/Bearer authentication
* Protected API endpoints
* Role-based access
* Environment-based secrets
* CORS handling
* HTTPS production API
* Server-side validation
* Database access controls

Sensitive configuration such as API keys should never be committed to the public repository.

---

# 👥 11. Multi-Role Architecture

SehatAI supports three primary user roles.

## 👤 Patient

Patient functionality includes:

* Home
* AI Assistant
* Doctors
* Medical Records
* Profile
* Emergency
* Consultations
* Prescriptions
* Medicines

## 👨‍⚕️ Doctor

Doctor functionality includes:

* Doctor dashboard
* Online/offline status
* Consultation queue
* Patient information
* AI triage information
* Accept/reject consultation
* Patient chat
* Prescription workflow

## 🛡️ Administrator

Administrative functionality includes:

* Platform metrics
* Patient statistics
* Doctor management
* Doctor verification
* Emergency logs
* Emergency alert management
* Platform monitoring

---

# 🌐 Production API

The backend API has been deployed to:

```text
https://sehataipakistan.xo.je/api/
```

Health endpoint:

```text
https://sehataipakistan.xo.je/api/health
```

The production health endpoint confirms that the API engine is operational and that the Google Gemini API configuration can be detected.

Example health response:

```json
{
    "status": "success",
    "message": "SehatAI Pakistan Healthcare REST API Engine is active.",
    "data": {
        "name": "SehatAI Pakistan API",
        "version": "2.0.0",
        "status": "operational",
        "gemini_api_key_configured": true,
        "ai_engine": "google_gemini_api"
    }
}
```

---

# 🔌 API Modules

The current backend architecture contains API modules for:

```text
/auth
/doctors
/consultations
/medicines
/prescriptions
/records
/emergency
/admin
/ai
```

Examples:

```text
POST /auth/register
POST /auth/login
GET  /auth/me

GET  /doctors
GET  /doctors/{id}

POST /consultations/request
GET  /consultations/patient
GET  /consultations/doctor

GET  /medicines
POST /medicines

GET  /prescriptions
POST /prescriptions

GET  /records
POST /records

POST /emergency/sos
GET  /emergency/alerts

GET  /admin/metrics
GET  /admin/doctors

POST /ai/triage
POST /ai/patient-brief
POST /ai/care-plan
```

> POST endpoints must be tested using an HTTP client or the Flutter application. Opening a POST endpoint directly in a browser sends a GET request and will correctly return a route-not-found response.

---

# 📁 Project Structure

```text
SehatAI-Pakistan/
│
├── android/
├── ios/
├── lib/
│   │
│   ├── main.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   │
│   ├── data/
│   ├── models/
│   ├── services/
│   │
│   └── features/
│       ├── auth/
│       ├── patient/
│       ├── emergency/
│       ├── ai/
│       ├── doctors/
│       ├── consultation/
│       ├── medical_records/
│       ├── prescriptions/
│       ├── medicines/
│       ├── profile/
│       ├── doctor/
│       └── admin/
│
├── pubspec.yaml
├── README.md
└── ...
```

---

# 🛠️ Backend Structure

The PHP API follows a modular controller-based architecture.

```text
api/
│
├── index.php
│
├── config/
│   ├── cors.php
│   ├── env_loader.php
│   ├── constants.php
│   └── ...
│
├── controllers/
│   ├── AuthController.php
│   ├── DoctorController.php
│   ├── ConsultationController.php
│   ├── ChatController.php
│   ├── MedicineController.php
│   ├── PrescriptionController.php
│   ├── MedicalRecordController.php
│   ├── EmergencyController.php
│   ├── AdminController.php
│   ├── AiController.php
│   └── HealthContinuityController.php
│
├── models/
├── utils/
├── middleware/
└── ...
```

---

# 🧪 Testing

The project is currently undergoing integration and production-readiness testing.

Testing covers:

### Backend

* API health check
* Authentication
* Database connectivity
* Doctor APIs
* Consultation APIs
* Medicine APIs
* Prescription APIs
* Medical record APIs
* Emergency APIs
* Admin APIs
* Gemini API integration
* AI triage
* Health Continuity Engine

### Mobile

* Authentication flow
* Patient portal
* Doctor portal
* Admin portal
* API connectivity
* AI assistant
* Emergency workflow
* Consultation workflow
* Medical records
* Prescriptions
* Medicines

---

# 📦 Release Build

The Flutter application is being prepared for release APK testing.

Release build command:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The generated APK will be used for real-device testing against the production API.

Before final release, the following must be verified:

* Production HTTPS API
* Authentication
* JWT/session persistence
* Gemini AI requests
* Database operations
* Doctor workflows
* Patient workflows
* Emergency workflow
* API error handling
* Network failure handling
* Android permissions
* Release configuration
* Security configuration

---

# 🔒 Security Notes

Never commit the following to GitHub:

```text
.env
Gemini API keys
Database passwords
JWT secrets
Private credentials
Production secrets
```

Production secrets must remain on the server/environment configuration.

The Flutter application should never contain a private Gemini API key.

AI requests should be routed through the secure backend:

```text
Flutter
   ↓
PHP API
   ↓
Gemini API
```

---

# 🗺️ Future Development

Future versions may include:

* Real-time WebRTC video consultation
* Voice-based AI interaction
* Improved Urdu voice support
* OCR improvements
* Official emergency service integration
* Location-aware hospital/BHU discovery
* Push notifications
* Advanced medication reminders
* Health analytics
* Doctor availability scheduling
* Laboratory integration
* Hospital integration
* Offline-first emergency functionality
* Expanded healthcare provider network

---

# 📊 Project Status

| Component                  | Status                   |
| -------------------------- | ------------------------ |
| Flutter Mobile Application | 🟢 Implemented           |
| Patient Portal             | 🟢 Implemented           |
| Doctor Portal              | 🟢 Implemented           |
| Admin Portal               | 🟢 Implemented           |
| PHP REST API               | 🟢 Implemented           |
| MySQL Database             | 🟢 Implemented           |
| Authentication             | 🟢 Implemented           |
| Doctor Management          | 🟢 Implemented           |
| Consultation System        | 🟢 Implemented           |
| Chat System                | 🟢 Implemented           |
| Medical Records            | 🟢 Implemented           |
| Prescription System        | 🟢 Implemented           |
| Medicine Management        | 🟢 Implemented           |
| Emergency/SOS APIs         | 🟢 Implemented           |
| Gemini API Configuration   | 🟢 Configured            |
| AI Triage                  | 🟡 Integration Testing   |
| Health Continuity Engine   | 🟡 Integration Testing   |
| Production API             | 🟢 Deployed              |
| Release APK                | 🟡 Preparation / Testing |
| Play Store Release         | ⚪ Not Released           |

---

# ⚠️ Current Development Status

**Important:** The project is currently in the **testing and integration stage**.

The backend API has been deployed and the production API is accessible through HTTPS. Google Gemini API configuration has also been completed.

However, **the application is currently being tested primarily in the local development/testing environment**, and the release APK is still undergoing final integration and real-device testing.

The project should **not yet be considered a fully production-certified healthcare application**.

Before public release, extensive functional, security, performance, medical-safety, and real-device testing is required.

---

# 🇵🇰 Vision

SehatAI Pakistan aims to use modern AI and mobile technology to reduce the distance between people and healthcare.

The goal is simple:

> **When healthcare is far away, help shouldn't be.**

SehatAI Pakistan is being developed as a technology platform to support patients, doctors, and emergency healthcare workflows across Pakistan.

---

# 👨‍💻 Project

**SehatAI Pakistan**

AI-Powered Healthcare & Emergency Assistance Platform

Built with:

```text
Flutter
PHP 8+
MySQL
Google Gemini AI
REST API
JWT Authentication
```

**Current Status:** 🟡 Local Hosting & Testing Ai healt Chat bot

**Release APK:** 🟡 Final integration and testing in progress
