import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../state/auth_notifier.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../util/errors.dart';

enum _Mode { signIn, signUp, forgotEmail, forgotReset }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _Mode _mode = _Mode.signIn;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _run(Future<void> Function() action) async {
    final l = AppL10n.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _snack(messageForError(e, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final auth = ref.watch(authProvider);
    final needsVerify = auth.status == AuthStatus.needsVerification;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: needsVerify
                  ? _buildVerify(l, auth)
                  : _mode == _Mode.forgotEmail
                      ? _buildForgotEmail(l)
                      : _mode == _Mode.forgotReset
                          ? _buildForgotReset(l)
                          : _buildAuth(l),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand(AppL10n l) => Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.c.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.c.accentStrong, width: 3),
            ),
            child: Center(
              child: Icon(Icons.schedule, size: 30, color: context.c.accentStrong),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.appTitle,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(l.welcomeTagline,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.inkSoft)),
          const SizedBox(height: 28),
        ],
      );

  Widget _buildAuth(AppL10n l) {
    final isSignUp = _mode == _Mode.signUp;
    return AutofillGroup(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _brand(l),
        if (isSignUp) ...[
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(labelText: l.name),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          decoration: InputDecoration(labelText: l.email),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          autofillHints: [
            isSignUp ? AutofillHints.newPassword : AutofillHints.password
          ],
          decoration: InputDecoration(
            labelText: l.password,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() async {
                    final auth = ref.read(authProvider);
                    if (isSignUp) {
                      await auth.register(
                          _email.text, _password.text, _name.text);
                    } else {
                      await auth.login(_email.text, _password.text);
                    }
                  }),
          child: _busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white))
              : Text(isSignUp ? l.signUp : l.signIn),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() =>
                  _mode = isSignUp ? _Mode.signIn : _Mode.signUp),
          child: Text(isSignUp ? l.haveAccount : l.needAccount),
        ),
        if (!isSignUp)
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() => _mode = _Mode.forgotEmail),
            child: Text(l.forgotPassword),
          ),
      ],
      ),
    );
  }

  Widget _buildForgotEmail(AppL10n l) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _brand(l),
        Text(l.resetTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(l.resetEmailHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.c.inkSoft)),
        const SizedBox(height: 20),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          decoration: InputDecoration(labelText: l.email),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() async {
                    await ref.read(authProvider).forgotPassword(_email.text);
                    if (mounted) setState(() => _mode = _Mode.forgotReset);
                  }),
          child: _busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white))
              : Text(l.sendResetCode),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _mode = _Mode.signIn),
          child: Text(l.backToSignIn),
        ),
      ],
    );
  }

  Widget _buildForgotReset(AppL10n l) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _brand(l),
        Text(l.resetTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(l.resetCodeHint(_email.text),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.c.inkSoft)),
        const SizedBox(height: 20),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: const InputDecoration(counterText: '', hintText: '••••••'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: l.newPassword,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() => ref
                  .read(authProvider)
                  .resetPassword(_email.text, _code.text, _password.text)),
          child: _busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white))
              : Text(l.doReset),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _mode = _Mode.signIn),
          child: Text(l.backToSignIn),
        ),
      ],
    );
  }

  Widget _buildVerify(AppL10n l, AuthNotifier auth) {
    final email = auth.pendingEmail ?? _email.text;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _brand(l),
        Text(l.verifyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(l.verifyHint(email),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.c.inkSoft)),
        const SizedBox(height: 20),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          style: const TextStyle(fontSize: 28, letterSpacing: 10),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() => auth.verify(email, _code.text)),
          child: _busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white))
              : Text(l.verify),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _busy ? null : () => auth.backToLogin(),
              child: Text(l.signIn),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await auth.resend(email);
                        _snack(l.resendCode);
                      }),
              child: Text(l.resendCode),
            ),
          ],
        ),
      ],
    );
  }
}
