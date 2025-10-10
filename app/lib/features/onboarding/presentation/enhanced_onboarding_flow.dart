import 'package:flutter/material.dart';
import 'marketing_pages.dart';
import 'marketing_pages_2.dart';
import 'marketing_pages_3.dart';
import 'onboarding_wizard.dart';
import '../../profile/profile_service.dart';

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
    // Enhanced flow steps
    switch (_currentStep) {
      case 0:
        // Welcome page with social proof
        return WelcomePage(onContinue: _nextStep);
      
      case 1:
        // Goal selection
        return GoalSelectionPage(
          onGoalSelected: (goal) {
            setState(() => _selectedGoal = goal);
            _nextStep();
          },
        );
      
      case 2:
        // Results/expectations page
        return ResultsPage(onContinue: _nextStep);
      
      case 3:
        // Progress graph visualization
        return ProgressGraphPage(onContinue: _nextStep);
      
      case 4:
        // App features carousel
        return AppFeaturesCarouselPage(onContinue: _nextStep);
      
      case 5:
        // Notification timing
        return NotificationTimingPage(
          onTimingSelected: (timing) {
            setState(() => _notificationTiming = timing);
            _nextStep();
          },
        );
      
      case 6:
        // Existing onboarding wizard (skin concerns, etc.)
        return OnboardingWizard(
          key: const Key('onboarding_wizard'),
          onComplete: _nextStep,
        );
      
      case 7:
        // Thank you page
        return ThankYouPage(
          onReview: () {
            // Open app store review
            // TODO: Implement app store review
            debugPrint('Opening app store review');
          },
          onContinue: _nextStep,
        );
      
      case 8:
        // Free trial offer
        return FreeTrialOfferPage(
          onAccept: _nextStep,
          onSkip: () {
            // Skip to end
            _completeOnboarding();
          },
        );
      
      case 9:
        // Timeline visualization
        return TimelineVisualizationPage(onContinue: _nextStep);
      
      case 10:
        // Payment page
        return PaymentPage(
          onComplete: (didComplete) {
            if (didComplete) {
              // Payment successful
              _completeOnboarding();
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
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
}
