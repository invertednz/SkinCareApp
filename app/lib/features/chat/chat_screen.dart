import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'data/chat_repository.dart';
import 'services/moderation_service.dart';
import '../../services/analytics_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final ModerationService _moderationService = ModerationService();
  
  List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  bool _isLoading = false;
  String? _currentConversationId;
  String _streamingContent = '';
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _loadLastConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  // Task 2.5: Restore last conversation on open
  Future<void> _loadLastConversation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get last conversation ID and messages
      final conversationId = await _chatRepository.getLastConversationId();
      final messages = await _chatRepository.getLastConversation();

      setState(() {
        _currentConversationId = conversationId;
        _messages = messages;
        _isLoading = false;
      });

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Don't show error for conversation loading failure
      // Just start with empty conversation
      debugPrint('Failed to load last conversation: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Task 2.3: Attachment picker with preview and size checks
  Future<void> _pickImage() async {
    if (_isStreaming) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Check file size (limit to 10MB)
        final file = File(image.path);
        final fileSize = await file.length();
        const maxSize = 10 * 1024 * 1024; // 10MB

        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image is too large. Please select an image under 10MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_isStreaming) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Check file size (limit to 10MB)
        final file = File(image.path);
        final fileSize = await file.length();
        const maxSize = 10 * 1024 * 1024; // 10MB

        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image is too large. Please select an image under 10MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Task 3.2: UX for blocked messages with supportive copy and resources link
  void _showModerationDialog(ModerationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Not Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.supportiveMessage ?? "We couldn't send that message. Please rephrase to keep it safe and focused on skincare."),
            if (result.shouldShowCrisisResources) ...[
              const SizedBox(height: 16),
              const Text(
                'If you\'re in crisis, please reach out:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...result.crisisResources.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${entry.key}: ${entry.value}'),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Task 5.4: Rate limit dialog with backoff UX
  void _showRateLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Limit Reached'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve reached the chat limit for this time period. Please wait a few minutes before sending another message.',
            ),
            SizedBox(height: 12),
            Text(
              'This helps us maintain service quality for all users.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Track rate limit hit for analytics
    AnalyticsService.capture('chat_rate_limit_hit', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if ((messageText.isEmpty && _selectedImages.isEmpty) || _isStreaming) return;

    // Task 5.4: Check rate limit before sending
    final rateLimitOk = await _chatRepository.checkRateLimit();
    if (!rateLimitOk) {
      _showRateLimitDialog();
      return;
    }

    // Task 3.1 & 3.2: Client-side moderation check
    if (messageText.isNotEmpty) {
      final moderationResult = await _moderationService.moderateContent(messageText);
      
      if (!moderationResult.passed) {
        // Task 3.3: Track chat_blocked_moderation with category
        AnalyticsService.capture('chat_blocked_moderation', {
          'categories': moderationResult.categories.map((c) => c.toString().split('.').last).toList(),
          'confidence': moderationResult.confidence,
          'blocked_reason': moderationResult.blockedReason,
          'message_length': messageText.length,
        });
        
        // Show supportive message for blocked content
        _showModerationDialog(moderationResult);
        return;
      }
    }

    // TODO: Upload attachments to Supabase Storage and create ChatAttachment objects
    List<ChatAttachment>? attachments;
    if (_selectedImages.isNotEmpty) {
      // For now, we'll create placeholder attachments
      // In a real implementation, you'd upload to Supabase Storage first
      attachments = _selectedImages.map((image) => ChatAttachment(
        type: 'image',
        url: image.path, // This would be the uploaded URL in production
        filename: image.name,
        size: 0, // Would get actual size after upload
        mimeType: 'image/jpeg',
      )).toList();
    }

    final userMessage = ChatMessage(
      id: _chatRepository.generateMessageId(),
      role: 'user',
      content: _messageController.text.trim().isNotEmpty ? _messageController.text.trim() : 'Shared an image',
      timestamp: DateTime.now(),
      attachments: attachments,
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _selectedImages.clear(); // Clear attachments after sending
      _isStreaming = true;
    });

    _scrollToBottom();

    // Task 5.5: Track analytics for chat interactions
    AnalyticsService.capture('chat_message_sent', {
      'message_length': userMessage.content.length,
      'has_attachments': userMessage.attachments?.isNotEmpty ?? false,
      'attachment_count': userMessage.attachments?.length ?? 0,
      'conversation_id': _currentConversationId,
    });

    try {
      // Create placeholder assistant message for streaming
      final assistantMessageId = _chatRepository.generateMessageId();
      final assistantMessage = ChatMessage(
        id: assistantMessageId,
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMessage);
      });

      // Stream the response
      await for (final chunk in _chatRepository.sendMessageStream(
        messages: _messages.where((m) => m.role == 'user').toList(),
        conversationId: _currentConversationId,
      )) {
        if (chunk.type == 'chunk' && chunk.content != null) {
          setState(() {
            _streamingContent += chunk.content!;
            // Update the last message (assistant message) with streaming content
            if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
              _messages[_messages.length - 1] = ChatMessage(
                id: assistantMessageId,
                role: 'assistant',
                content: _streamingContent,
                timestamp: DateTime.now(),
              );
            }
          });
          _scrollToBottom();
        } else if (chunk.type == 'done') {
          setState(() {
            _isStreaming = false;
          });
          
          // Task 5.2: Save messages to database after completion
          try {
            await _chatRepository.saveMessage(userMessage, _currentConversationId!);
            if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
              await _chatRepository.saveMessage(_messages.last, _currentConversationId!);
            }
          } catch (e) {
            debugPrint('Failed to save messages: $e');
          }

          // Task 5.5: Track successful chat completion
          AnalyticsService.capture('chat_response_completed', {
            'response_length': _streamingContent.length,
            'conversation_id': _currentConversationId,
            'response_time_ms': DateTime.now().difference(userMessage.timestamp).inMilliseconds,
          });
          
          break;
        } else if (chunk.type == 'error') {
          setState(() {
            _isStreaming = false;
            // Replace the streaming message with error message
            if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
              _messages[_messages.length - 1] = ChatMessage(
                id: assistantMessageId,
                role: 'assistant',
                content: 'Sorry, I encountered an error. Please try again.',
                timestamp: DateTime.now(),
              );
            }
          });

          // Task 5.5: Track chat errors for analytics
          AnalyticsService.capture('chat_error', {
            'error_type': 'streaming_error',
            'conversation_id': _currentConversationId,
            'error_details': chunk.error ?? 'Unknown streaming error',
          });
          
          break;
        }
      }
    } catch (e) {
      setState(() {
        _isStreaming = false;
        // Add error message
        _messages.add(ChatMessage(
          id: _chatRepository.generateMessageId(),
          role: 'assistant',
          content: 'Sorry, I encountered an error. Please try again.',
          timestamp: DateTime.now(),
        ));
      });

      // Task 5.5: Track chat errors for analytics
      AnalyticsService.capture('chat_error', {
        'error_type': 'request_error',
        'conversation_id': _currentConversationId,
        'error_details': e.toString(),
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Assistant'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _isStreaming ? null : _showAttachmentOptions,
            tooltip: 'Add attachment',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start a conversation!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ask me about skincare routines, products, or track your skin health journey.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _ChatMessageWidget(
                        message: message,
                        isStreaming: _isStreaming && 
                                   index == _messages.length - 1 && 
                                   message.role == 'assistant',
                      );
                    },
                  ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                // Attachment previews
                if (_selectedImages.isNotEmpty) ...[
                  Container(
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        final image = _selectedImages[index];
                        return Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(image.path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                // Text input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        enabled: !_isStreaming,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: _isStreaming 
                              ? 'AI is responding...' 
                              : 'Ask about your skincare...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      onPressed: _isStreaming ? null : _sendMessage,
                      child: _isStreaming 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;

  const _ChatMessageWidget({
    required this.message,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.smart_toy,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser 
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isStreaming) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
