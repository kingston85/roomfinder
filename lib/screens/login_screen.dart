import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/session.dart';
import '../widgets/common.dart';

/// Opens the login screen if needed. Returns true when the person is signed in.
Future<bool> ensureSignedIn(BuildContext context, {String? reason}) async {
  if (Session.instance.signedIn) return true;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => LoginScreen(reason: reason)),
  );
  return ok == true || Session.instance.signedIn;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.reason});
  final String? reason;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submitEmail() {
    if (!_form.currentState!.validate()) return;
    final s = Session.instance;
    _run(() => _creating
        ? s.createAccount(_name.text, _email.text, _password.text)
        : s.signInWithEmail(_email.text, _password.text));
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      showMessage(context, 'Type your email first, then tap "Forgot password".');
      return;
    }
    try {
      await Session.instance.resetPassword(_email.text);
      if (mounted) showMessage(context, 'Password reset email sent.');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Brand.ocean,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Close',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('RoomFinder',
                    style: display(const TextStyle(
                        color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Brand.sign, borderRadius: BorderRadius.circular(8)),
                  child: Text('LR',
                      style: display(const TextStyle(color: Brand.ink, fontSize: 17, fontWeight: FontWeight.w800))),
                ),
              ]),
              const SizedBox(height: 10),
              Text(
                widget.reason ?? 'Checked rooms, apartments and houses to rent in Liberia.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFCDE6EE), fontSize: 15.5, height: 1.4),
              ),
            ]),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ListView(padding: const EdgeInsets.fromLTRB(24, 28, 24, 24), children: [
                    Text(_creating ? 'Create your account' : 'Welcome back', style: text.headlineSmall),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(backgroundColor: scheme.surface),
                      onPressed: _busy ? null : () => _run(Session.instance.signInWithGoogle),
                      icon: const Icon(Icons.g_mobiledata, size: 30),
                      label: const Text('Continue with Google'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or use email', style: TextStyle(color: scheme.onSurfaceVariant)),
                        ),
                        const Expanded(child: Divider()),
                      ]),
                    ),
                    Form(
                      key: _form,
                      child: Column(children: [
                        if (_creating) ...[
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                                labelText: 'Your name', prefixIcon: Icon(Icons.person_outline)),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                              labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          decoration: const InputDecoration(
                              labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                          obscureText: true,
                          validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null,
                          onFieldSubmitted: (_) => _submitEmail(),
                        ),
                      ]),
                    ),
                    if (!_creating)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: _forgot, child: const Text('Forgot password?')),
                      )
                    else
                      const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _submitEmail,
                      child: _busy
                          ? const SizedBox(
                              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text(_creating ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _creating = !_creating),
                      child: Text(_creating ? 'I already have an account' : 'New here? Create an account'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
