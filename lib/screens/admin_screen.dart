import 'package:flutter/material.dart';

import '../data/liberia.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../services/session.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'listing_detail_screen.dart';

/// Shown only to accounts whose users/{uid}.role is "admin".
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: const TabBar(tabs: [Tab(text: 'Review queue'), Tab(text: 'Reports')]),
        ),
        body: const TabBarView(children: [_ReviewQueue(), _Reports()]),
      ),
    );
  }
}

Future<void> _run(BuildContext context, Future<void> Function() action, String done) async {
  try {
    await action();
    showMessage(context, done);
  } catch (e) {
    showMessage(context, friendlyError(e));
  }
}

Future<String?> _askReason(BuildContext context, String title) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        decoration: const InputDecoration(
          labelText: 'Reason (the owner sees this)',
          hintText: 'e.g. Photos are not of this property',
        ),
        maxLines: 2,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Confirm')),
      ],
    ),
  );
}

void _open(BuildContext context, String id) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: id)));

class _ReviewQueue extends StatelessWidget {
  const _ReviewQueue();

  @override
  Widget build(BuildContext context) {
    final adminId = Session.instance.user!.uid;
    final svc = ListingService.instance;
    return StreamBuilder<List<Listing>>(
      stream: svc.pending(),
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(icon: Icons.cloud_off, title: 'Could not load', message: friendlyError(snap.error!));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return const EmptyState(icon: Icons.done_all, title: 'Nothing waiting for review');
        }
        return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('${items.length} waiting. Check photos, price and location. '
                'Use "Approve + verified" only after a visit or video call.'),
          ),
          for (final l in items)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                ListingCard(listing: l, margin: EdgeInsets.zero, onTap: () => _open(context, l.id)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Text('${l.photos.length} photos · ${l.postedBy} · added ${daysAgo(l.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                OverflowBar(alignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: () async {
                      final reason = await _askReason(context, 'Reject this listing?');
                      if (reason == null) return;
                      await _run(context, () => svc.reject(l.id, reason), 'Rejected.');
                    },
                    child: const Text('Reject'),
                  ),
                  TextButton(
                    onPressed: () => _run(context,
                        () => svc.approve(l.id, verified: false, adminId: adminId), 'Approved and live.'),
                    child: const Text('Approve'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _run(context,
                        () => svc.approve(l.id, verified: true, adminId: adminId), 'Approved and verified.'),
                    child: const Text('Approve + verified'),
                  ),
                ]),
              ]),
            ),
        ]);
      },
    );
  }
}

class _Reports extends StatelessWidget {
  const _Reports();

  @override
  Widget build(BuildContext context) {
    final svc = ListingService.instance;
    return StreamBuilder<List<Report>>(
      stream: svc.openReports(),
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(icon: Icons.cloud_off, title: 'Could not load', message: friendlyError(snap.error!));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) return const EmptyState(icon: Icons.verified_user_outlined, title: 'No open reports');
        return ListView(children: [
          for (final r in items)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(reportReasons[r.reason] ?? r.reason, style: Theme.of(context).textTheme.titleSmall),
                  if (r.note.isNotEmpty) Text(r.note),
                  Text('Reported ${daysAgo(r.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
                  OverflowBar(alignment: MainAxisAlignment.end, children: [
                    TextButton(onPressed: () => _open(context, r.listingId), child: const Text('View')),
                    TextButton(
                      onPressed: () => _run(context, () => svc.resolveReport(r.id, 'dismissed'), 'Dismissed.'),
                      child: const Text('Dismiss'),
                    ),
                    TextButton(
                      onPressed: () => _run(context, () async {
                        await svc.hide(r.listingId);
                        await svc.resolveReport(r.id, 'hidden');
                      }, 'Listing hidden.'),
                      child: const Text('Hide listing'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Ban the owner?'),
                            content: const Text('Hides this listing and blocks the owner from posting.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ban')),
                            ],
                          ),
                        );
                        if (ok != true) return;
                        await _run(context, () async {
                          final listing = (await svc.loadListings([r.listingId])).firstOrNull;
                          await svc.hide(r.listingId);
                          if (listing != null) await svc.banUser(listing.ownerId);
                          await svc.resolveReport(r.id, 'banned');
                        }, 'Owner banned.');
                      },
                      child: const Text('Ban owner'),
                    ),
                  ]),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}
