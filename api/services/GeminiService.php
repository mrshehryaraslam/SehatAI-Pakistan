<?php
/**
 * SehatAI Pakistan - Google Gemini Multilingual Medical Triage Service
 * 
 * Communicates with Google Gemini API for medical symptom assessment in English,
 * Urdu, and Roman Urdu with strict clinical safety guardrails, contextual patient
 * profile framing, multi-turn conversation memory, and emergency escalation.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/constants.php';

class GeminiService {
    private string $apiKey;
    private string $model;
    private const BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models/';

    public function __construct(?string $apiKey = null, ?string $model = null) {
        $this->apiKey = $apiKey ?? (defined('GEMINI_API_KEY') ? GEMINI_API_KEY : '');
        $this->model = $model ?? (defined('GEMINI_MODEL') ? GEMINI_MODEL : 'gemini-3.5-flash');
    }

    /**
     * Perform triage analysis on user message with history and patient context.
     *
     * @param string $userMessage The current query / symptom description.
     * @param string $language 'english', 'urdu', or 'roman_urdu'.
     * @param array $history Previous messages: [['role' => 'user'|'model', 'message' => '...']]
     * @param array|null $patientProfile Optional: ['age' => ..., 'gender' => ..., 'allergies' => ..., 'chronic_conditions' => ...]
     * @return array Standardized structured triage data.
     */
    public function triage(
        string $userMessage,
        string $language = 'roman_urdu',
        array $history = [],
        ?array $patientProfile = null
    ): array {
        // If no API key is provided or Gemini call fails, use intelligent local clinical triage
        if (empty($this->apiKey)) {
            $fallback = $this->generateLocalRuleBasedTriage($userMessage, $language, $patientProfile);
            $fallback['_source'] = 'offline_rule_engine';
            return $this->applyEmergencySafetyNet($userMessage, $fallback, $language);
        }

        try {
            $geminiResponse = $this->callGeminiApi($userMessage, $language, $history, $patientProfile);
            if ($geminiResponse !== null) {
                $geminiResponse['_source'] = 'google_gemini_api';
                return $this->applyEmergencySafetyNet($userMessage, $geminiResponse, $language);
            }
        } catch (Throwable $e) {
            error_log('[GeminiService] API Exception: ' . $e->getMessage());
        }

        // Fallback to local rule engine if API threw error
        $fallback = $this->generateLocalRuleBasedTriage($userMessage, $language, $patientProfile);
        $fallback['_source'] = 'offline_rule_engine_fallback';
        return $this->applyEmergencySafetyNet($userMessage, $fallback, $language);
    }

    /**
     * Make HTTP REST request to Google Gemini API with retry logic.
     */
    private function callGeminiApi(
        string $userMessage,
        string $language,
        array $history,
        ?array $patientProfile
    ): ?array {
        $endpoint = self::BASE_URL . $this->model . ':generateContent?key=' . urlencode($this->apiKey);

        $systemInstruction = $this->buildSystemInstruction($language, $patientProfile);
        $contents = $this->buildContentsPayload($userMessage, $history);

        $payload = [
            'system_instruction' => [
                'parts' => [
                    ['text' => $systemInstruction]
                ]
            ],
            'contents' => $contents,
            'generationConfig' => [
                'temperature' => 0.2,
                'topP' => 0.8,
                'maxOutputTokens' => 2048,
                'responseMimeType' => 'application/json',
            ]
        ];

        $maxRetries = 2;
        for ($attempt = 0; $attempt <= $maxRetries; $attempt++) {
            $ch = curl_init($endpoint);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST => true,
                CURLOPT_HTTPHEADER => [
                    'Content-Type: application/json; charset=utf-8',
                    'Accept: application/json'
                ],
                CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_UNICODE),
                CURLOPT_TIMEOUT => 30,
                CURLOPT_CONNECTTIMEOUT => 10,
                CURLOPT_SSL_VERIFYPEER => false, // For local XAMPP SSL bundle compatibility
                CURLOPT_SSL_VERIFYHOST => 0,
            ]);

            $responseBody = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $curlError = curl_error($ch);
            curl_close($ch);

            if (!empty($curlError)) {
                error_log("[GeminiService] cURL error (attempt {$attempt}): {$curlError}");
                if ($attempt < $maxRetries) {
                    sleep(2);
                    continue;
                }
                return null;
            }

            // Retry on transient errors: 429 (rate limit), 503 (service unavailable)
            if (($httpCode === 429 || $httpCode === 503) && $attempt < $maxRetries) {
                $retryDelay = $httpCode === 429 ? 5 : 2;
                error_log("[GeminiService] HTTP {$httpCode}, retrying in {$retryDelay}s (attempt {$attempt})");
                sleep($retryDelay);
                continue;
            }

            if ($httpCode < 200 || $httpCode >= 300 || empty($responseBody)) {
                error_log("[GeminiService] Gemini API HTTP {$httpCode}: {$responseBody}");
                return null;
            }

            $decoded = json_decode($responseBody, true);
            $rawText = $decoded['candidates'][0]['content']['parts'][0]['text'] ?? null;

            if (empty($rawText)) {
                return null;
            }

            return $this->parseAndValidateJsonResponse($rawText, $language);
        }

        return null;
    }

    /**
     * Build system instruction prompt with Pakistan healthcare guidelines.
     */
    private function buildSystemInstruction(string $language, ?array $patientProfile): string {
        $patientContextStr = "No prior patient profile provided.";
        if ($patientProfile && !empty(array_filter($patientProfile))) {
            $parts = [];
            if (!empty($patientProfile['age'])) $parts[] = "Age: " . $patientProfile['age'];
            if (!empty($patientProfile['gender'])) $parts[] = "Gender: " . $patientProfile['gender'];
            if (!empty($patientProfile['allergies'])) $parts[] = "Known Allergies: " . $patientProfile['allergies'];
            if (!empty($patientProfile['chronic_conditions'])) $parts[] = "Chronic Conditions: " . $patientProfile['chronic_conditions'];
            if (!empty($patientProfile['city'])) $parts[] = "City/Region: " . $patientProfile['city'] . ", Pakistan";
            $patientContextStr = implode(", ", $parts);
        }

        $langDirective = match(strtolower($language)) {
            'urdu', 'ur' => 'Respond in standard Urdu script (اردو). Use polite, reassuring medical Urdu vocabulary.',
            'roman_urdu', 'roman-urdu', 'ur_roman' => 'Respond in Roman Urdu (Urdu written in Latin English alphabet, e.g. "Aap ko bukhar hai to paani zyada piyein aur aaram karein"). Ensure clear, colloquial, respectful tone.',
            default => 'Respond in clear, empathetic professional English tailored for Pakistani patients.'
        };

        return <<<PROMPT
You are SehatAI, an empathetic, highly knowledgeable medical triage AI assistant specifically built for healthcare in Pakistan.

PATIENT PROFILE CONTEXT:
{$patientContextStr}

LANGUAGE REQUIREMENT:
{$langDirective}

STRICT CLINICAL SAFETY RULES:
1. You provide PRELIMINARY MEDICAL GUIDANCE & TRIAGE ONLY. You must NEVER give a definitive clinical diagnosis or prescribe restricted prescription-only medications.
2. Maintain active conversation context. If the user mentions new symptoms, analyze them alongside previous statements.
3. EMERGENCY DETECTION:
   - If red-flag symptoms are present (crushing chest pain, left arm pain, severe shortness of breath, severe head trauma, poison ingestion, snake bite, acute paralysis/facial droop, unconsciousness, severe unstopped bleeding, high fever with stiff neck or seizures), classify risk_level as "high", set requires_doctor to true, and provide an immediate emergency_warning advising to contact Rescue 1122 or rush to the nearest emergency ward.
4. MODERATE RISK:
   - For persistent fever, productive cough, moderate abdominal pain, vomiting, or symptoms lasting several days, classify risk_level as "moderate", set requires_doctor to true, recommend consulting a PMDC-registered doctor within 24 hours, and provide supportive home care advice (hydration, rest, ORS).
5. LOW RISK:
   - For mild self-limiting issues (mild cold, occasional headache, fatigue, minor scrapes), classify risk_level as "low", set requires_doctor to false, and provide safe home care and monitoring guidance.
6. CULTURAL RELEVANCE:
   - Mention relevant Pakistani healthcare context where applicable (Rescue 1122 for emergencies, PMDC registered doctors, hydration/ORS for dehydration, boiled water).
7. OUTPUT FORMAT:
   - You MUST output ONLY a valid JSON object with EXACTLY these keys:
   {
     "reply": "Empathetic conversational response in the requested language with structured bullets for guidance",
     "detected_symptoms": ["list", "of", "detected", "symptoms"],
     "risk_level": "low" | "moderate" | "high",
     "requires_doctor": true | false,
     "emergency_warning": "Warning text if high risk, or null/empty if not emergency",
     "disclaimer": "Preliminary triage guidance only. Not a definitive medical diagnosis. For emergencies, contact 1122."
   }
PROMPT;
    }

    /**
     * Build Gemini contents payload with history.
     */
    private function buildContentsPayload(string $userMessage, array $history): array {
        $contents = [];

        // Add history
        foreach ($history as $item) {
            $role = ($item['role'] ?? 'user') === 'user' ? 'user' : 'model';
            $text = trim((string)($item['message'] ?? $item['content'] ?? $item['text'] ?? ''));
            if (!empty($text)) {
                $contents[] = [
                    'role' => $role,
                    'parts' => [['text' => $text]]
                ];
            }
        }

        // Add current user message
        $contents[] = [
            'role' => 'user',
            'parts' => [['text' => $userMessage]]
        ];

        return $contents;
    }

    /**
     * Parse and sanitize JSON response from Gemini.
     */
    private function parseAndValidateJsonResponse(string $rawText, string $language): ?array {
        // Strip markdown code fences if Gemini added them (```json ... ```)
        $clean = trim($rawText);
        if (preg_match('/^```(?:json)?\s*(.*?)\s*```$/is', $clean, $matches)) {
            $clean = trim($matches[1]);
        }

        $json = json_decode($clean, true);
        if (!is_array($json) || empty($json['reply'])) {
            return null;
        }

        $riskLevel = strtolower((string)($json['risk_level'] ?? 'low'));
        if (!in_array($riskLevel, ['low', 'moderate', 'high'], true)) {
            $riskLevel = 'low';
        }

        $detectedSymptoms = [];
        if (isset($json['detected_symptoms']) && is_array($json['detected_symptoms'])) {
            $detectedSymptoms = array_values(array_filter(array_map('strval', $json['detected_symptoms'])));
        }

        $requiresDoctor = isset($json['requires_doctor']) ? (bool)$json['requires_doctor'] : ($riskLevel !== 'low');
        $emergencyWarning = !empty($json['emergency_warning']) ? (string)$json['emergency_warning'] : null;

        $disclaimer = !empty($json['disclaimer'])
            ? (string)$json['disclaimer']
            : 'Preliminary triage guidance only. Not a definitive medical diagnosis. In case of emergency, contact 1122.';

        return [
            'reply' => (string)$json['reply'],
            'detected_symptoms' => $detectedSymptoms,
            'risk_level' => $riskLevel,
            'requires_doctor' => $requiresDoctor,
            'emergency_warning' => $emergencyWarning,
            'disclaimer' => $disclaimer,
        ];
    }

    /**
     * Emergency safety net rule verification.
     * Guarantees critical red-flags always trigger High Risk regardless of model output.
     */
    public function applyEmergencySafetyNet(string $userMessage, array $triage, string $language): array {
        $lower = mb_strtolower($userMessage, 'UTF-8');

        $redFlags = [
            // English
            'chest pain', 'heart attack', 'difficulty breathing', 'shortness of breath',
            'snake bite', 'poison', 'unconscious', 'paralysis',
            'severe head injury', 'severe bleeding', 'convulsion', 'stroke', 'cyanosis',
            // Roman Urdu
            'seene mein dard', 'seene me dard', 'dil ka daura',
            'sans lene mein dushwari', 'saans nahi aa rahi',
            'saanp ne kata', 'saanp ka katna', 'zehar', 'zehr',
            'behoshi', 'behosh', 'falij', 'lakwa',
            'sar par shadeed chot', 'khoon nikal raha hai',
            'jhatke', 'mirgi', 'hont neelay',
            // Urdu script
            'سینے میں درد', 'سانپ', 'زہر', 'بے ہوش', 'بےہوش',
            'فالج', 'لکوا', 'دورے', 'مرگی',
            'شدید خون', 'سر پر چوٹ', 'سانس لینے میں دشواری',
            'سانس نہیں آ رہی', 'جھٹکے',
        ];

        $isEmergency = false;
        $matchedTrigger = '';
        foreach ($redFlags as $flag) {
            if (str_contains($lower, $flag)) {
                $isEmergency = true;
                $matchedTrigger = $flag;
                break;
            }
        }

        if ($isEmergency) {
            $triage['risk_level'] = 'high';
            $triage['requires_doctor'] = true;
            if (empty($triage['emergency_warning'])) {
                $triage['emergency_warning'] = match(strtolower($language)) {
                    'urdu', 'ur' => '🚨 ہنگامی انتباہ: یہ علامات فوری ہنگامی طبی امداد کی متقاضی ہیں۔ فوراً 1122 پر کال کریں یا قریبی ایمرجنسی وارڈ جائیں۔',
                    'roman_urdu', 'roman-urdu', 'ur_roman' => '🚨 EMERGENCY WARNING: Ye alamaat fori emergency medical care mangti hain. Foran Rescue 1122 ko call karein ya qareebi hospital emergency jayein.',
                    default => '🚨 EMERGENCY WARNING: Critical red-flag symptoms detected. Contact Rescue 1122 or visit the nearest emergency department immediately.'
                };
            }
            if (empty($triage['detected_symptoms'])) {
                $triage['detected_symptoms'] = ['Critical Red Flag: ' . $matchedTrigger];
            }
        }

        return $triage;
    }

    // -----------------------------------------------------------------
    // HEALTH CONTINUITY ENGINE: Patient Brief & Care Plan Generation
    // -----------------------------------------------------------------

    /**
     * Generate an AI Patient Brief for the doctor from triage/history/profile data.
     *
     * @param array $context Aggregated data:
     *   - patient_profile: ['age','gender','blood_group','allergies','chronic_conditions','city']
     *   - triage:          ['primary_complaint','detected_symptoms','risk_level','emergency_warning','ai_reply']
     *   - medical_records: [['title','description','diagnosis','record_date'], ...]
     *   - active_medicines:[['medicine_name','dosage','frequency'], ...]
     *   - consultation:    ['symptoms','risk_level']
     * @param string $language 'english', 'urdu', or 'roman_urdu'
     * @return array ['brief_text' => string, 'structured_data' => array, 'source' => string]
     */
    public function generatePatientBrief(array $context, string $language = 'english'): array {
        if (empty($this->apiKey)) {
            return $this->generateOfflinePatientBrief($context, $language);
        }

        try {
            $systemInstruction = $this->buildPatientBriefSystemInstruction($context, $language);
            $userMessage = $this->buildPatientBriefUserMessage($context);

            $rawText = $this->callGeminiGenerateContent($systemInstruction, $userMessage, [
                'temperature' => 0.2,
                'topP' => 0.8,
                // 4096 headroom: thinking tokens count toward the budget, and
                // truncated JSON (finishReason MAX_TOKENS) fails to parse and
                // falls back to the offline template.
                'maxOutputTokens' => 4096,
                'responseMimeType' => 'application/json',
            ]);

            if ($rawText === null) {
                return $this->generateOfflinePatientBrief($context, $language);
            }

            $parsed = $this->parseBriefJson($rawText);
            if ($parsed === null) {
                error_log('[GeminiService] Patient brief JSON parse failed. rawHead=' . substr($rawText, 0, 300));
                return $this->generateOfflinePatientBrief($context, $language);
            }

            // Emergency safety: always inject red-flag banner if risk is high
            $parsed = $this->injectBriefEmergencyBanner($parsed, $context, $language);
            $parsed['_source'] = 'google_gemini_api';
            return $parsed;

        } catch (Throwable $e) {
            error_log('[GeminiService] Patient brief exception: ' . $e->getMessage());
            return $this->generateOfflinePatientBrief($context, $language);
        }
    }

    /**
     * Generate an AI Care Plan for the patient after consultation/prescription.
     *
     * @param array $context Aggregated data:
     *   - patient_profile:    ['age','gender','allergies','chronic_conditions','city']
     *   - consultation:       ['symptoms','risk_level','doctor_notes']
     *   - prescription_items: [['medicine_name','dosage','frequency','duration','instructions'], ...]
     *   - doctor_name:        string
     *   - doctor_specialty:   string
     * @param string $language 'english', 'urdu', or 'roman_urdu'
     * @return array ['care_plan_text' => string, 'structured_data' => array, 'follow_up_date' => ?string, 'source' => string]
     */
    public function generateCarePlan(array $context, string $language = 'english'): array {
        if (empty($this->apiKey)) {
            return $this->generateOfflineCarePlan($context, $language);
        }

        try {
            $systemInstruction = $this->buildCarePlanSystemInstruction($context, $language);
            $userMessage = $this->buildCarePlanUserMessage($context);

            $rawText = $this->callGeminiGenerateContent($systemInstruction, $userMessage, [
                'temperature' => 0.3,
                'topP' => 0.8,
                // 4096 headroom: prevents truncated JSON (see patient brief note).
                'maxOutputTokens' => 4096,
                'responseMimeType' => 'application/json',
            ]);

            if ($rawText === null) {
                return $this->generateOfflineCarePlan($context, $language);
            }

            $parsed = $this->parseCarePlanJson($rawText);
            if ($parsed === null) {
                error_log('[GeminiService] Care plan JSON parse failed. rawHead=' . substr($rawText, 0, 300));
                return $this->generateOfflineCarePlan($context, $language);
            }

            // Emergency safety: always append rule-based Rescue 1122 warning signs
            $parsed = $this->injectCarePlanEmergencySigns($parsed, $language);
            $parsed['_source'] = 'google_gemini_api';
            return $parsed;

        } catch (Throwable $e) {
            error_log('[GeminiService] Care plan exception: ' . $e->getMessage());
            return $this->generateOfflineCarePlan($context, $language);
        }
    }

    /**
     * Shared Gemini generateContent call with retry handling for transient
     * failures (HTTP 429 rate limit / 503 overload). Mirrors the retry pattern
     * already used by the triage endpoint.
     *
     * @return string|null Raw model text, or null when the API keeps failing.
     */
    private function callGeminiGenerateContent(string $systemInstruction, string $userMessage, array $generationConfig): ?string {
        $endpoint = self::BASE_URL . $this->model . ':generateContent?key=' . urlencode($this->apiKey);

        $payload = [
            'system_instruction' => [
                'parts' => [['text' => $systemInstruction]],
            ],
            'contents' => [
                ['role' => 'user', 'parts' => [['text' => $userMessage]]],
            ],
            'generationConfig' => $generationConfig,
        ];

        $maxRetries = 2;
        for ($attempt = 0; $attempt <= $maxRetries; $attempt++) {
            $ch = curl_init($endpoint);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST           => true,
                CURLOPT_HTTPHEADER     => [
                    'Content-Type: application/json; charset=utf-8',
                    'Accept: application/json',
                ],
                CURLOPT_POSTFIELDS     => json_encode($payload, JSON_UNESCAPED_UNICODE),
                CURLOPT_TIMEOUT        => 30,
                CURLOPT_CONNECTTIMEOUT => 10,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_SSL_VERIFYHOST => 0,
            ]);

            $responseBody = curl_exec($ch);
            $httpCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $curlError = curl_error($ch);
            curl_close($ch);

            if (!empty($curlError)) {
                error_log("[GeminiService] cURL error (attempt {$attempt}): {$curlError}");
                if ($attempt < $maxRetries) {
                    sleep(2);
                    continue;
                }
                return null;
            }

            // Free-tier rate limit (20 req/min) or transient overload — back off and retry.
            if (($httpCode === 429 || $httpCode === 503) && $attempt < $maxRetries) {
                $retryDelay = $httpCode === 429 ? ($attempt === 0 ? 15 : 20) : 2;
                error_log("[GeminiService] HTTP {$httpCode} from Gemini, retrying in {$retryDelay}s (attempt {$attempt})");
                sleep($retryDelay);
                continue;
            }

            if ($httpCode < 200 || $httpCode >= 300 || empty($responseBody)) {
                error_log("[GeminiService] Gemini API HTTP {$httpCode}: {$responseBody}");
                return null;
            }

            $decoded = json_decode((string)$responseBody, true);
            $candidate = $decoded['candidates'][0] ?? [];
            $parts = $candidate['content']['parts'] ?? [];
            $rawText = $parts[0]['text'] ?? null;

            // Thinking models can consume the whole output budget or emit a
            // thought-only part; surface that instead of failing silently.
            if (empty($rawText)) {
                error_log('[GeminiService] Empty response text. finishReason='
                    . ($candidate['finishReason'] ?? 'n/a')
                    . ' parts=' . count($parts)
                    . ' bodyHead=' . substr((string)$responseBody, 0, 300));
                return null;
            }

            // If the first part is a thought, use the first non-thought part.
            if (!empty($parts[0]['thought'])) {
                foreach ($parts as $part) {
                    if (empty($part['thought']) && !empty($part['text'])) {
                        return (string)$part['text'];
                    }
                }
                error_log('[GeminiService] Only thought parts returned. finishReason='
                    . ($candidate['finishReason'] ?? 'n/a'));
                return null;
            }

            return (string)$rawText;
        }

        return null;
    }

    // -----------------------------------------------------------------
    // Patient Brief — Prompt Builders & Helpers
    // -----------------------------------------------------------------

    private function buildPatientBriefSystemInstruction(array $context, string $language): string {
        $langDirective = match(strtolower($language)) {
            'urdu', 'ur' => 'Write the brief in standard Urdu script (اردو). Use clear clinical Urdu terminology.',
            'roman_urdu', 'roman-urdu', 'ur_roman' => 'Write the brief in Roman Urdu (Urdu in Latin alphabet). Use concise, professional Roman Urdu.',
            default => 'Write the brief in clear, concise professional English.',
        };

        return <<<PROMPT
You are a clinical briefing assistant for SehatAI Pakistan, generating concise patient summaries for PMDC-registered doctors before a teleconsultation.

LANGUAGE REQUIREMENT:
{$langDirective}

STRICT RULES:
1. Summarise ONLY — do NOT diagnose or prescribe.
2. Highlight allergies, chronic conditions, and any emergency red-flag symptoms prominently.
3. If the triage risk_level is "high", the first line MUST be an emergency warning banner.
4. Keep the brief under 300 words. Use bullet points and short sections.
5. Mention Pakistani healthcare context where relevant (Rescue 1122, PMDC, ORS).

OUTPUT FORMAT — valid JSON with EXACTLY these keys:
{
  "chief_complaint": "One-line summary of the primary presenting complaint",
  "symptom_timeline": "Brief timeline/duration of symptoms",
  "risk_factors": ["array of clinical risk factors from profile and triage"],
  "relevant_history": "Summary of past medical records and chronic conditions",
  "current_medications_summary": "Summary of active medicines or None",
  "allergies_and_contraindications": "Known allergies or None known",
  "ai_triage_assessment": "Summary of AI triage result including risk level",
  "suggested_focus_areas": ["array of areas the doctor should focus on"],
  "brief_markdown": "Full formatted brief in markdown"
}
PROMPT;
    }

    private function buildPatientBriefUserMessage(array $context): string {
        $p = $context['patient_profile'] ?? [];
        $t = $context['triage'] ?? [];
        $c = $context['consultation'] ?? [];
        $records = $context['medical_records'] ?? [];
        $medicines = $context['active_medicines'] ?? [];

        $parts = [];
        $parts[] = "PATIENT PROFILE: Age " . ($p['age'] ?? 'N/A') . ", Gender: " . ($p['gender'] ?? 'N/A')
                 . ", Blood Group: " . ($p['blood_group'] ?? 'N/A') . ", City: " . ($p['city'] ?? 'N/A');
        $parts[] = "ALLERGIES: " . ($p['allergies'] ?? 'None known');
        $parts[] = "CHRONIC CONDITIONS: " . ($p['chronic_conditions'] ?? 'None reported');

        $parts[] = "\nCONSULTATION SYMPTOMS: " . ($c['symptoms'] ?? 'N/A');
        $parts[] = "CONSULTATION RISK LEVEL: " . ($c['risk_level'] ?? 'moderate');

        if (!empty($t)) {
            $symptoms = is_array($t['detected_symptoms'] ?? null)
                ? implode(', ', $t['detected_symptoms'])
                : ($t['detected_symptoms'] ?? 'N/A');
            $parts[] = "\nAI TRIAGE DATA:";
            $parts[] = "- Primary Complaint: " . ($t['primary_complaint'] ?? 'N/A');
            $parts[] = "- Detected Symptoms: " . $symptoms;
            $parts[] = "- Risk Level: " . ($t['risk_level'] ?? 'N/A');
            $parts[] = "- Emergency Warning: " . ($t['emergency_warning'] ?? 'None');
            $parts[] = "- AI Reply: " . ($t['ai_reply'] ?? 'N/A');
        }

        if (!empty($records)) {
            $parts[] = "\nRECENT MEDICAL RECORDS:";
            foreach (array_slice($records, 0, 5) as $r) {
                $parts[] = "- [" . ($r['record_date'] ?? '') . "] " . ($r['title'] ?? '') . ": " . ($r['description'] ?? '');
            }
        }

        if (!empty($medicines)) {
            $parts[] = "\nACTIVE MEDICINES:";
            foreach ($medicines as $m) {
                $parts[] = "- " . ($m['medicine_name'] ?? '') . " " . ($m['dosage'] ?? '') . " " . ($m['frequency'] ?? '');
            }
        }

        $parts[] = "\nGenerate a concise patient brief for the attending doctor.";
        return implode("\n", $parts);
    }

    private function parseBriefJson(string $rawText): ?array {
        $clean = trim($rawText);
        if (preg_match('/^```(?:json)?\s*(.*?)\s*```$/is', $clean, $matches)) {
            $clean = trim($matches[1]);
        }
        $json = json_decode($clean, true);
        if (!is_array($json) || empty($json['brief_markdown'])) {
            return null;
        }
        return [
            'brief_text' => (string)$json['brief_markdown'],
            'structured_data' => [
                'chief_complaint' => (string)($json['chief_complaint'] ?? ''),
                'symptom_timeline' => (string)($json['symptom_timeline'] ?? ''),
                'risk_factors' => is_array($json['risk_factors'] ?? null) ? $json['risk_factors'] : [],
                'relevant_history' => (string)($json['relevant_history'] ?? ''),
                'current_medications_summary' => (string)($json['current_medications_summary'] ?? ''),
                'allergies_and_contraindications' => (string)($json['allergies_and_contraindications'] ?? ''),
                'ai_triage_assessment' => (string)($json['ai_triage_assessment'] ?? ''),
                'suggested_focus_areas' => is_array($json['suggested_focus_areas'] ?? null) ? $json['suggested_focus_areas'] : [],
            ],
        ];
    }

    /**
     * Rule-based emergency banner injection into brief — never AI-overridden.
     */
    private function injectBriefEmergencyBanner(array $parsed, array $context, string $language): array {
        $riskLevel = strtolower($context['triage']['risk_level'] ?? $context['consultation']['risk_level'] ?? 'low');
        $emergencyWarning = $context['triage']['emergency_warning'] ?? null;

        if ($riskLevel === 'high' || !empty($emergencyWarning)) {
            $banner = match(strtolower($language)) {
                'urdu', 'ur' => "\u{1F6A8} ہنگامی انتباہ: یہ مریض اعلیٰ خطرے کی علامات کے ساتھ پیش ہوا ہے۔ فوری طبی توجہ درکار ہے۔ ریسکیو 1122 سے رابطہ کریں۔\n\n",
                'roman_urdu', 'roman-urdu', 'ur_roman' => "\u{1F6A8} EMERGENCY ALERT: Ye mareez high-risk alamaat ke sath aaya hai. Fori medical attention zaroori hai. Rescue 1122 par rabta karein.\n\n",
                default => "\u{1F6A8} EMERGENCY ALERT: This patient presented with high-risk symptoms requiring immediate attention. Contact Rescue 1122 or nearest emergency department.\n\n",
            };
            $parsed['brief_text'] = $banner . $parsed['brief_text'];
        }
        return $parsed;
    }

    /**
     * Offline template-based patient brief fallback (no AI).
     */
    private function generateOfflinePatientBrief(array $context, string $language): array {
        $p = $context['patient_profile'] ?? [];
        $t = $context['triage'] ?? [];
        $c = $context['consultation'] ?? [];
        $records = $context['medical_records'] ?? [];
        $medicines = $context['active_medicines'] ?? [];
        $riskLevel = strtolower($t['risk_level'] ?? $c['risk_level'] ?? 'low');
        $lang = strtolower($language);

        // Emergency banner (rule-based, always present for high risk)
        $emergencyBanner = '';
        if ($riskLevel === 'high' || !empty($t['emergency_warning'])) {
            $emergencyBanner = match($lang) {
                'urdu', 'ur' => "\u{1F6A8} ہنگامی انتباہ: اعلیٰ خطرہ — فوری طبی امداد درکار ہے۔ ریسکیو 1122۔\n\n",
                'roman_urdu', 'roman-urdu', 'ur_roman' => "\u{1F6A8} EMERGENCY: High-risk symptoms — Fori medical attention zaroori hai. Rescue 1122.\n\n",
                default => "\u{1F6A8} EMERGENCY: High-risk symptoms detected — Immediate medical attention required. Contact Rescue 1122.\n\n",
            };
        }

        $chiefComplaint = $c['symptoms'] ?? $t['primary_complaint'] ?? 'Not specified';
        $symptoms = is_array($t['detected_symptoms'] ?? null) ? implode(', ', $t['detected_symptoms']) : ($t['detected_symptoms'] ?? 'N/A');

        $riskFactors = [];
        if (!empty($p['chronic_conditions'])) $riskFactors[] = 'Chronic: ' . $p['chronic_conditions'];
        if ($riskLevel !== 'low') $riskFactors[] = 'Triage Risk: ' . strtoupper($riskLevel);

        $medsSummary = 'No active medications on record.';
        if (!empty($medicines)) {
            $medsList = [];
            foreach ($medicines as $m) {
                $medsList[] = ($m['medicine_name'] ?? '') . ' ' . ($m['dosage'] ?? '') . ' ' . ($m['frequency'] ?? '');
            }
            $medsSummary = implode('; ', $medsList);
        }

        $allergies = $p['allergies'] ?? 'None known';
        $history = 'No recent medical records on file.';
        if (!empty($records)) {
            $histParts = [];
            foreach (array_slice($records, 0, 3) as $r) {
                $histParts[] = ($r['title'] ?? '') . ' (' . ($r['record_date'] ?? '') . ')';
            }
            $history = implode('; ', $histParts);
        }

        $brief = $emergencyBanner;
        $brief .= "**Patient:** Age " . ($p['age'] ?? 'N/A') . ", " . ($p['gender'] ?? 'N/A') . ", Blood Group: " . ($p['blood_group'] ?? 'N/A') . "\n";
        $brief .= "**Chief Complaint:** {$chiefComplaint}\n";
        $brief .= "**AI Detected Symptoms:** {$symptoms}\n";
        $brief .= "**Risk Level:** " . strtoupper($riskLevel) . "\n";
        $brief .= "**Allergies:** {$allergies}\n";
        $brief .= "**Chronic Conditions:** " . ($p['chronic_conditions'] ?? 'None') . "\n";
        $brief .= "**Active Medications:** {$medsSummary}\n";
        $brief .= "**Recent History:** {$history}\n";

        $focusAreas = ['Review presenting symptoms', 'Check medication interactions'];
        if ($riskLevel === 'high') array_unshift($focusAreas, 'Assess emergency status immediately');

        return [
            'brief_text' => $brief,
            'structured_data' => [
                'chief_complaint' => $chiefComplaint,
                'symptom_timeline' => $symptoms,
                'risk_factors' => $riskFactors,
                'relevant_history' => $history,
                'current_medications_summary' => $medsSummary,
                'allergies_and_contraindications' => $allergies,
                'ai_triage_assessment' => 'Risk: ' . strtoupper($riskLevel) . ' — ' . ($t['ai_reply'] ?? 'Triage data'),
                'suggested_focus_areas' => $focusAreas,
            ],
            '_source' => 'offline_template',
        ];
    }

    // -----------------------------------------------------------------
    // Care Plan — Prompt Builders & Helpers
    // -----------------------------------------------------------------

    private function buildCarePlanSystemInstruction(array $context, string $language): string {
        $langDirective = match(strtolower($language)) {
            'urdu', 'ur' => 'Write the care plan in standard Urdu script (اردو). Use patient-friendly, reassuring medical Urdu.',
            'roman_urdu', 'roman-urdu', 'ur_roman' => 'Write the care plan in Roman Urdu. Use simple, reassuring language a patient can understand.',
            default => 'Write the care plan in clear, empathetic English that a patient can easily understand.',
        };

        return <<<PROMPT
You are a post-consultation care plan assistant for SehatAI Pakistan, generating patient-friendly recovery guidance after a doctor's consultation and prescription.

LANGUAGE REQUIREMENT:
{$langDirective}

STRICT RULES:
1. Provide supportive care guidance ONLY — do NOT alter the doctor's prescription or add new medications.
2. Explain how to take each prescribed medicine in simple terms (with/without food, timing tips).
3. List common side effects to watch for each medicine.
4. WARNING SIGNS must always include: "If you experience chest pain, severe breathing difficulty, unconsciousness, seizures, or severe bleeding — contact Rescue 1122 immediately."
5. Suggest a reasonable follow-up period (typically 5-14 days depending on condition severity).
6. Include practical lifestyle and home monitoring tips relevant to Pakistani context (ORS, hydration, boiled water).

OUTPUT FORMAT — valid JSON with EXACTLY these keys:
{
  "medication_guidance": [{"medicine": "name", "how_to_take": "simple instructions", "side_effects_watch": "common side effects"}],
  "warning_signs": ["array of warning signs including mandatory Rescue 1122 emergency line"],
  "lifestyle_recommendations": ["array of practical lifestyle tips"],
  "follow_up_in_days": 7,
  "follow_up_date": "YYYY-MM-DD or null",
  "home_monitoring": ["array of things patient should monitor at home"],
  "care_plan_markdown": "Full formatted care plan in markdown"
}
PROMPT;
    }

    private function buildCarePlanUserMessage(array $context): string {
        $p = $context['patient_profile'] ?? [];
        $c = $context['consultation'] ?? [];
        $items = $context['prescription_items'] ?? [];
        $docName = $context['doctor_name'] ?? 'Your Doctor';
        $docSpec = $context['doctor_specialty'] ?? 'General Physician';

        $parts = [];
        $parts[] = "PATIENT: Age " . ($p['age'] ?? 'N/A') . ", " . ($p['gender'] ?? 'N/A');
        $parts[] = "ALLERGIES: " . ($p['allergies'] ?? 'None known');
        $parts[] = "CHRONIC CONDITIONS: " . ($p['chronic_conditions'] ?? 'None');

        $parts[] = "\nCONSULTATION SYMPTOMS: " . ($c['symptoms'] ?? 'N/A');
        $parts[] = "RISK LEVEL: " . ($c['risk_level'] ?? 'moderate');
        $parts[] = "DOCTOR NOTES: " . ($c['doctor_notes'] ?? 'None provided');

        $parts[] = "\nPRESCRIBED BY: {$docName} ({$docSpec})";
        $parts[] = "PRESCRIPTION MEDICINES:";
        if (empty($items)) {
            $parts[] = "- No medicines prescribed.";
        } else {
            foreach ($items as $item) {
                $parts[] = "- " . ($item['medicine_name'] ?? '') . " | Dosage: " . ($item['dosage'] ?? '')
                         . " | Frequency: " . ($item['frequency'] ?? '') . " | Duration: " . ($item['duration'] ?? '')
                         . " | Instructions: " . ($item['instructions'] ?? 'As directed');
            }
        }

        $parts[] = "\nGenerate a complete post-consultation care plan for this patient.";
        $parts[] = "Today's date: " . date('Y-m-d');
        return implode("\n", $parts);
    }

    private function parseCarePlanJson(string $rawText): ?array {
        $clean = trim($rawText);
        if (preg_match('/^```(?:json)?\s*(.*?)\s*```$/is', $clean, $matches)) {
            $clean = trim($matches[1]);
        }
        $json = json_decode($clean, true);
        if (!is_array($json) || empty($json['care_plan_markdown'])) {
            return null;
        }

        $followUpDate = $json['follow_up_date'] ?? null;
        if (empty($followUpDate) && !empty($json['follow_up_in_days'])) {
            $days = (int)$json['follow_up_in_days'];
            $followUpDate = date('Y-m-d', strtotime("+{$days} days"));
        }

        $medGuidance = [];
        if (is_array($json['medication_guidance'] ?? null)) {
            foreach ($json['medication_guidance'] as $mg) {
                $medGuidance[] = [
                    'medicine' => (string)($mg['medicine'] ?? ''),
                    'how_to_take' => (string)($mg['how_to_take'] ?? ''),
                    'side_effects_watch' => (string)($mg['side_effects_watch'] ?? ''),
                ];
            }
        }

        return [
            'care_plan_text' => (string)$json['care_plan_markdown'],
            'structured_data' => [
                'medication_guidance' => $medGuidance,
                'warning_signs' => is_array($json['warning_signs'] ?? null) ? $json['warning_signs'] : [],
                'lifestyle_recommendations' => is_array($json['lifestyle_recommendations'] ?? null) ? $json['lifestyle_recommendations'] : [],
                'home_monitoring' => is_array($json['home_monitoring'] ?? null) ? $json['home_monitoring'] : [],
            ],
            'follow_up_date' => $followUpDate,
        ];
    }

    /**
     * Rule-based Rescue 1122 emergency warning signs injection — never AI-overridden.
     */
    private function injectCarePlanEmergencySigns(array $parsed, string $language): array {
        $emergencySigns = match(strtolower($language)) {
            'urdu', 'ur' => '🚨 اگر سینے میں درد، سانس لینے میں شدید دشواری، بے ہوشی، دورے، یا شدید خون بہہ رہا ہو — فوراً ریسکیو 1122 پر کال کریں۔',
            'roman_urdu', 'roman-urdu', 'ur_roman' => '🚨 Agar seene mein dard, saans lene mein shadeed dushwari, behoshi, jhatke, ya shadeed bleeding ho — foran Rescue 1122 par call karein.',
            default => '🚨 If you experience chest pain, severe breathing difficulty, unconsciousness, seizures, or severe bleeding — contact Rescue 1122 immediately.',
        };

        $signs = $parsed['structured_data']['warning_signs'] ?? [];
        // Ensure the emergency sign is always present
        $hasEmergencySign = false;
        foreach ($signs as $s) {
            if (str_contains(strtolower($s), 'rescue 1122') || str_contains(strtolower($s), '1122')) {
                $hasEmergencySign = true;
                break;
            }
        }
        if (!$hasEmergencySign) {
            $signs[] = $emergencySigns;
        }
        $parsed['structured_data']['warning_signs'] = $signs;

        // Also inject into the markdown text
        if (!str_contains($parsed['care_plan_text'], '1122')) {
            $parsed['care_plan_text'] .= "\n\n---\n**{$emergencySigns}**";
        }

        return $parsed;
    }

    /**
     * Offline template-based care plan fallback (no AI).
     */
    private function generateOfflineCarePlan(array $context, string $language): array {
        $p = $context['patient_profile'] ?? [];
        $c = $context['consultation'] ?? [];
        $items = $context['prescription_items'] ?? [];
        $docName = $context['doctor_name'] ?? 'Your Doctor';
        $docSpec = $context['doctor_specialty'] ?? 'General Physician';
        $lang = strtolower($language);

        $followUpDays = ($c['risk_level'] ?? 'moderate') === 'high' ? 3 : 7;
        $followUpDate = date('Y-m-d', strtotime("+{$followUpDays} days"));

        // Build medication guidance
        $medGuidance = [];
        foreach ($items as $item) {
            $medGuidance[] = [
                'medicine' => $item['medicine_name'] ?? 'Medicine',
                'how_to_take' => ($item['instructions'] ?? 'Take as directed by your doctor') . ' — ' . ($item['frequency'] ?? '') . ' for ' . ($item['duration'] ?? 'as prescribed'),
                'side_effects_watch' => 'Report any unusual reactions to your doctor.',
            ];
        }

        // Warning signs — always includes Rescue 1122
        $warningSigns = match($lang) {
            'urdu', 'ur' => [
                'اگر بخار 3 دن سے زیادہ رہے تو ڈاکٹر سے رابطہ کریں',
                'اگر علامات بڑھ جائیں یا نئی علامات ظاہر ہوں تو فوری مشورہ کریں',
                '🚨 اگر سینے میں درد، سانس لینے میں شدید دشواری، بے ہوشی، دورے، یا شدید خون بہہ رہا ہو — فوراً ریسکیو 1122 پر کال کریں۔',
            ],
            'roman_urdu', 'roman-urdu', 'ur_roman' => [
                'Agar bukhar 3 din se zyada rahe to doctor se rabta karein',
                'Agar alamaat barh jayein ya nayi alamaat zahir hon to foran mashwara karein',
                '🚨 Agar seene mein dard, saans lene mein shadeed dushwari, behoshi, jhatke, ya shadeed bleeding ho — foran Rescue 1122 par call karein.',
            ],
            default => [
                'If fever persists beyond 3 days, contact your doctor',
                'If symptoms worsen or new symptoms appear, seek immediate advice',
                '🚨 If you experience chest pain, severe breathing difficulty, unconsciousness, seizures, or severe bleeding — contact Rescue 1122 immediately.',
            ],
        };

        $lifestyleTips = match($lang) {
            'urdu', 'ur' => ['پانی اور او آر ایس کا استعمال بڑھائیں', 'مکمل آرام کریں اور متوازن غذا لیں', 'ہر 4-6 گھنٹے بخار چیک کریں'],
            'roman_urdu', 'roman-urdu', 'ur_roman' => ['Paani aur ORS ka istemal barhayein', 'Mukammal aaram karein aur mutawazan ghiza lein', 'Har 4-6 ghante bukhar check karein'],
            default => ['Increase fluid intake (water, ORS, warm soups)', 'Get adequate rest and maintain balanced nutrition', 'Monitor temperature every 4-6 hours'],
        };

        $homeMonitoring = match($lang) {
            'urdu', 'ur' => ['روزانہ درجہ حرارت نوٹ کریں', 'علامات کی تبدیلیاں ریکارڈ کریں'],
            'roman_urdu', 'roman-urdu', 'ur_roman' => ['Rozana darja hararat note karein', 'Alamaat ki tabdeeliyan record karein'],
            default => ['Record daily body temperature', 'Note any changes in symptoms'],
        };

        // Build markdown
        $plan = match($lang) {
            'urdu', 'ur' => "# دیکھ بھال کا منصوبہ\n\n**ڈاکٹر:** {$docName} ({$docSpec})\n\n## ادویات\n",
            'roman_urdu', 'roman-urdu', 'ur_roman' => "# Care Plan\n\n**Doctor:** {$docName} ({$docSpec})\n\n## Medicines\n",
            default => "# Your Care Plan\n\n**Prescribed by:** {$docName} ({$docSpec})\n\n## Your Medicines\n",
        };

        foreach ($medGuidance as $mg) {
            $plan .= "- **" . $mg['medicine'] . "**: " . $mg['how_to_take'] . "\n";
        }

        $plan .= match($lang) {
            'urdu', 'ur' => "\n## انتباہی علامات\n",
            'roman_urdu', 'roman-urdu', 'ur_roman' => "\n## Warning Signs\n",
            default => "\n## Warning Signs — Seek Help If:\n",
        };
        foreach ($warningSigns as $ws) {
            $plan .= "- {$ws}\n";
        }

        $plan .= match($lang) {
            'urdu', 'ur' => "\n## طرز زندگی کے مشورے\n",
            'roman_urdu', 'roman-urdu', 'ur_roman' => "\n## Lifestyle Tips\n",
            default => "\n## Lifestyle Recommendations\n",
        };
        foreach ($lifestyleTips as $tip) {
            $plan .= "- {$tip}\n";
        }

        $plan .= match($lang) {
            'urdu', 'ur' => "\n## فالو اپ: {$followUpDate} کو ڈاکٹر سے دوبارہ مشورہ کریں\n",
            'roman_urdu', 'roman-urdu', 'ur_roman' => "\n## Follow-up: {$followUpDate} ko doctor se dobara mashwara karein\n",
            default => "\n## Follow-up: Please consult your doctor again on {$followUpDate}\n",
        };

        return [
            'care_plan_text' => $plan,
            'structured_data' => [
                'medication_guidance' => $medGuidance,
                'warning_signs' => $warningSigns,
                'lifestyle_recommendations' => $lifestyleTips,
                'home_monitoring' => $homeMonitoring,
            ],
            'follow_up_date' => $followUpDate,
            '_source' => 'offline_template',
        ];
    }

    /**
     * High quality offline rule-based triage fallback.
     */
    public function generateLocalRuleBasedTriage(
        string $userMessage,
        string $language = 'roman_urdu',
        ?array $patientProfile = null
    ): array {
        $lower = mb_strtolower($userMessage, 'UTF-8');

        // Check High Risk
        $highRiskWords = [
            'chest pain', 'seene mein dard', 'seene me dard', 'dil ka daura', 'heart attack',
            'difficulty breathing', 'shortness of breath', 'sans lene mein dushwari', 'saans lene me takleef',
            'bleeding', 'khoon', 'snake bite', 'saanp', 'poison', 'zehar', 'zehr',
            'unconscious', 'behoshi', 'behosh', 'paralysis', 'falij', 'head injury', 'sar par chot', 'jhatke'
        ];

        // Check Moderate Risk
        $moderateRiskWords = [
            'fever', 'bukhar', 'vomiting', 'ulti', 'stomach pain', 'pait dard', 'pait mein dard',
            'cough', 'khansi', 'throat pain', 'gala kharab', 'diarrhea', 'dast', 'loose motion',
            'dizziness', 'chakkar', 'infection', 'wound', 'zakham'
        ];

        $isHigh = false;
        foreach ($highRiskWords as $w) {
            if (str_contains($lower, $w)) {
                $isHigh = true;
                break;
            }
        }

        $isModerate = false;
        if (!$isHigh) {
            foreach ($moderateRiskWords as $w) {
                if (str_contains($lower, $w)) {
                    $isModerate = true;
                    break;
                }
            }
        }

        $lang = strtolower($language);

        if ($isHigh) {
            $detected = ['Critical Cardiopulmonary / Acute Emergency Symptoms'];
            if ($lang === 'urdu' || $lang === 'ur') {
                $reply = "🚨 **ہنگامی الرٹ (High Risk Alert)**\n\n"
                    . "آپ کی بیان کردہ علامات فوری ہنگامی طبی توجہ کی متقاضی ہیں۔\n\n"
                    . "• کسی قسم کی تاخیر یا غیر تصدیق شدہ گھریلو ٹوٹکے نہ آزمائیں۔\n"
                    . "• فوری طور پر ریسکیو 1122 پر کال کریں یا قریبی ایمرجنسی وارڈ میں جائیں۔\n"
                    . "• مریض کو پرسکون حالت میں بٹھائیں اور اکیلا نہ چھوڑیں۔";
                $warning = "فوری طبی امداد کی ضرورت ہے۔ فوراً 1122 پر کال کریں۔";
                $disclaimer = "یہ ابتدائی رہنمائی ہے۔ حتمی تشخیص نہیں۔ ہنگامی صورت میں 1122 کال کریں۔";
            } elseif ($lang === 'roman_urdu' || $lang === 'roman-urdu' || $lang === 'ur_roman') {
                $reply = "🚨 **HIGH-RISK EMERGENCY WARNING**\n\n"
                    . "Aap ki batayi gayi alamaat fori emergency medical care mangti hain.\n\n"
                    . "• Foran Rescue 1122 par rabta karein ya qareebi emergency hospital tashreef le jayein.\n"
                    . "• Khud se koi gher-tasdeeq shuda dawa na lein aur aaram se baith jayein.\n"
                    . "• Kisi qareebi dost ya family member ko sath rakhein.";
                $warning = "Critical emergency symptoms detected. Call Rescue 1122 immediately.";
                $disclaimer = "Ibtidai medical guidance hai, hatmi diagnosis nahi. Emergency mein 1122 call karein.";
            } else {
                $reply = "🚨 **HIGH-RISK MEDICAL ALERT**\n\n"
                    . "The symptoms you described indicate potential critical cardiopulmonary or acute emergency signs.\n\n"
                    . "• Do not exert yourself or attempt unverified home remedies.\n"
                    . "• Call Rescue 1122 immediately or proceed to the nearest emergency department.\n"
                    . "• Stay accompanied and maintain calm breathing.";
                $warning = "Immediate emergency evaluation required. Call 1122.";
                $disclaimer = "Preliminary triage guidance only. Not a definitive medical diagnosis. In emergency, call 1122.";
            }

            return [
                'reply' => $reply,
                'detected_symptoms' => $detected,
                'risk_level' => 'high',
                'requires_doctor' => true,
                'emergency_warning' => $warning,
                'disclaimer' => $disclaimer,
            ];
        }

        if ($isModerate) {
            $detected = ['Moderate systemic / infectious symptoms'];
            if ($lang === 'urdu' || $lang === 'ur') {
                $reply = "⚠️ **معتدل خطرے کا جائزہ (Moderate Assessment)**\n\n"
                    . "آپ کی علامات معتدل انفیکشن یا بیماری کی طرف اشارہ کرتی ہیں:\n\n"
                    . "• پانی، او آر ایس (ORS) اور گرم سیال اشیاء کا استعمال بڑھائیں۔\n"
                    . "• ہر 4 سے 6 گھنٹے بعد بخار اور علامات چیک کریں۔\n"
                    . "• 24 گھنٹوں کے اندر پی ایم ڈی سی تصدیق شدہ ڈاکٹر سے آن لائن مشاورت کریں۔";
                $disclaimer = "یہ ابتدائی رہنمائی ہے۔ حتمی تشخیص نہیں۔ پی ایم ڈی سی ڈاکٹر سے مشورہ کریں۔";
            } elseif ($lang === 'roman_urdu' || $lang === 'roman-urdu' || $lang === 'ur_roman') {
                $reply = "⚠️ **Moderate Health Assessment**\n\n"
                    . "Aap ki alamaat ko dekhte hue mundarja-zail hidayat par amal karein:\n\n"
                    . "• Hydration ka sakhti se khayal rakhein (ubla hua paani, ORS, soup).\n"
                    . "• Har 4 se 6 ghante baad body temperature note karein.\n"
                    . "• 24 ghante ke andar PMDC registered doctor se teleconsultation karein agar behtari na aaye.";
                $disclaimer = "Ibtidai medical guidance hai. Behtar rehnumai ke liye doctor se rabta karein.";
            } else {
                $reply = "⚠️ **Moderate Risk Assessment**\n\n"
                    . "Based on the reported symptoms, clinical monitoring is recommended:\n\n"
                    . "• Maintain strict hydration (ORS, boiled water, electrolytes, warm fluids).\n"
                    . "• Monitor body temperature and vital symptoms every 4-6 hours.\n"
                    . "• A teleconsultation with a PMDC registered doctor is recommended within 24 hours.";
                $disclaimer = "Preliminary triage guidance only. Consult a registered physician for diagnosis.";
            }

            return [
                'reply' => $reply,
                'detected_symptoms' => $detected,
                'risk_level' => 'moderate',
                'requires_doctor' => true,
                'emergency_warning' => null,
                'disclaimer' => $disclaimer,
            ];
        }

        // Low Risk
        $detected = ['Mild / self-limiting discomfort'];
        if ($lang === 'urdu' || $lang === 'ur') {
            $reply = "✅ **ابتدائی عمومی رہنمائی (Low Risk)**\n\n"
                . "آپ کی بیان کردہ علامات بظاہر معمولی اور خود ٹھیک ہونے والی معلوم ہوتی ہیں:\n\n"
                . "• مناسب آرام کریں اور متوازن غذا و پانی استعمال کریں۔\n"
                . "• اگلے 48 گھنٹے تک علامات پر نظر رکھیں۔\n"
                . "• اگر تکلیف 3 سے 5 دن سے زیادہ برقرار رہے تو ڈاکٹر سے رجوع کریں۔";
            $disclaimer = "یہ عام معلوماتی رہنمائی ہے۔ ضرورت پڑنے پر ڈاکٹر سے رابطہ کریں۔";
        } elseif ($lang === 'roman_urdu' || $lang === 'roman-urdu' || $lang === 'ur_roman') {
            $reply = "✅ **Low Risk / General Guidance**\n\n"
                . "Aap ki alamaat mamooli maloom hoti hain:\n\n"
                . "• Mukammal aaram karein aur paani zyada miqdar mein piyein.\n"
                . "• Agle 48 ghante tak apni tabiyat observe karein.\n"
                . "• Agar 3-5 din tak takleef khatam na ho to doctor se checkup karwayein.";
            $disclaimer = "Ibtidai rehnumai hai. Agar takleef barhay to doctor se mashwara karein.";
        } else {
            $reply = "✅ **Low Risk / General Guidance**\n\n"
                . "The symptoms described appear to be mild and self-limiting:\n\n"
                . "• Get adequate rest, maintain healthy nutrition, and drink plenty of fluids.\n"
                . "• Observe symptoms over the next 48 hours.\n"
                . "• If discomfort persists beyond 3-5 days or worsens, please consult a physician.";
            $disclaimer = "General preliminary health guidance only. Not a medical diagnosis.";
        }

        return [
            'reply' => $reply,
            'detected_symptoms' => $detected,
            'risk_level' => 'low',
            'requires_doctor' => false,
            'emergency_warning' => null,
            'disclaimer' => $disclaimer,
        ];
    }
}
