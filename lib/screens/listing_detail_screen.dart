import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/liberia.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../services/session.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late final Stream<Listing?> _stream = ListingService.instance.watch(widget.listingId);
  final _pages = PageController();
  int _page = 0;
  ListingContact? _contact;
  bool _loadingContact = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  String get _shareLink => '${AppConfig.webBaseUrl}/#/listing?id=${widget.listingId}';

  Future<ListingContact?> _getContact() async {
    if (_contact != null) return _contact;
    if (!await ensureSignedIn(context, reason: 'Sign in to see the landlord\'s number.')) {
      return null;
    }
    setState(() => _loadingContact = true);
    try {
      final c = await ListingService.instance.contactFor(widget.listingId);
      if (c == null) {
        if (mounted) showMessage(context, 'This listing has no contact number.');
        return null;
      }
      setState(() => _contact = c);
      return c;
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      return null;
    } finally {
      if (mounted) setState(() => _loadingContact = false);
    }
  }

  Future<void> _call() async {
    final c = await _getContact();
    if (c == null || c.phone.isEmpty) return;
    await launchUrl(Uri.parse('tel:${c.phone.replaceAll(' ', '')}'));
  }

  Future<void> _whatsapp(Listing l) async {
    final c = await _getContact();
    if (c == null) return;
    final number = toInternationalDigits(c.whatsapp.isNotEmpty ? c.whatsapp : c.phone);
    if (number.isEmpty) return;
    final msg = Uri.encodeComponent(
        'Hello, I saw your ${typeLabel(l.type).toLowerCase()} in ${l.community} on ${AppConfig.appName}. Is it still available?');
    await launchUrl(Uri.parse('https://wa.me/$number?text=$msg'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _report() async {
    if (!await ensureSignedIn(context, reason: 'Sign in to report a listing.')) return;
    String reason = 'taken';
    final note = TextEditingController();
    final send = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Report this listing', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('Our team checks every report.'),
            const SizedBox(height: 18),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in reportReasons.entries)
                PickChip(
                  label: e.value,
                  selected: reason == e.key,
                  onTap: () => setSheet(() => reason = e.key),
                ),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Details (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Brand.laterite),
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Send report'),
              ),
            ),
          ]),
        ),
      ),
    );
    if (send != true) return;
    try {
      await ListingService.instance
          .report(widget.listingId, Session.instance.user!.uid, reason, note.text);
      if (mounted) showMessage(context, 'Report sent. Thank you.');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    }
  }

  Future<void> _toggleSave(bool isSaved) async {
    if (!await ensureSignedIn(context, reason: 'Sign in to save places.')) return;
    await ListingService.instance
        .toggleSave(Session.instance.user!.uid, widget.listingId, !isSaved);
    if (mounted) showMessage(context, isSaved ? 'Removed from saved places.' : 'Saved.');
  }

  Future<void> _share() async {
    await Clipboard.setData(ClipboardData(text: _shareLink));
    if (mounted) showMessage(context, 'Link copied. Paste it in WhatsApp or Facebook.');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Listing?>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError || (snap.connectionState != ConnectionState.waiting && snap.data == null)) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(
              icon: Icons.key_off_outlined,
              title: 'This place is no longer available',
              message: 'It may have been rented out or removed.',
              action: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back to search'),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _buildListing(context, snap.data!);
      },
    );
  }

  Widget _roundButton({required IconData icon, required String tooltip, required VoidCallback onTap, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 1,
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: color ?? Brand.ink, size: 22),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _gallery(Listing l) {
    final count = l.photos.isEmpty ? 1 : l.photos.length;
    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        controller: _pages,
        itemCount: count,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (_, i) {
          final photo = NetPhoto(l.photos.isEmpty ? null : thumbUrl(l.photos[i], width: 1400));
          return i == 0 ? Hero(tag: 'photo-${l.id}', child: photo) : photo;
        },
      ),
      if (count > 1)
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page ? Colors.white : Colors.white.withAlpha(140),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ]),
        ),
    ]);
  }

  Widget _fact(IconData icon, String value, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withAlpha(150),
          borderRadius: BorderRadius.circular(Brand.radiusM),
        ),
        child: Column(children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              style: display(TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface))),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _buildListing(BuildContext context, Listing l) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final session = Session.instance;
    final isOwnerOrAdmin = session.user?.uid == l.ownerId || session.isAdmin;
    final uid = session.user?.uid;
    final hasRooms = l.type != 'single_room' && l.type != 'shop';
    final presentAmenities = amenityLabels.entries.where((e) => l.amenities[e.key] == true).toList();

    final saveButton = uid == null
        ? _roundButton(icon: Icons.favorite_border, tooltip: 'Save', onTap: () => _toggleSave(false))
        : StreamBuilder<Set<String>>(
            stream: ListingService.instance.savedIds(uid),
            builder: (context, s) {
              final saved = s.data?.contains(l.id) ?? false;
              return _roundButton(
                icon: saved ? Icons.favorite : Icons.favorite_border,
                color: saved ? Brand.laterite : null,
                tooltip: saved ? 'Remove from saved' : 'Save',
                onTap: () => _toggleSave(saved),
              );
            },
          );

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          stretch: true,
          backgroundColor: Brand.ocean,
          automaticallyImplyLeading: false,
          leading: _roundButton(
            icon: Icons.arrow_back,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            saveButton,
            _roundButton(icon: Icons.ios_share, tooltip: 'Copy link to share', onTap: _share),
            const SizedBox(width: 6),
          ],
          flexibleSpace: FlexibleSpaceBar(background: _gallery(l)),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (isOwnerOrAdmin && l.status != 'live')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Panel(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            StatusChip(l.status),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l.status == 'rejected' && l.rejectReason.isNotEmpty
                                    ? l.rejectReason
                                    : 'Only you and the admins can see this place right now.',
                                style: text.bodySmall,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      PriceTag(listing: l, large: true),
                      const Spacer(),
                      if (l.verified) const VerifiedBadge(),
                    ]),
                    const SizedBox(height: 18),
                    Text(l.title, style: text.headlineSmall),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.place, size: 18, color: scheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${l.community}, ${l.county}',
                            style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    if (l.landmark.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2),
                        child: Text(l.landmark, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                    const SizedBox(height: 20),
                    Row(children: [
                      _fact(Icons.event_available_outlined,
                          l.advanceMonths == 0 ? 'None' : '${l.advanceMonths} month${l.advanceMonths == 1 ? '' : 's'}',
                          'Rent up front'),
                      const SizedBox(width: 10),
                      _fact(hasRooms ? Icons.bed_outlined : Icons.meeting_room_outlined,
                          hasRooms ? '${l.bedrooms}' : (l.type == 'shop' ? 'Shop' : 'Room'),
                          hasRooms ? 'Bedroom${l.bedrooms == 1 ? '' : 's'}' : 'Type'),
                      const SizedBox(width: 10),
                      _fact(l.postedBy == 'agent' ? Icons.badge_outlined : Icons.person_outline,
                          l.postedBy == 'agent' ? 'Agent' : 'Landlord', 'Posted by'),
                    ]),
                    if (l.postedBy == 'agent' && l.agentFee.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text('Agent fee: ${l.agentFee}', style: text.bodyMedium),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Confirmed free ${daysAgo(l.lastConfirmedAt)}'
                      '${l.verified && l.verifiedAt != null ? ', verified ${daysAgo(l.verifiedAt)}' : ''}',
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (l.description.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('About this place', style: text.titleLarge?.copyWith(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(l.description, style: text.bodyLarge),
                    ],
                    if (presentAmenities.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('What it has', style: text.titleLarge?.copyWith(fontSize: 18)),
                      const SizedBox(height: 12),
                      Panel(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Column(children: [
                          for (var i = 0; i < presentAmenities.length; i++) ...[
                            if (i > 0) const Divider(indent: 56),
                            ListTile(
                              dense: true,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withAlpha(22),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(amenityIcons[presentAmenities[i].key], size: 20, color: scheme.primary),
                              ),
                              title: Text(presentAmenities[i].value, style: text.bodyLarge),
                            ),
                          ],
                        ]),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const SafetyCard(),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: scheme.error),
                        onPressed: _report,
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Report this listing'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
      bottomNavigationBar: l.status == 'live' || isOwnerOrAdmin
          ? Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, -2))],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (_contact != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Brand.sign,
                            child: Text(
                              (_contact!.name.isEmpty ? '?' : _contact!.name[0]).toUpperCase(),
                              style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_contact!.name.isEmpty ? 'Contact' : _contact!.name, style: text.titleSmall),
                              Text(_contact!.phone, style: text.bodySmall),
                            ]),
                          ),
                        ]),
                      ),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadingContact ? null : _call,
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Brand.palm, foregroundColor: Colors.white),
                          onPressed: _loadingContact ? null : () => _whatsapp(l),
                          icon: _loadingContact
                              ? const SizedBox(
                                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.chat_outlined),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
            )
          : null,
    );
  }
}
