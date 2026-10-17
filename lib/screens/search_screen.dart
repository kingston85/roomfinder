import 'package:flutter/material.dart';

import '../data/liberia.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'listing_detail_screen.dart';

const typeIcons = <String, IconData>{
  'single_room': Icons.bed_outlined,
  'room_parlor': Icons.weekend_outlined,
  'apartment_1': Icons.apartment_outlined,
  'apartment_2': Icons.apartment_outlined,
  'apartment_3': Icons.domain_outlined,
  'house': Icons.house_outlined,
  'shop': Icons.storefront_outlined,
};

class SearchFilters {
  String? community;
  String? type;
  double? maxUsd;
  Set<String> amenities = {};
  bool verifiedOnly = false;
  String sort = 'newest'; // newest | cheapest

  int get extraCount =>
      (maxUsd != null ? 1 : 0) + amenities.length + (verifiedOnly ? 1 : 0);

  List<Listing> apply(List<Listing> all) {
    final out = all.where((l) {
      if (maxUsd != null && l.priceUsd > maxUsd!) return false;
      if (verifiedOnly && !l.verified) return false;
      for (final a in amenities) {
        if (l.amenities[a] != true) return false;
      }
      return true;
    }).toList();
    int featuredFirst(Listing a, Listing b) =>
        (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0);
    final epoch = DateTime(2000);
    out.sort((a, b) {
      final f = featuredFirst(a, b);
      if (f != 0) return f;
      return sort == 'cheapest'
          ? a.priceUsd.compareTo(b.priceUsd)
          : (b.lastConfirmedAt ?? epoch).compareTo(a.lastConfirmedAt ?? epoch);
    });
    return out;
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _f = SearchFilters();
  late Stream<List<Listing>> _stream;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _stream = ListingService.instance.searchLive(community: _f.community, type: _f.type);
  }

  Future<void> _pickCommunity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(controller: controller, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text('Choose a community', style: Theme.of(context).textTheme.headlineSmall),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(Icons.map_outlined),
            title: const Text('All communities'),
            trailing: _f.community == null ? const Icon(Icons.check_circle, color: Brand.palm) : null,
            onTap: () => Navigator.pop(sheetContext, '__all__'),
          ),
          for (final c in communities)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.place_outlined),
              title: Text(c),
              trailing: c == _f.community ? const Icon(Icons.check_circle, color: Brand.palm) : null,
              onTap: () => Navigator.pop(sheetContext, c),
            ),
          const SizedBox(height: 24),
        ]),
      ),
    );
    if (picked == null) return;
    setState(() {
      _f.community = picked == '__all__' ? null : picked;
      _reload();
    });
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheet) {
        void update(VoidCallback fn) {
          setSheet(fn);
          setState(() {});
        }

        final text = Theme.of(context).textTheme;
        const budgets = [50.0, 100.0, 150.0, 250.0, 400.0, 600.0];
        Widget heading(String s) => Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 10),
              child: Text(s, style: text.titleMedium),
            );
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Filters', style: text.headlineSmall),
                    heading('Most you will pay per month'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      PickChip(
                        label: 'Any price',
                        selected: _f.maxUsd == null,
                        onTap: () => update(() => _f.maxUsd = null),
                      ),
                      for (final b in budgets)
                        PickChip(
                          label: 'Up to US\$${b.round()}',
                          selected: _f.maxUsd == b,
                          onTap: () => update(() => _f.maxUsd = b),
                        ),
                    ]),
                    const SizedBox(height: 6),
                    Text('Places priced in L\$ are converted for comparison.',
                        style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    heading('Must have'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final e in amenityLabels.entries)
                        PickChip(
                          label: e.value,
                          icon: amenityIcons[e.key],
                          selected: _f.amenities.contains(e.key),
                          onTap: () => update(() => _f.amenities.contains(e.key)
                              ? _f.amenities.remove(e.key)
                              : _f.amenities.add(e.key)),
                        ),
                    ]),
                    const SizedBox(height: 14),
                    Card(
                      child: SwitchListTile(
                        secondary: const Icon(Icons.verified_outlined, color: Brand.palm),
                        title: const Text('Verified places only'),
                        subtitle: const Text('Checked in person by our team'),
                        value: _f.verifiedOnly,
                        onChanged: (v) => update(() => _f.verifiedOnly = v),
                      ),
                    ),
                    heading('Sort by'),
                    Wrap(spacing: 8, children: [
                      PickChip(
                        label: 'Recently confirmed',
                        icon: Icons.schedule,
                        selected: _f.sort == 'newest',
                        onTap: () => update(() => _f.sort = 'newest'),
                      ),
                      PickChip(
                        label: 'Lowest price',
                        icon: Icons.south,
                        selected: _f.sort == 'cheapest',
                        onTap: () => update(() => _f.sort = 'cheapest'),
                      ),
                    ]),
                  ]),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Row(children: [
                  TextButton(
                    onPressed: () => update(() {
                      _f.maxUsd = null;
                      _f.amenities.clear();
                      _f.verifiedOnly = false;
                      _f.sort = 'newest';
                    }),
                    child: const Text('Clear all'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Show places'),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
  }

  Widget _header(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.ocean, Brand.oceanDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('RoomFinder',
                  style: display(const TextStyle(
                      color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Brand.sign, borderRadius: BorderRadius.circular(6)),
                child: Text('LR',
                    style: display(const TextStyle(
                        color: Brand.ink, fontSize: 13, fontWeight: FontWeight.w800))),
              ),
            ]),
            const SizedBox(height: 22),
            ListenableBuilder(
              listenable: Session.instance,
              builder: (context, _) {
                final first = (Session.instance.profile?.name ?? '').trim().split(' ').first;
                return first.isEmpty
                    ? const SizedBox.shrink()
                    : Text('Hello $first,',
                        style: const TextStyle(
                            color: Color(0xFFB9DCE6), fontSize: 15, fontWeight: FontWeight.w500));
              },
            ),
            Text('Where do you want to live?',
                style: display(const TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.6))),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Brand.radiusM),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Brand.radiusM),
                    onTap: _pickCommunity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      child: Row(children: [
                        const Icon(Icons.place, color: Brand.ocean),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _f.community ?? 'All communities',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Brand.ink, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.expand_more, color: Brand.mist),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Badge(
                isLabelVisible: _f.extraCount > 0,
                backgroundColor: Brand.sign,
                textColor: Brand.ink,
                label: Text('${_f.extraCount}', style: const TextStyle(fontWeight: FontWeight.w800)),
                child: Material(
                  color: Colors.white.withAlpha(36),
                  borderRadius: BorderRadius.circular(Brand.radiusM),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Brand.radiusM),
                    onTap: _openFilters,
                    child: const SizedBox(
                      width: 54,
                      height: 54,
                      child: Icon(Icons.tune, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _typeChips() {
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PickChip(
              label: 'Everything',
              icon: Icons.grid_view_rounded,
              selected: _f.type == null,
              onTap: () => setState(() {
                _f.type = null;
                _reload();
              }),
            ),
          ),
          for (final e in listingTypes.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PickChip(
                label: e.value,
                icon: typeIcons[e.key],
                selected: _f.type == e.key,
                onTap: () => setState(() {
                  _f.type = e.key;
                  _reload();
                }),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: StreamBuilder<List<Listing>>(
        stream: _stream,
        builder: (context, snap) {
          final slivers = <Widget>[
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(child: _typeChips()),
          ];
          if (snap.hasError) {
            slivers.add(SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Places could not load',
                message: friendlyError(snap.error!),
              ),
            ));
          } else if (!snap.hasData) {
            slivers.add(const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ));
          } else {
            final results = _f.apply(snap.data!);
            if (results.isEmpty) {
              slivers.add(SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.travel_explore,
                  title: 'No places here yet',
                  message: 'Try another community or fewer filters. New places are added every week.',
                  action: _f.extraCount > 0 || _f.type != null || _f.community != null
                      ? OutlinedButton(
                          onPressed: () => setState(() {
                            _f
                              ..community = null
                              ..type = null
                              ..maxUsd = null
                              ..verifiedOnly = false
                              ..amenities.clear();
                            _reload();
                          }),
                          child: const Text('Show all places'),
                        )
                      : null,
                ),
              ));
            } else {
              slivers.add(SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        '${results.length} place${results.length == 1 ? '' : 's'} free to rent',
                        style: text.titleMedium,
                      ),
                    ),
                    Text(_f.sort == 'cheapest' ? 'Lowest price first' : 'Recently confirmed',
                        style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ]),
                ),
              ));
              slivers.add(SliverList.builder(
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final l = results[i];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListingPhotoCard(
                        listing: l,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ListingDetailScreen(listingId: l.id),
                        )),
                      ),
                    ),
                  );
                },
              ));
              slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
            }
          }
          return CustomScrollView(slivers: slivers);
        },
      ),
    );
  }
}
