class ChatMessage {
  final String id;
  final String role;
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
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
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

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    List<ChatAttachment>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
    );
  }
}

// Import for ChatAttachment
class ChatAttachment {
  final String id;
  final String type;
  final String url;
  final String? name;
  final int? size;

  ChatAttachment({
    required this.id,
    required this.type,
    required this.url,
    this.name,
    this.size,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'] ?? '',
      type: json['type'] ?? 'unknown',
      url: json['url'] ?? '',
      name: json['name'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'name': name,
      'size': size,
    };
  }
}
