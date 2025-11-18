import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/env.dart';
import '../../theme/brand.dart';
import '../../services/session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // Debug mock mode: bypass Supabase and mark as signed-in
      if (kDebugMode) {
        SessionService.instance.setMockSignedIn(true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in (mock).')));
        context.go('/onboarding');
        return;
      }
      final supabase = Supabase.instance.client;
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      final res = await supabase.auth.signInWithPassword(email: email, password: password);
      if (res.user == null) {
        setState(() => _error = 'Unable to sign in.');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in.')));
        context.go('/onboarding');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (kDebugMode) return null; // allow any string in debug
    final emailRegex = RegExp(r'^.+@.+\..+$');
    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (kDebugMode) return null; // allow any length in debug
    if (v.length < 8) return 'At least 8 characters';
    return null;
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final terms = Env.termsUrl;
    final privacy = Env.privacyUrl;
    final termsEnabled = terms != null && terms.isNotEmpty;
    final privacyEnabled = privacy != null && privacy.isNotEmpty;
    return Scaffold(
      backgroundColor: Brand.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo/Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: Brand.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: Brand.primaryStart.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.spa_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Welcome to SkinCare',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Brand.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your journey to healthier skin starts here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Brand.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Brand.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Brand.primaryStart.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Social buttons (disabled)
                          const Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _DisabledSocialButton(label: 'Continue with Google'),
                              _DisabledSocialButton(label: 'Continue with Apple'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Social sign-in coming soon',
                            style: TextStyle(
                              fontSize: 12,
                              color: Brand.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Brand.borderMedium)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Or continue with email',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Brand.textTertiary,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Brand.borderMedium)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Email field
                          TextFormField(
                            key: const Key('emailField'),
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, color: Brand.primaryStart),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Brand.borderMedium),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Brand.borderMedium),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Brand.primaryStart, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            validator: _validateEmail,
                            enabled: !_loading,
                          ),
                          const SizedBox(height: 16),
                          // Password field
                          TextFormField(
                            key: const Key('passwordField'),
                            controller: _passwordCtrl,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline, color: Brand.primaryStart),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Brand.borderMedium),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Brand.borderMedium),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Brand.primaryStart, width: 2),
                              ),
                            ),
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            validator: _validatePassword,
                            enabled: !_loading,
                          ),
                          const SizedBox(height: 12),
                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const Key('forgotPasswordLink'),
                              onPressed: _loading ? null : () => context.push('/reset'),
                              style: TextButton.styleFrom(
                                foregroundColor: Brand.primaryStart,
                              ),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          // Sign in button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              key: const Key('submitButton'),
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Brand.primaryStart,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: Brand.borderMedium,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Terms & Privacy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        key: const Key('termsLink'),
                        onPressed: termsEnabled ? () => _openUrl(terms) : null,
                        style: TextButton.styleFrom(
                          foregroundColor: Brand.textTertiary,
                        ),
                        child: const Text('Terms'),
                      ),
                      Text('·', style: TextStyle(color: Brand.textTertiary)),
                      TextButton(
                        key: const Key('privacyLink'),
                        onPressed: privacyEnabled ? () => _openUrl(privacy) : null,
                        style: TextButton.styleFrom(
                          foregroundColor: Brand.textTertiary,
                        ),
                        child: const Text('Privacy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisabledSocialButton extends StatelessWidget {
  const _DisabledSocialButton({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.lock_outline),
      label: Text(label),
    );
  }
}
