import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config.dart';
import 'screens/account_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/listing_detail_screen.dart';
import 'screens/my_listings_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/search_screen.dart';
import 'services/session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.isConfigured) {
    runApp(const _NotConfiguredApp());
    return;
  }
  await Firebase.initializeApp(options: AppConfig.firebaseOptions);
  Session.instance; // start listening for sign-in changes
  runApp(const RoomFinderApp());
}

class RoomFinderApp extends StatelessWidget {
  const RoomFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      initialRoute: '/',
      // Share links look like  <site>/#/listing?id=<listingId>
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        if (uri.path == '/listing' && (uri.queryParameters['id'] ?? '').isNotEmpty) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ListingDetailScreen(listingId: uri.queryParameters['id']!),
          );
        }
        return MaterialPageRoute(settings: settings, builder: (_) => const HomeShell());
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _Tab {
  const _Tab(this.icon, this.selectedIcon, this.label, this.page);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Saved and Account are built fresh (not const) so they redraw when the
  // person signs in or out.
  List<_Tab> _tabs(Session s) => [
        const _Tab(Icons.search, Icons.search, 'Find', SearchScreen()),
        _Tab(Icons.favorite_border, Icons.favorite, 'Saved', SavedScreen(key: ValueKey('saved-${s.user?.uid}'))),
        if (s.canList && !s.isBanned)
          const _Tab(Icons.home_work_outlined, Icons.home_work, 'My places', MyListingsScreen()),
        if (s.isAdmin)
          const _Tab(Icons.shield_outlined, Icons.shield, 'Admin', AdminScreen()),
        _Tab(Icons.person_outline, Icons.person, 'Account', AccountScreen(key: ValueKey('account-${s.user?.uid}-${s.profile?.role}'))),
      ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final tabs = _tabs(Session.instance);
        if (_index >= tabs.length) _index = 0;
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              for (final t in tabs) KeyedSubtree(key: ValueKey(t.label), child: t.page),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (final t in tabs)
                NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.label),
            ],
          ),
        );
      },
    );
  }
}

class _NotConfiguredApp extends StatelessWidget {
  const _NotConfiguredApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.settings_outlined, size: 48),
              SizedBox(height: 12),
              Text('${AppConfig.appName} is not set up yet', style: TextStyle(fontSize: 20)),
              SizedBox(height: 8),
              Text('The Firebase settings were not included in this build. '
                  'Add them as GitHub secrets (see README.md) and build again.',
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      ),
    );
  }
}
