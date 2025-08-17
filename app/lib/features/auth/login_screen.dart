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
        context.go('/tabs');
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
        context.go('/tabs');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gradient header
                  Container(
                    height: 160,
                    decoration: Brand.gradientDecoration(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Skincare Tracker',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Overlapping card with form
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Container(
                      decoration: Brand.cardDecoration(context),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Social-first layout (disabled per MVP)
                            const Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _DisabledSocialButton(label: 'Continue with Google'),
                                _DisabledSocialButton(label: 'Continue with Apple'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Social sign-in coming soon',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              key: const Key('emailField'),
                              controller: _emailCtrl,
                              decoration: const InputDecoration(labelText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                              validator: _validateEmail,
                              enabled: !_loading,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('passwordField'),
                              controller: _passwordCtrl,
                              decoration: const InputDecoration(labelText: 'Password'),
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              validator: _validatePassword,
                              enabled: !_loading,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                key: const Key('forgotPasswordLink'),
                                onPressed: _loading ? null : () => context.push('/reset'),
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_error != null)
                              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                            const SizedBox(height: 8),
                            FilledButton(
                              key: const Key('submitButton'),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Sign in'),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  key: const Key('termsLink'),
                                  onPressed: termsEnabled ? () => _openUrl(terms) : null,
                                  child: const Text('Terms'),
                                ),
                                const Text('·'),
                                TextButton(
                                  key: const Key('privacyLink'),
                                  onPressed: privacyEnabled ? () => _openUrl(privacy) : null,
                                  child: const Text('Privacy'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
