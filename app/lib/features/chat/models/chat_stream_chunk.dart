class ChatStreamChunk {
  final String type;
  final String? content;
  final String? error;
  final Map<String, dynamic>? metadata;
  final bool isComplete;

  ChatStreamChunk({
    required this.type,
    this.content,
    this.error,
    this.metadata,
    this.isComplete = false,
  });

  factory ChatStreamChunk.fromJson(Map<String, dynamic> json) {
    return ChatStreamChunk(
      type: json['type'] ?? 'content',
      content: json['content'],
      error: json['error'],
      metadata: json['metadata'],
      isComplete: json['is_complete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
      'error': error,
      'metadata': metadata,
      'is_complete': isComplete,
    };
  }

  ChatStreamChunk copyWith({
    String? type,
    String? content,
    String? error,
    Map<String, dynamic>? metadata,
    bool? isComplete,
  }) {
    return ChatStreamChunk(
      type: type ?? this.type,
      content: content ?? this.content,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  bool get hasError => error != null;
  bool get hasContent => content != null && content!.isNotEmpty;
}
