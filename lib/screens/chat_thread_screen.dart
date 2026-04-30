import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../widgets/profile_avatar.dart';

class ChatThreadScreen extends StatefulWidget {
  final String conversationId;
  const ChatThreadScreen({super.key, required this.conversationId});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _chat = ChatService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  
  String _otherPersonName = 'Chargement...';
  String? _otherPersonImage;
  bool _isLawyerContext = false;
  
  PlatformFile? _attachedFile;
  bool _isSending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadOtherPersonName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final conversation = await _chat.getConversation(widget.conversationId);
    if (conversation == null) return;

    final bool iAmTheLawyer = conversation.lawyerId == uid;
    if (mounted) setState(() => _isLawyerContext = iAmTheLawyer);
    
    String otherName = '';
    String? otherImage;
    try {
      if (iAmTheLawyer) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(conversation.userId).get();
        if (userDoc.exists) {
          final data = userDoc.data() ?? {};
          otherName = (data['fullName'] ?? data['full_name'] ?? data['name'] ?? data['displayName'] ?? '').toString().trim();
          otherImage = data['profileImageBase64'];
        }
        if (otherName.isEmpty && conversation.userName != null) {
          otherName = conversation.userName!.trim();
        }
        if (otherName.isEmpty) otherName = 'Client';
      } else {
        final lawyerDoc = await FirebaseFirestore.instance.collection('lawyers').doc(conversation.lawyerId).get();
        if (lawyerDoc.exists) {
          final data = lawyerDoc.data() ?? {};
          otherName = (data['name'] ?? data['fullName'] ?? data['full_name'] ?? '').toString().trim();
          otherImage = data['profileImageBase64'];
        }
        if (otherName.isEmpty && conversation.lawyerName != null) {
          otherName = conversation.lawyerName!.trim();
        }
        if (otherName.isEmpty) otherName = 'Avocat';
      }
    } catch (e) {
      otherName = iAmTheLawyer ? 'Client' : 'Avocat';
    }

    if (mounted) {
      setState(() {
        _otherPersonName = otherName;
        _otherPersonImage = otherImage;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOtherPersonName();
  }

  Future<void> _pickFile() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
      withData: true, // We need the bytes to convert to base64
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      // Check size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le fichier est trop grand (Max 5MB)')),
        );
        return;
      }
      setState(() => _attachedFile = file);
    }
  }

  Future<void> _send() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final text = _ctrl.text.trim();
    if (text.isEmpty && _attachedFile == null) return;
    
    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();
    
    String? base64String;
    String? fileName;
    String? fileExtension;

    if (_attachedFile != null && _attachedFile!.bytes != null) {
      base64String = base64Encode(_attachedFile!.bytes!);
      fileName = _attachedFile!.name;
      fileExtension = _attachedFile!.extension;
    }

    final sentText = text;
    _ctrl.clear();
    setState(() => _attachedFile = null);

    try {
      await _chat.sendMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        text: sentText,
        attachedFileName: fileName,
        attachedFileType: fileExtension,
        attachedFileBase64: base64String,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAttachmentPreview() {
    if (_attachedFile == null) return const SizedBox.shrink();
    final isImage = ['jpg', 'jpeg', 'png'].contains(_attachedFile!.extension?.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0052D4).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(_attachedFile!.bytes!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF0052D4), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _attachedFile!.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(_attachedFile!.size / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
            onPressed: () => setState(() => _attachedFile = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel m, bool mine, Color primaryColor, Color myBubbleColor, Color theirBubbleColor, Color myTextColor, Color theirTextColor, bool isDark) {
    final hasAttachment = m.attachedFileName != null && m.attachedFileBase64 != null;
    final isImage = hasAttachment && ['jpg', 'jpeg', 'png'].contains(m.attachedFileType?.toLowerCase());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            ProfileAvatar(
              imageBase64: _otherPersonImage,
              name: _otherPersonName,
              size: 28,
              backgroundColor: primaryColor.withOpacity(0.2),
              borderColor: Colors.transparent,
              borderWidth: 0,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(hasAttachment && isImage ? 4 : 12),
              decoration: BoxDecoration(
                color: mine ? myBubbleColor : theirBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(mine ? 20 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 20),
                ),
                boxShadow: [
                  if (!mine && !isDark)
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  if (mine && !isDark)
                    BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (hasAttachment) ...[
                    if (isImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
                          child: Image.memory(
                            base64Decode(m.attachedFileBase64!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: EdgeInsets.only(bottom: m.text.isNotEmpty ? 8 : 0),
                        decoration: BoxDecoration(
                          color: mine ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insert_drive_file_rounded,
                              color: mine ? Colors.white : primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                m.attachedFileName!,
                                style: TextStyle(
                                  color: mine ? Colors.white : theirTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (m.text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (m.text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hasAttachment && isImage ? 8 : 0),
                      child: Text(
                        m.text,
                        style: TextStyle(
                          color: mine ? myTextColor : theirTextColor,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 4,
                      right: hasAttachment && isImage ? 8 : 0,
                      left: hasAttachment && isImage ? 8 : 0,
                    ),
                    child: Text(
                      _formatTime(m.createdAt),
                      style: TextStyle(
                        color: mine ? myTextColor.withOpacity(0.7) : theirTextColor.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (mine) const SizedBox(width: 22),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = _isLawyerContext; 
    
    final Color primaryColor = isDark ? const Color(0xFFC9A84C) : const Color(0xFF0052D4);
    final Color headerColor = isDark ? const Color(0xFF0D1B2A) : const Color(0xFF0052D4);
    final Color bgColor = isDark ? const Color(0xFF1B2D42) : const Color(0xFFF8FAFC);
    final Color myBubbleColor = isDark ? const Color(0xFFC9A84C) : const Color(0xFF0052D4);
    final Color theirBubbleColor = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final Color myTextColor = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final Color theirTextColor = isDark ? const Color(0xFFF0EDE8) : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: headerColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              ProfileAvatar(
                imageBase64: _otherPersonImage,
                name: _otherPersonName,
                size: 40,
                backgroundColor: Colors.white.withOpacity(0.2),
                borderColor: Colors.white.withOpacity(0.5),
                borderWidth: 1.5,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otherPersonName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'En ligne',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chat.streamMessages(widget.conversationId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }
                if (snap.hasError) {
                  return Center(child: Text('Erreur: ${snap.error}', style: const TextStyle(color: Colors.red)));
                }
                final list = snap.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.forum_rounded, size: 60, color: primaryColor.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Démarrez la discussion',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final mine = m.senderId == uid;
                    return _buildMessageBubble(m, mine, primaryColor, myBubbleColor, theirBubbleColor, myTextColor, theirTextColor, isDark);
                  },
                );
              },
            ),
          ),
          
          _buildAttachmentPreview(),
          
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2D42) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.attach_file_rounded, color: isDark ? const Color(0xFF8A9BB0) : const Color(0xFF64748B)),
                    onPressed: _isSending ? null : _pickFile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2D42) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'Tapez votre message...',
                        hintStyle: TextStyle(color: isDark ? const Color(0xFF8A9BB0) : Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isSending ? null : _send,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isSending ? Colors.grey : primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: _isSending ? [] : [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Icon(Icons.send_rounded, color: isDark ? const Color(0xFF0D1B2A) : Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
