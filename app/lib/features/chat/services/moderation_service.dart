import 'dart:async';

enum ModerationCategory {
  inappropriateContent,
  medicalAdviceRequest,
  harassment,
  spam,
  violence,
  selfHarm,
  adultContent,
}

class ModerationResult {
  final bool passed;
  final List<ModerationCategory> categories;
  final double confidence;
  final String? blockedReason;
  final String? supportiveMessage;
  
  /// Whether to show crisis resources
  bool get shouldShowCrisisResources => categories.contains(ModerationCategory.selfHarm);
  
  /// Get crisis resources if needed
  Map<String, String> get crisisResources => shouldShowCrisisResources 
      ? ModerationService().getCrisisResources() 
      : {};

  ModerationResult({
    required this.passed,
    required this.categories,
    required this.confidence,
    this.blockedReason,
    this.supportiveMessage,
  });

  factory ModerationResult.fromJson(Map<String, dynamic> json) {
    return ModerationResult(
      passed: json['passed'] ?? true,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((c) => _categoryFromString(c.toString()))
          .where((c) => c != null)
          .cast<ModerationCategory>()
          .toList() ?? [],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      blockedReason: json['blocked_reason'],
      supportiveMessage: json['supportive_message'],
    );
  }

  static ModerationCategory? _categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'inappropriate_content':
        return ModerationCategory.inappropriateContent;
      case 'medical_advice_request':
        return ModerationCategory.medicalAdviceRequest;
      case 'harassment':
        return ModerationCategory.harassment;
      case 'spam':
        return ModerationCategory.spam;
      case 'violence':
        return ModerationCategory.violence;
      case 'self_harm':
        return ModerationCategory.selfHarm;
      case 'adult_content':
        return ModerationCategory.adultContent;
      default:
        return null;
    }
  }
}

class ModerationService {
  static final ModerationService _instance = ModerationService._internal();
  factory ModerationService() => _instance;
  ModerationService._internal();

  // Task 3.1: Central moderation utility with categories per PRD
  Future<ModerationResult> moderateContent(String content) async {
    try {
      // Client-side pre-moderation for immediate feedback
      final clientResult = _clientSideModeration(content);
      
      if (!clientResult.passed) {
        return clientResult;
      }

      // TODO: Integrate with server-side moderation for more comprehensive checking
      // For now, return the client-side result
      return clientResult;
    } catch (e) {
      // If moderation fails, err on the side of caution but don't block
      return ModerationResult(
        passed: true,
        categories: [],
        confidence: 0.0,
        blockedReason: 'moderation_error',
      );
    }
  }

  ModerationResult _clientSideModeration(String content) {
    final lowerContent = content.toLowerCase();
    final blockedCategories = <ModerationCategory>[];
    double maxConfidence = 0.0;

    // Check for self-harm content
    final selfHarmPatterns = [
      RegExp(r'\b(suicide|self.?harm|kill.?myself|end.?it.?all)\b', caseSensitive: false),
      RegExp(r'\b(want.?to.?die|better.?off.?dead)\b', caseSensitive: false),
    ];

    for (final pattern in selfHarmPatterns) {
      if (pattern.hasMatch(content)) {
        blockedCategories.add(ModerationCategory.selfHarm);
        maxConfidence = 0.9;
        break;
      }
    }

    // Check for inappropriate medical advice requests
    final medicalPatterns = [
      RegExp(r'\b(diagnose|diagnosis|what.?disease|medical.?condition)\b', caseSensitive: false),
      RegExp(r'\b(prescription|medication|drug.?dosage|treatment.?plan)\b', caseSensitive: false),
      RegExp(r'\b(doctor.?said|medical.?advice|professional.?opinion)\b', caseSensitive: false),
    ];

    for (final pattern in medicalPatterns) {
      if (pattern.hasMatch(content)) {
        blockedCategories.add(ModerationCategory.medicalAdviceRequest);
        maxConfidence = maxConfidence < 0.8 ? 0.8 : maxConfidence;
        break;
      }
    }

    // Check for harassment or inappropriate content
    final harassmentPatterns = [
      RegExp(r'\b(hate|stupid|idiot|moron)\b.*\b(you|assistant|ai)\b', caseSensitive: false),
      RegExp(r'\b(shut.?up|go.?away|useless)\b', caseSensitive: false),
    ];

    for (final pattern in harassmentPatterns) {
      if (pattern.hasMatch(content)) {
        blockedCategories.add(ModerationCategory.harassment);
        maxConfidence = maxConfidence < 0.7 ? 0.7 : maxConfidence;
        break;
      }
    }

    // Check for spam patterns
    final spamPatterns = [
      RegExp(r'(.)\1{10,}', caseSensitive: false), // Repeated characters
      RegExp(r'\b(buy.?now|click.?here|limited.?time)\b', caseSensitive: false),
    ];

    for (final pattern in spamPatterns) {
      if (pattern.hasMatch(content)) {
        blockedCategories.add(ModerationCategory.spam);
        maxConfidence = maxConfidence < 0.6 ? 0.6 : maxConfidence;
        break;
      }
    }

    final passed = blockedCategories.isEmpty;
    return ModerationResult(
      passed: passed,
      categories: blockedCategories,
      confidence: passed ? 0.1 : maxConfidence,
      blockedReason: passed ? null : 'client_side_filter',
      supportiveMessage: passed ? null : _getSupportiveMessage(blockedCategories),
    );
  }

  // Task 3.2: UX for blocked messages with supportive copy and resources link
  String _getSupportiveMessage(List<ModerationCategory> categories) {
    if (categories.contains(ModerationCategory.selfHarm)) {
      return "I understand you might be going through a difficult time. I'm here to help with skincare questions, but for serious concerns, please reach out to a mental health professional or crisis helpline. Is there something specific about your skincare routine I can help you with instead?";
    }

    if (categories.contains(ModerationCategory.medicalAdviceRequest)) {
      return "I can't provide medical diagnoses or treatment advice. For skin conditions that concern you, it's best to consult with a dermatologist or healthcare provider. However, I'm happy to discuss general skincare routines, product information, or help you track your skin health journey. What would you like to know?";
    }

    if (categories.contains(ModerationCategory.harassment)) {
      return "I want to keep our conversation respectful and helpful. I'm here to assist you with skincare questions and support your skin health journey. How can I help you today?";
    }

    if (categories.contains(ModerationCategory.spam)) {
      return "I noticed your message might contain spam-like content. I'm here to help with genuine skincare questions and support. What would you like to know about skincare?";
    }

    return "I want to keep our conversation focused on helpful skincare guidance. Let me know how I can assist you with your skincare routine, product questions, or tracking your skin health progress.";
  }

  // Get crisis resources for self-harm cases
  Map<String, String> getCrisisResources() {
    return {
      'National Suicide Prevention Lifeline': '988',
      'Crisis Text Line': 'Text HOME to 741741',
      'International Association for Suicide Prevention': 'https://www.iasp.info/resources/Crisis_Centres/',
      'Mental Health Resources': 'https://www.mentalhealth.gov/get-help/immediate-help',
    };
  }

  // Check if message should show crisis resources
  bool shouldShowCrisisResources(ModerationResult result) {
    return result.categories.contains(ModerationCategory.selfHarm);
  }
}
