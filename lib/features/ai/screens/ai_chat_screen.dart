import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/risk_indicator_badge.dart';
import '../../../services/ai_triage_service.dart';
import '../../../services/auth_service.dart';
import '../../emergency/screens/emergency_screen.dart';
import '../../emergency/screens/triage_result_screen.dart';
import '../../doctors/screens/doctor_list_screen.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final TriageRiskLevel? detectedRisk;
  final List<String>? quickActions;

  AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.detectedRisk,
    this.quickActions,
  });
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiTriageService _aiTriageService = AiTriageService();
  late final String _sessionId;
  AppLanguage _selectedLanguage = AppLanguage.romanUrdu;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
  }

  final List<AiChatMessage> _messages = [
    AiChatMessage(
      text:
          'Assalam o Alaikum! I am SehatAI, your medical guidance assistant for Pakistan.\n\n'
          'Aap apni bimari ya symptoms English, Urdu (اردو) ya Roman Urdu mein likh ya bol sakte hain. (e.g. "Mujhe 2 din se bukhar hai").\n\n'
          '⚠️ Note: I provide preliminary triage and guidance, not a definitive medical diagnosis.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      quickActions: [
        'Mujhe 2 din se tez bukhar hai',
        'Chest pain & shortness of breath',
        'Khana khane ke baad seene mein jalan',
      ],
    ),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _inputController.text.trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _inputController.clear();
    }

    setState(() {
      _messages.add(AiChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Compile conversation history for multi-turn context
    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'message': m.text,
            })
        .toList();

    // Patient profile from active session
    final patientProfile = AuthService().currentUserOrNull;

    try {
      final triage = await _aiTriageService.analyzeSymptoms(
        message: text,
        language: _selectedLanguage,
        sessionId: _sessionId,
        history: history,
        patientProfile: patientProfile,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(AiChatMessage(
            text: triage.reply,
            isUser: false,
            timestamp: DateTime.now(),
            detectedRisk: triage.riskLevel,
            quickActions: triage.quickActions,
          ));
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
  }


  void _handleQuickAction(String action, String messageText) {
    if (action.contains('Emergency') || action.contains('SOS') || action.contains('1122')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EmergencyScreen(initialSymptom: messageText),
        ),
      );
    } else if (action.contains('Doctor')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DoctorListScreen(),
        ),
      );
    } else {
      _sendMessage(action);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.auto_awesome, color: AppColors.textWhite, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SehatAI Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Multilingual AI Triage • Active',
                  style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Emergency SOS',
            icon: const Icon(Icons.emergency_rounded, color: AppColors.emergency),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EmergencyScreen()),
              );
            },
          ),
        ],
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Language Switcher bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Language (زبان):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  LanguageSelector(
                    selectedLanguage: _selectedLanguage,
                    onLanguageChanged: (lang) {
                      setState(() => _selectedLanguage = lang);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Chat Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Voice Input simulated button
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, color: AppColors.primary),
                    tooltip: 'Speak in Urdu or English',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎙️ Voice Input: "Mujhe 2 din se tez bukhar hai" simulated.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      setState(() {
                        _inputController.text = 'Mujhe 2 din se tez bukhar hai aur sar dard hai';
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _selectedLanguage == AppLanguage.urdu
                            ? 'اپنی علامات یہاں لکھیں...'
                            : _selectedLanguage == AppLanguage.romanUrdu
                                ? 'Apni bimari yahan likhein (e.g. bukhar, dard)...'
                                : 'Type your symptoms here...',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.textWhite, size: 20),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!msg.isUser) ...[
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? AppColors.primary
                        : (msg.detectedRisk == TriageRiskLevel.high
                            ? AppColors.emergencyLight
                            : AppColors.surface),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                    ),
                    border: msg.isUser
                        ? null
                        : Border.all(
                            color: msg.detectedRisk == TriageRiskLevel.high
                                ? AppColors.emergency.withOpacity(0.4)
                                : AppColors.border,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.detectedRisk != null) ...[
                        RiskIndicatorBadge(riskLevel: msg.detectedRisk!),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: msg.isUser
                              ? AppColors.textWhite
                              : (msg.detectedRisk == TriageRiskLevel.high
                                  ? AppColors.emergencyDark
                                  : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (msg.isUser) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.person, size: 16, color: AppColors.textWhite),
                ),
              ],
            ],
          ),
          if (msg.quickActions != null && msg.quickActions!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: msg.quickActions!.map((action) {
                  final isEmergency = action.contains('SOS') || action.contains('1122');
                  return ActionChip(
                    backgroundColor: isEmergency ? AppColors.emergencyLight : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isEmergency ? AppColors.emergency : AppColors.primaryLight,
                      ),
                    ),
                    label: Text(
                      action,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isEmergency ? AppColors.emergencyDark : AppColors.primary,
                      ),
                    ),
                    onPressed: () => _handleQuickAction(action, msg.text),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedLanguage == AppLanguage.urdu
                      ? 'رہنمائی تیار کی جا رہی ہے...'
                      : 'SehatAI is analyzing symptoms...',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
