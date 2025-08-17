import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_attachment.dart';
import '../models/chat_stream_chunk.dart';
import '../services/personalization_service.dart';
import '../../../services/env.dart';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final List<ChatAttachment>? attachments;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.attachments,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => ChatAttachment.fromJson(a))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'attachments': attachments?.map((a) => a.toJson()).toList(),
    };
  }
}

class ChatAttachment {
  final String type;
  final String url;
  final String filename;
  final int size;
  final String mimeType;

  ChatAttachment({
    required this.type,
    required this.url,
    required this.filename,
    required this.size,
    required this.mimeType,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      filename: json['filename'] ?? '',
      size: json['size'] ?? 0,
      mimeType: json['mime_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'filename': filename,
      'size': size,
      'mime_type': mimeType,
    };
  }
}

class ChatStreamChunk {
  final String type; // 'chunk', 'done', 'error'
  final String? content;
  final String? conversationId;
  final String? messageId;
  final String? error;

  ChatStreamChunk({
    required this.type,
    this.content,
    this.conversationId,
    this.messageId,
    this.error,
  });

  factory ChatStreamChunk.fromJson(Map<String, dynamic> json) {
    return ChatStreamChunk(
      type: json['type'] ?? 'chunk',
      content: json['content'],
      conversationId: json['conversation_id'],
      messageId: json['message_id'],
      error: json['error'],
    );
  }
}

class ChatRepository {
  final SupabaseClient _supabase;
  final String _functionUrl;
  final PersonalizationService _personalizationService;

  ChatRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client,
        _functionUrl = '${Env.supabaseUrl}/functions/v1/chat-proxy',
        _personalizationService = PersonalizationService(supabase: supabase);

  // Send message with streaming response
  Stream<ChatStreamChunk> sendMessageStream({
    required List<ChatMessage> messages,
    List<ChatAttachment>? attachments,
    String? conversationId,
    bool personalizationEnabled = true,
  }) async* {
    try {
      final request = http.Request('POST', Uri.parse(_functionUrl));
      
      // Add headers
      final session = _supabase.auth.currentSession;
      if (session?.accessToken == null) {
        throw Exception('User not authenticated');
      }
      
      request.headers.addAll({
        'Authorization': 'Bearer ${session!.accessToken}',
        'Content-Type': 'application/json',
        'apikey': Env.supabaseAnonKey!,
      });

      // Task 4.0: Add personalization context if enabled
      Map<String, dynamic>? personalizationContext;
      if (personalizationEnabled) {
        final context = await _personalizationService.getPersonalizationContext(
          personalizationEnabled: true,
        );
        if (context != null) {
          personalizationContext = _personalizationService.sanitizeContextForAI(context);
        }
      }

      // Add request body
      final requestBody = {
        'messages': messages.map((m) => m.toJson()).toList(),
        'attachments': attachments?.map((a) => a.toJson()).toList(),
        'conversation_id': conversationId,
        'settings': {
          'personalization_enabled': personalizationEnabled,
          'stream': true,
        },
        if (personalizationContext != null) 'personalization_context': personalizationContext,
      };
      
      request.body = jsonEncode(requestBody);

      // Send request and handle streaming response
      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('Chat request failed: ${streamedResponse.statusCode} - $errorBody');
      }

      // Parse SSE stream
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data.isNotEmpty && data != '[DONE]') {
              try {
                final json = jsonDecode(data);
                yield ChatStreamChunk.fromJson(json);
              } catch (e) {
                // Skip malformed JSON chunks
                continue;
              }
            }
          }
        }
      }
    } catch (e) {
      yield ChatStreamChunk(
        type: 'error',
        error: e.toString(),
      );
    }
  }

  // Send message with regular response (non-streaming)
  Future<ChatMessage> sendMessage({
    required List<ChatMessage> messages,
    List<ChatAttachment>? attachments,
    String? conversationId,
    bool personalizationEnabled = true,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session?.accessToken == null) {
        throw Exception('User not authenticated');
      }

      // Task 4.0: Add personalization context if enabled
      Map<String, dynamic>? personalizationContext;
      if (personalizationEnabled) {
        final context = await _personalizationService.getPersonalizationContext(
          personalizationEnabled: true,
        );
        if (context != null) {
          personalizationContext = _personalizationService.sanitizeContextForAI(context);
        }
      }

      final requestBody = {
        'messages': messages.map((m) => m.toJson()).toList(),
        'attachments': attachments?.map((a) => a.toJson()).toList(),
        'conversation_id': conversationId,
        'settings': {
          'personalization_enabled': personalizationEnabled,
          'stream': false,
        },
        if (personalizationContext != null) 'personalization_context': personalizationContext,
      };

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Authorization': 'Bearer ${session!.accessToken}',
          'Content-Type': 'application/json',
          'apikey': Env.supabaseAnonKey!,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Chat request failed: ${response.statusCode} - ${response.body}');
      }

      final json = jsonDecode(response.body);
      return ChatMessage.fromJson(json['message']);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Generate a new message ID
  String generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // Generate a new conversation ID
  String generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // Task 5.1 & 5.2: Restore last conversation and persist messages
  Future<List<ChatMessage>> getLastConversation() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the most recent conversation
      final conversationResponse = await _supabase
          .from('chat_conversations')
          .select('id')
          .eq('user_id', user.id)
          .order('last_message_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (conversationResponse == null) {
        return [];
      }

      final conversationId = conversationResponse['id'] as String;

      // Get messages from the conversation
      final messagesResponse = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      return messagesResponse.map<ChatMessage>((messageData) {
        return ChatMessage(
          id: messageData['message_id'] ?? messageData['id'],
          role: messageData['role'] ?? 'user',
          content: messageData['content'] ?? '',
          timestamp: DateTime.parse(messageData['created_at']),
          attachments: messageData['attachments'] != null
              ? (messageData['attachments'] as List)
                  .map((a) => ChatAttachment.fromJson(a))
                  .toList()
              : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load conversation: $e');
    }
  }

  Future<void> saveMessage(ChatMessage message, String conversationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Insert message into database
      await _supabase.from('chat_messages').insert({
        'user_id': user.id,
        'conversation_id': conversationId,
        'message_id': message.id,
        'role': message.role,
        'content': message.content,
        'attachments': message.attachments?.map((a) => a.toJson()).toList(),
        'created_at': message.timestamp.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save message: $e');
    }
  }

  Future<String?> getLastConversationId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('chat_conversations')
          .select('id')
          .eq('user_id', user.id)
          .order('last_message_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      throw Exception('Failed to get last conversation ID: $e');
    }
  }

  // Task 5.4: Per-user rate limit with backoff UX
  Future<bool> checkRateLimit() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false; // Not authenticated, deny
      }

      final now = DateTime.now();
      final windowStart = DateTime(now.year, now.month, now.day, now.hour, (now.minute ~/ 10) * 10);
      final windowEnd = windowStart.add(const Duration(minutes: 10));

      // Check current rate limit window
      final response = await _supabase
          .from('chat_rate_limits')
          .select('request_count')
          .eq('user_id', user.id)
          .eq('window_start', windowStart.toIso8601String())
          .maybeSingle();

      const maxRequestsPerWindow = 20; // 20 requests per 10-minute window

      if (response == null) {
        // Create new rate limit window
        await _supabase.from('chat_rate_limits').insert({
          'user_id': user.id,
          'window_start': windowStart.toIso8601String(),
          'window_end': windowEnd.toIso8601String(),
          'request_count': 1,
        });
        return true;
      } else {
        final currentCount = response['request_count'] as int;
        if (currentCount >= maxRequestsPerWindow) {
          return false; // Rate limited
        }

        // Increment request count
        await _supabase
            .from('chat_rate_limits')
            .update({'request_count': currentCount + 1})
            .eq('user_id', user.id)
            .eq('window_start', windowStart.toIso8601String());
        
        return true;
      }
    } catch (e) {
      debugPrint('Rate limit check failed: $e');
      return true; // Allow on error to avoid blocking users
    }
  }
}
