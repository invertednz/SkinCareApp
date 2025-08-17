class ChatAttachment {
  final String id;
  final String type;
  final String url;
  final String? name;
  final int? size;
  final Map<String, dynamic>? metadata;

  ChatAttachment({
    required this.id,
    required this.type,
    required this.url,
    this.name,
    this.size,
    this.metadata,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'] ?? '',
      type: json['type'] ?? 'unknown',
      url: json['url'] ?? '',
      name: json['name'],
      size: json['size'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'name': name,
      'size': size,
      'metadata': metadata,
    };
  }

  ChatAttachment copyWith({
    String? id,
    String? type,
    String? url,
    String? name,
    int? size,
    Map<String, dynamic>? metadata,
  }) {
    return ChatAttachment(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      name: name ?? this.name,
      size: size ?? this.size,
      metadata: metadata ?? this.metadata,
    );
  }
}
