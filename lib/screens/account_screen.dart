import 'package:flutter/material.dart';

import '../config.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  String _role = 'renter';
  String? _loadedFor;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  void _fillFromProfile() {
    final p = Session.instance.profile;
    if (p == null || _loadedFor == p.uid) return;
    _loadedFor = p.uid;
    _name.text = p.name;
    _phone.text = p.phone;
    _whatsapp.text = p.whatsapp;
    _role = p.role == 'admin' ? 'landlord' : p.role;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Session.instance.updateProfile(
        name: _name.text,
        phone: _phone.text,
        whatsapp: _whatsapp.text,
        role: _role,
      );
      if (mounted) showMessage(context, 'Saved.');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _roleCard(String value, IconData icon, String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _role == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? scheme.primary.withAlpha(18) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.radiusM),
          side: BorderSide(color: selected ? scheme.primary : scheme.outline, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Brand.radiusM),
          onTap: () => setState(() => _role = value),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ]),
              ),
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? scheme.primary : scheme.outline),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (!session.signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: EmptyState(
          icon: Icons.person_outline,
          title: 'Sign in to do more',
          message: 'Save places, see landlords\' numbers, or list your own place for free.',
          action: FilledButton(onPressed: () => ensureSignedIn(context), child: const Text('Sign in')),
        ),
      );
    }
    _fillFromProfile();
    final p = session.profile;
    final initial = (p?.name.isNotEmpty == true ? p!.name[0] : (session.user?.email ?? '?')[0]).toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
            if (p?.banned == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: scheme.errorContainer,
                  child: const ListTile(
                    leading: Icon(Icons.block),
                    title: Text('This account is suspended'),
                    subtitle: Text('It broke the listing rules. Contact the team if you think this is a mistake.'),
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Brand.sign,
                    child: Text(initial,
                        style: display(const TextStyle(color: Brand.ink, fontSize: 26, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p?.name.isNotEmpty == true ? p!.name : 'Your account', style: text.titleLarge),
                      Text(session.user?.email ?? '', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      if (p?.isAdmin == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: scheme.primary.withAlpha(22), borderRadius: BorderRadius.circular(30)),
                            child: Text('Admin',
                                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                          ),
                        ),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Panel(
              title: 'Your details',
              subtitle: 'Your phone number fills in automatically when you list a place.',
              child: Column(children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.call_outlined)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _whatsapp,
                  decoration: const InputDecoration(labelText: 'WhatsApp number', prefixIcon: Icon(Icons.chat_outlined)),
                  keyboardType: TextInputType.phone,
                ),
              ]),
            ),
            if (p?.isAdmin != true) ...[
              const SizedBox(height: 16),
              Panel(
                title: 'How will you use RoomFinder?',
                child: Column(children: [
                  _roleCard('renter', Icons.search, 'Find a place', 'Search, save and contact landlords'),
                  _roleCard('landlord', Icons.house_outlined, 'Rent out my own place', 'Adds the My places tab'),
                  _roleCard('agent', Icons.badge_outlined, 'List places as an agent', 'Adds the My places tab'),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Save changes'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                _loadedFor = null;
                await session.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
            const SizedBox(height: 24),
            const SafetyCard(),
            const SizedBox(height: 18),
            Text('${AppConfig.appName} connects renters with landlords and agents. We never collect rent or deposits.',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
