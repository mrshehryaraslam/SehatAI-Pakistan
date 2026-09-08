import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/consultation_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/consultation_service.dart';

class ChatScreen extends StatefulWidget {
  final ConsultationModel consultation;

  const ChatScreen({super.key, required this.consultation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessageModel> _messages;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.consultation.chatMessages);
    _loadMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool force = false}) async {
    final liveMessages = await ConsultationService().fetchMessages(widget.consultation.id);
    if (mounted) {
      if (force ||
          liveMessages.length != _messages.length ||
          (liveMessages.isNotEmpty && _messages.isNotEmpty && liveMessages.last.id != _messages.last.id)) {
        setState(() {
          _messages = liveMessages;
        });
        _scrollToBottom();
      }
    }
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final success = await ConsultationService().sendMessage(widget.consultation.id, text);
    if (success) {
      _messageController.clear();
      await _loadMessages(force: true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message.'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = AuthService().currentUser.role == UserRole.doctor;
    final otherPartyName = isDoctor ? widget.consultation.patient.fullName : widget.consultation.doctor.name;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryContainer,
              child: Icon(
                isDoctor ? Icons.person : Icons.medical_services_outlined,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherPartyName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Encrypted Telehealth Session',
                    style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_outlined, color: AppColors.emergency),
            tooltip: 'Emergency Alert',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency escalation shortcut triggered.'),
                  backgroundColor: AppColors.emergency,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Warning Notice Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primaryContainer.withOpacity(0.4),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Doctor-patient consultation thread. For extreme emergencies, dial 1122 immediately.',
                      style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),

            // Message Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  // Attachment Icon
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppColors.textMuted),
                    tooltip: 'Attach Lab Report or Image',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📎 Attachment uploaded: Lab_Report_CBC.pdf'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
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
                      icon: const Icon(Icons.send_rounded, color: AppColors.textWhite, size: 18),
                      onPressed: _sendMessage,
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

  Widget _buildChatBubble(ChatMessageModel msg) {
    if (msg.isEmergencyNotice) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.emergencyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.emergency.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyDark, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg.message,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emergencyDark),
              ),
            ),
          ],
        ),
      );
    }

    final isMe = msg.senderId == AuthService().currentUser.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            msg.senderName,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: isMe ? null : Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              msg.message,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? AppColors.textWhite : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            Formatters.formatTime(msg.timestamp),
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
