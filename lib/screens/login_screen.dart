import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:microfinance_app/theme/app_tokens.dart';
import 'package:microfinance_app/widgets/premium/index.dart';

/// Authentication entry point.
///
/// The authentication logic is unchanged: the same
/// `signInWithPassword` / `signUp` calls against the same Supabase client,
/// with the same navigation target on success. Only presentation, validation
/// feedback and error wording have been reworked.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Maps Supabase auth errors to language a collection agent can act on,
  /// while the raw message still reaches the console for debugging.
  String _friendly(Object e) {
    debugPrint('[SVV] Auth error: $e');
    final msg = e is AuthException ? e.message : e.toString();
    final lower = msg.toLowerCase();
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'That email and password combination was not recognised.';
    }
    if (lower.contains('email not confirmed')) {
      return 'This account has not been confirmed yet. Check your inbox for '
          'the confirmation link.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('failed host')) {
      return 'Cannot reach the server. Check your internet connection.';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return msg;
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) {
        setState(() => _notice =
            'Account created. Check your email for a confirmation link, '
            'then sign in.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900;

    return Scaffold(
      backgroundColor: t.background,
      body: wide
          ? Row(
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTokens.space8),
                      child: _form(context),
                    ),
                  ),
                ),
              ],
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTokens.space6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _CompactBrand(),
                      const SizedBox(height: AppTokens.space8),
                      _form(context),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _form(BuildContext context) {
    final t = context.tokens;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sign in',
              style: TextStyle(
                color: t.foreground,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Access your collection records',
              style: TextStyle(color: t.mutedForeground, fontSize: 14),
            ),
            const SizedBox(height: AppTokens.space8),

            _Label('Email address'),
            const SizedBox(height: AppTokens.space2),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              enabled: !_loading,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              decoration: const InputDecoration(
                hintText: 'name@company.com',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 19),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Enter your email address';
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTokens.space5),

            _Label('Password'),
            const SizedBox(height: AppTokens.space2),
            TextFormField(
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              enabled: !_loading,
              onFieldSubmitted: (_) => _loading ? null : _signIn(),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 19,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Enter your password';
                if ((v ?? '').length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: AppTokens.space4),
              _Banner(
                text: _error!,
                tone: t.danger,
                icon: Icons.error_outline_rounded,
              ),
            ],
            if (_notice != null) ...[
              const SizedBox(height: AppTokens.space4),
              _Banner(
                text: _notice!,
                tone: t.success,
                icon: Icons.mark_email_read_outlined,
              ),
            ],

            const SizedBox(height: AppTokens.space6),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _signIn,
                child: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: t.onPrimary,
                        ),
                      )
                    : const Text('Sign In'),
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            TextButton(
              onPressed: _loading ? null : _signUp,
              child: const Text('Need an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: context.tokens.foreground,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _Banner extends StatelessWidget {
  final String text;
  final Color tone;
  final IconData icon;

  const _Banner({required this.text, required this.tone, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: tone),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: tone, fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wide-screen brand panel. Fixed navy, matching the splash.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const _navy = Color(0xFF06182D);
  static const _navyDeep = Color(0xFF03101F);
  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navy, _navyDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.045),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: Image.asset(
                      'assets/images/logo_with_name.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_balance_rounded,
                        size: 80,
                        color: _gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space6),
                  const Text(
                    'SRI VETRI VINAYAGA',
                    style: TextStyle(
                      color: Color(0xFFF2F6FC),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'AUTO FINANCE',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space6),
                  Container(width: 48, height: 1, color: _gold.withValues(alpha: 0.4)),
                  const SizedBox(height: AppTokens.space5),
                  const Text(
                    'YOUR DREAMS  •  OUR SUPPORT',
                    style: TextStyle(
                      color: Color(0xFF93A7C4),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Narrow-screen brand lockup.
class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: t.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(color: t.accent.withValues(alpha: 0.28)),
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            'assets/images/final_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.account_balance_rounded, size: 34, color: t.accent),
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        Text(
          'SRI VETRI VINAYAGA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: t.foreground,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'AUTO FINANCE',
          style: TextStyle(
            color: t.accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }
}
