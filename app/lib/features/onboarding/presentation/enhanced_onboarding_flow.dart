import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'marketing_pages.dart';
import 'marketing_pages_2.dart';
import 'marketing_pages_3.dart';
import 'marketing_pages.dart';
import 'marketing_pages_2.dart';
import 'marketing_pages_3.dart';
import 'question_pages.dart';
import 'onboarding_wizard.dart';
import '../../profile/profile_service.dart';
import '../../../widgets/page_transitions.dart';
import '../../../services/session.dart';

/// Enhanced onboarding flow coordinator with Dusty Rose & Charcoal design
class EnhancedOnboardingFlow extends StatefulWidget {
  const EnhancedOnboardingFlow({super.key});

  @override
  State<EnhancedOnboardingFlow> createState() => _EnhancedOnboardingFlowState();
}

class _EnhancedOnboardingFlowState extends State<EnhancedOnboardingFlow> {
  int _currentStep = 0;
  String? _selectedGoal;
  String? _notificationTiming;
  int _currentStep = 0;
  String? _selectedGoal;
  String? _notificationTiming;
  Map<String, double>? _skinConcerns;
  String? _skinType;
  bool _showDiscountOffer = false;

  void _nextStep() {
    setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _completeOnboarding() async {
    // Save any final data
    await ProfileService.instance.markOnboardingCompleted();
    
    if (!mounted) return;
    
    // Navigate to main app
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for reduced motion preference
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    // Enhanced flow steps with cross-fade transition
    return AnimatedSwitcher(
      duration: reducedMotion 
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 300),
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      transitionBuilder: (child, animation) {
        if (reducedMotion) return child;
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Welcome page with social proof
        return WelcomePage(key: const ValueKey(0), onContinue: _nextStep);
      
      case 1:
        // Goal selection
        return GoalSelectionPage(
          key: const ValueKey(1),
          onGoalSelected: (goal) {
            setState(() => _selectedGoal = goal);
            _nextStep();
          },
        );
      
      case 2:
        // Results/expectations page
        return ResultsPage(key: const ValueKey(2), onContinue: _nextStep);
      
      case 3:
        // Progress graph visualization
        return ProgressGraphPage(key: const ValueKey(3), onContinue: _nextStep);
      
      case 4:
        // App features carousel
        return AppFeaturesCarouselPage(key: const ValueKey(4), onContinue: _nextStep);
      
      case 5:
        // Notification timing
        return NotificationTimingPage(
          key: const ValueKey(5),
          onTimingSelected: (timing) {
            setState(() => _notificationTiming = timing);
            _nextStep();
          },
        );
      
      case 6:
        // Skin concerns (New UI)
        return SkinConcernsPage(
          key: const ValueKey(6),
          onConcernsSelected: (concerns) {
            setState(() => _skinConcerns = concerns);
            // Save to profile/state if needed
            _nextStep();
          },
        );

      case 7:
        // Skin type (New UI)
        return SkinTypePage(
          key: const ValueKey(7),
          onSkinTypeSelected: (type) {
            setState(() => _skinType = type);
            // Save to profile/state if needed
            _nextStep();
          },
        );
      
      case 8:
        // Existing onboarding wizard (remaining steps)
        return OnboardingWizard(
          key: const ValueKey(8),
          onComplete: _nextStep,
        );
      
      case 9:
        // Thank you page
        return ThankYouPage(
          key: const ValueKey(9),
          onReview: () {
            // Open app store review
            // TODO: Implement app store review
            debugPrint('Opening app store review');
          },
          onContinue: _nextStep,
        );
      
      case 10:
        // Free trial offer
        return FreeTrialOfferPage(
          key: const ValueKey(10),
          onAccept: _nextStep,
          onSkip: () {
            // Skip to end
            _completeOnboarding();
          },
        );
      
      case 11:
        // Timeline visualization
        return TimelineVisualizationPage(key: const ValueKey(11), onContinue: _nextStep);
      
      case 12:
        // Payment page
        return PaymentPage(
          key: const ValueKey(12),
          onComplete: (didComplete) {
            if (didComplete) {
              // Payment successful
              if (!SessionService.instance.isSignedIn) {
                if (mounted) {
                  // Redirect unsigned users to sign up / log in before entering main app
                  context.go('/auth');
                }
              } else {
                _completeOnboarding();
              }
            } else {
              // User closed payment - show discount
              setState(() => _showDiscountOffer = true);
            }
          },
        );
      
      default:
        // Show discount offer if user declined payment
        if (_showDiscountOffer) {
          return SpecialDiscountPage(
            key: const ValueKey(13),
            onAccept: () {
              // Accept discount and complete
              _completeOnboarding();
            },
            onDecline: () {
              // Decline and complete anyway
              _completeOnboarding();
            },
          );
        }
        
        // Fallback - complete onboarding
        Future.microtask(_completeOnboarding);
        return const Scaffold(
          key: ValueKey(99),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
}
