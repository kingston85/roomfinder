import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../services/listing_service.dart';
import '../services/session.dart';
import '../widgets/common.dart';
import 'listing_detail_screen.dart';
import 'listing_form_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  Future<void> _act(BuildContext context, Future<void> Function() action, String done) async {
    try {
      await action();
      showMessage(context, done);
    } catch (e) {
      showMessage(context, friendlyError(e));
    }
  }

  Future<void> _confirmDelete(BuildContext context, Listing l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this place?'),
        content: const Text('This cannot be undone. If it is only rented out, use "Mark taken" instead.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _act(context, () => ListingService.instance.delete(l.id), 'Deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = Session.instance.user!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('My places')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ListingFormScreen())),
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Add a place'),
      ),
      body: StreamBuilder<List<Listing>>(
        stream: ListingService.instance.myListings(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(icon: Icons.cloud_off, title: 'Could not load', message: friendlyError(snap.error!));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.home_work_outlined,
              title: 'You have no places yet',
              message: 'Add your first room, apartment or house. Listing is free.',
            );
          }
          final needConfirm =
              items.where((l) => (l.status == 'live' || l.status == 'pending') && l.needsConfirming).length;
          return ListView(padding: const EdgeInsets.only(bottom: 96), children: [
            if (needConfirm > 0)
              Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text('$needConfirm place${needConfirm == 1 ? '' : 's'} need confirming'),
                  subtitle: const Text('Places not confirmed for 14 days are hidden from search. '
                      'Tap "Still free" on each one that is available.'),
                ),
              ),
            for (final l in items)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ListingCard(
                    listing: l,
                    margin: EdgeInsets.zero,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(listingId: l.id),
                    )),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Row(children: [
                      StatusChip(l.status),
                      const SizedBox(width: 8),
                      if (l.verified) const VerifiedBadge(),
                    ]),
                  ),
                  if (l.status == 'rejected' && l.rejectReason.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Text('Reason: ${l.rejectReason}. Edit the listing and send it again.',
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  OverflowBar(alignment: MainAxisAlignment.end, children: [
                    if (l.status != 'rejected' && l.status != 'hidden')
                      TextButton.icon(
                        onPressed: () => _act(context, () => ListingService.instance.confirmAvailable(l),
                            'Thanks! Marked as still free.'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Still free'),
                      ),
                    if (l.status == 'live' || l.status == 'pending')
                      TextButton(
                        onPressed: () =>
                            _act(context, () => ListingService.instance.markTaken(l.id), 'Marked as taken.'),
                        child: const Text('Mark taken'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ListingFormScreen(existing: l))),
                      child: const Text('Edit'),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, l),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ]),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}
