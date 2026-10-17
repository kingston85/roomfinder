import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../services/listing_service.dart';
import '../services/session.dart';
import '../widgets/common.dart';
import 'listing_detail_screen.dart';
import 'login_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Session.instance.user?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved places')),
      body: uid == null
          ? EmptyState(
              icon: Icons.favorite_border,
              title: 'Save places you like',
              message: 'Sign in to keep a list of places to call or visit.',
              action: FilledButton(
                onPressed: () => ensureSignedIn(context),
                child: const Text('Sign in'),
              ),
            )
          : StreamBuilder<Set<String>>(
              stream: ListingService.instance.savedIds(uid),
              builder: (context, ids) {
                if (!ids.hasData) return const Center(child: CircularProgressIndicator());
                if (ids.data!.isEmpty) {
                  return const EmptyState(
                    icon: Icons.favorite_border,
                    title: 'Nothing saved yet',
                    message: 'Tap the heart on a place to save it here.',
                  );
                }
                return FutureBuilder<List<Listing>>(
                  key: ValueKey(ids.data!.join(',')),
                  future: ListingService.instance.loadListings(ids.data!),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final list = snap.data!;
                    final gone = ids.data!.length - list.length;
                    return ListView(children: [
                      for (final l in list)
                        ListingCard(
                          listing: l,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ListingDetailScreen(listingId: l.id),
                          )),
                          trailing: l.status == 'live'
                              ? null
                              : const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: StatusChip('taken'),
                                ),
                        ),
                      if (gone > 0)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('$gone saved place${gone == 1 ? ' is' : 's are'} no longer available.'),
                        ),
                    ]);
                  },
                );
              },
            ),
    );
  }
}
