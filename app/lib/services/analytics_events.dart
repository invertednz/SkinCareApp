/// Centralized analytics event constants for compile-time safety
/// This ensures all analytics events are properly typed and prevents typos
class AnalyticsEvents {
  // App lifecycle
  static const String appLaunch = 'app_launch';
  static const String appBackground = 'app_background';
  static const String appForeground = 'app_foreground';
  
  // Screen views (handled automatically by router observer)
  static const String screenView = 'screen_view';
  
  // Authentication events
  static const String authStart = 'auth_start';
  static const String authSuccess = 'auth_success';
  static const String authFailure = 'auth_failure';
  static const String authSignOut = 'auth_sign_out';
  
  // Onboarding events
  static const String onboardingStart = 'onboarding_start';
  static const String onboardingStepSubmit = 'onboarding_step_submit';
  static const String onboardingComplete = 'onboarding_complete';
  static const String onboardingSkip = 'onboarding_skip';
  
  // Paywall and IAP events
  static const String paywallView = 'paywall_view';
  static const String paywallSelectPlan = 'paywall_select_plan';
  static const String startTrial = 'start_trial';
  static const String purchaseInitiated = 'purchase_initiated';
  static const String purchasePending = 'purchase_pending';
  static const String purchaseSuccess = 'purchase_success';
  static const String purchaseFailure = 'purchase_failure';
  static const String purchaseCanceled = 'purchase_canceled';
  static const String purchaseRestored = 'purchase_restored';
  static const String restorePurchasesInitiated = 'restore_purchases_initiated';
  static const String restorePurchasesFailure = 'restore_purchases_failure';
  static const String entitlementSync = 'entitlement_sync';
  static const String entitlementSyncError = 'entitlement_sync_error';
  static const String purchaseSyncSuccess = 'purchase_sync_success';
  static const String purchaseSyncFailure = 'purchase_sync_failure';
  static const String purchaseSyncException = 'purchase_sync_exception';
  static const String iapInitFailure = 'iap_init_failure';
  static const String productLoadFailure = 'product_load_failure';
  static const String productLoadException = 'product_load_exception';
  static const String productsNotFound = 'products_not_found';
  static const String purchaseValidationError = 'purchase_validation_error';
  static const String subscriptionInitFailure = 'subscription_init_failure';
  
  // Diary logging events
  static const String logCreateSkin = 'log_create_skin';
  static const String logCreateSymptoms = 'log_create_symptoms';
  static const String logCreateDiet = 'log_create_diet';
  static const String logCreateSupplements = 'log_create_supplements';
  static const String logCreateRoutine = 'log_create_routine';
  static const String logCreateSleep = 'log_create_sleep';
  static const String logCreateStress = 'log_create_stress';
  static const String logCreateWater = 'log_create_water';
  static const String logUpdate = 'log_update';
  static const String logDelete = 'log_delete';
  static const String logView = 'log_view';
  
  // Photo events
  static const String photoUploadStart = 'photo_upload_start';
  static const String photoUploadSuccess = 'photo_upload_success';
  static const String photoUploadFailure = 'photo_upload_failure';
  static const String photoUploadCancel = 'photo_upload_cancel';
  static const String photoAnalyzeStart = 'photo_analyze_start';
  static const String photoAnalyzeSuccess = 'photo_analyze_success';
  static const String photoAnalyzeFailure = 'photo_analyze_failure';
  static const String photoDelete = 'photo_delete';
  static const String photoModerationBlock = 'photo_moderation_block';
  
  // Insights events
  static const String insightsGenerateRequest = 'insights_generate_request';
  static const String insightsGenerateSuccess = 'insights_generate_success';
  static const String insightsGenerateRateLimited = 'insights_generate_rate_limited';
  static const String insightsView = 'insights_view';
  static const String insightsAddToRoutine = 'insights_add_to_routine';
  static const String insightsRefresh = 'insights_refresh';
  
  // Chat events
  static const String chatOpen = 'chat_open';
  static const String chatMessageSent = 'chat_message_sent';
  static const String chatResponseCompleted = 'chat_response_completed';
  static const String chatError = 'chat_error';
  static const String chatStreamStart = 'chat_stream_start';
  static const String chatStreamEnd = 'chat_stream_end';
  static const String chatBlockedModeration = 'chat_blocked_moderation';
  static const String chatThumbsUp = 'chat_thumbsup';
  static const String chatThumbsDown = 'chat_thumbsdown';
  
  // Notification events
  static const String notificationDelivered = 'notification_delivered';
  static const String notificationOpen = 'notification_open';
  static const String notificationSettingsUpdate = 'notification_settings_update';
  static const String notificationPermissionRequest = 'notification_permission_request';
  static const String notificationPermissionGranted = 'notification_permission_granted';
  static const String notificationPermissionDenied = 'notification_permission_denied';
  
  // Navigation events
  static const String navigationTabSwitch = 'navigation_tab_switch';
  static const String navigationDeepLink = 'navigation_deep_link';
  
  // Error events
  static const String errorUnhandled = 'error_unhandled';
  static const String errorBoundary = 'error_boundary';
  static const String errorNetwork = 'error_network';
  static const String errorAuth = 'error_auth';
  
  // Privacy events
  static const String privacyOptOut = 'privacy_opt_out';
  static const String privacyOptIn = 'privacy_opt_in';
  static const String privacyDataRequest = 'privacy_data_request';
  static const String privacyDataDeletion = 'privacy_data_deletion';
}

/// Common property keys for analytics events
class AnalyticsProperties {
  // Common properties
  static const String timestamp = 'timestamp';
  static const String platform = 'platform';
  static const String screenName = 'screen_name';
  static const String userId = 'user_id';
  static const String sessionId = 'session_id';
  
  // Auth properties
  static const String authMethod = 'method';
  static const String errorCode = 'error_code';
  static const String error = 'error';
  
  // Onboarding properties
  static const String stepKey = 'step_key';
  static const String stepIndex = 'step_index';
  static const String totalSteps = 'total_steps';
  
  // Purchase properties
  static const String productId = 'product_id';
  static const String plan = 'plan';
  static const String price = 'price';
  static const String transactionId = 'transaction_id';
  static const String hasSubscription = 'has_subscription';
  static const String planType = 'plan_type';
  static const String expiresAt = 'expires_at';
  
  // Log properties
  static const String hasPhoto = 'has_photo';
  static const String logType = 'log_type';
  static const String entryCount = 'entry_count';
  
  // Photo properties
  static const String fileSize = 'file_size';
  static const String width = 'width';
  static const String height = 'height';
  static const String format = 'format';
  static const String moderationCategory = 'moderation_category';
  
  // Chat properties
  static const String hasImage = 'has_image';
  static const String durationMs = 'duration_ms';
  static const String messageLength = 'message_length';
  static const String category = 'category';
  
  // Notification properties
  static const String notificationType = 'notification_type';
  static const String permissionStatus = 'permission_status';
  
  // Navigation properties
  static const String fromTab = 'from_tab';
  static const String toTab = 'to_tab';
  static const String deepLinkPath = 'deep_link_path';
}

/// Validation helper for analytics events
class AnalyticsValidator {
  /// List of all valid event names for compile-time checking
  static const Set<String> validEvents = {
    // App lifecycle
    AnalyticsEvents.appLaunch,
    AnalyticsEvents.appBackground,
    AnalyticsEvents.appForeground,
    AnalyticsEvents.screenView,
    
    // Auth
    AnalyticsEvents.authStart,
    AnalyticsEvents.authSuccess,
    AnalyticsEvents.authFailure,
    AnalyticsEvents.authSignOut,
    
    // Onboarding
    AnalyticsEvents.onboardingStart,
    AnalyticsEvents.onboardingStepSubmit,
    AnalyticsEvents.onboardingComplete,
    AnalyticsEvents.onboardingSkip,
    
    // Paywall/IAP
    AnalyticsEvents.paywallView,
    AnalyticsEvents.paywallSelectPlan,
    AnalyticsEvents.startTrial,
    AnalyticsEvents.purchaseInitiated,
    AnalyticsEvents.purchasePending,
    AnalyticsEvents.purchaseSuccess,
    AnalyticsEvents.purchaseFailure,
    AnalyticsEvents.purchaseCanceled,
    AnalyticsEvents.purchaseRestored,
    AnalyticsEvents.restorePurchasesInitiated,
    AnalyticsEvents.restorePurchasesFailure,
    AnalyticsEvents.entitlementSync,
    AnalyticsEvents.entitlementSyncError,
    AnalyticsEvents.purchaseSyncSuccess,
    AnalyticsEvents.purchaseSyncFailure,
    AnalyticsEvents.purchaseSyncException,
    AnalyticsEvents.iapInitFailure,
    AnalyticsEvents.productLoadFailure,
    AnalyticsEvents.productLoadException,
    AnalyticsEvents.productsNotFound,
    AnalyticsEvents.purchaseValidationError,
    AnalyticsEvents.subscriptionInitFailure,
    
    // Diary logging
    AnalyticsEvents.logCreateSkin,
    AnalyticsEvents.logCreateSymptoms,
    AnalyticsEvents.logCreateDiet,
    AnalyticsEvents.logCreateSupplements,
    AnalyticsEvents.logCreateRoutine,
    AnalyticsEvents.logCreateSleep,
    AnalyticsEvents.logCreateStress,
    AnalyticsEvents.logCreateWater,
    AnalyticsEvents.logUpdate,
    AnalyticsEvents.logDelete,
    AnalyticsEvents.logView,
    
    // Photos
    AnalyticsEvents.photoUploadStart,
    AnalyticsEvents.photoUploadSuccess,
    AnalyticsEvents.photoUploadFailure,
    AnalyticsEvents.photoUploadCancel,
    AnalyticsEvents.photoAnalyzeStart,
    AnalyticsEvents.photoAnalyzeSuccess,
    AnalyticsEvents.photoAnalyzeFailure,
    AnalyticsEvents.photoDelete,
    AnalyticsEvents.photoModerationBlock,
    
    // Insights
    AnalyticsEvents.insightsGenerateRequest,
    AnalyticsEvents.insightsGenerateSuccess,
    AnalyticsEvents.insightsGenerateRateLimited,
    AnalyticsEvents.insightsView,
    AnalyticsEvents.insightsAddToRoutine,
    AnalyticsEvents.insightsRefresh,
    
    // Chat
    AnalyticsEvents.chatOpen,
    AnalyticsEvents.chatMessageSent,
    AnalyticsEvents.chatResponseCompleted,
    AnalyticsEvents.chatError,
    AnalyticsEvents.chatStreamStart,
    AnalyticsEvents.chatStreamEnd,
    AnalyticsEvents.chatBlockedModeration,
    AnalyticsEvents.chatThumbsUp,
    AnalyticsEvents.chatThumbsDown,
    
    // Notifications
    AnalyticsEvents.notificationDelivered,
    AnalyticsEvents.notificationOpen,
    AnalyticsEvents.notificationSettingsUpdate,
    AnalyticsEvents.notificationPermissionRequest,
    AnalyticsEvents.notificationPermissionGranted,
    AnalyticsEvents.notificationPermissionDenied,
    
    // Navigation
    AnalyticsEvents.navigationTabSwitch,
    AnalyticsEvents.navigationDeepLink,
    
    // Errors
    AnalyticsEvents.errorUnhandled,
    AnalyticsEvents.errorBoundary,
    AnalyticsEvents.errorNetwork,
    AnalyticsEvents.errorAuth,
    
    // Privacy
    AnalyticsEvents.privacyOptOut,
    AnalyticsEvents.privacyOptIn,
    AnalyticsEvents.privacyDataRequest,
    AnalyticsEvents.privacyDataDeletion,
  };
  
  /// Validate that an event name is in the approved list
  static bool isValidEvent(String eventName) {
    return validEvents.contains(eventName);
  }
  
  /// Get suggestions for similar event names (for debugging)
  static List<String> getSuggestions(String eventName) {
    return validEvents
        .where((event) => event.toLowerCase().contains(eventName.toLowerCase()))
        .toList();
  }
}
