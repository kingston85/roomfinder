import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/liberia.dart';
import '../models/listing.dart';
import '../theme.dart';
import '../utils/format.dart';

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Turns Firebase error codes into plain words.
String friendlyError(Object e) {
  final s = e.toString();
  if (s.contains('network') || s.contains('unavailable')) {
    return 'No connection. Check your data or Wi-Fi and try again.';
  }
  if (s.contains('permission-denied')) return 'You are not allowed to do that.';
  if (s.contains('wrong-password') || s.contains('invalid-credential')) {
    return 'Email or password is not correct.';
  }
  if (s.contains('user-not-found')) return 'No account with that email.';
  if (s.contains('email-already-in-use')) return 'That email already has an account. Sign in instead.';
  if (s.contains('weak-password')) return 'Use a password of at least 6 characters.';
  if (s.contains('popup-closed') || s.contains('canceled') || s.contains('cancelled')) {
    return 'Sign-in was cancelled.';
  }
  if (s.contains('failed-precondition') && s.contains('index')) {
    return 'The database needs an index. Deploy firestore.indexes.json (see README).';
  }
  return s.replaceFirst('Exception: ', '');
}

/// Icons for each amenity key.
const amenityIcons = <String, IconData>{
  'water_inside': Icons.water_drop_outlined,
  'water_well': Icons.opacity,
  'lec_power': Icons.bolt_outlined,
  'backup_power': Icons.solar_power_outlined,
  'fence_gate': Icons.fence_outlined,
  'toilet_inside': Icons.wc_outlined,
  'kitchen': Icons.kitchen_outlined,
  'parking': Icons.local_parking_outlined,
  'good_road': Icons.add_road_outlined,
};

class NetPhoto extends StatelessWidget {
  const NetPhoto(this.url, {super.key, this.fit = BoxFit.cover});
  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.house_outlined, size: 44, color: scheme.onSurfaceVariant.withAlpha(120)),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

/// The signature element: a yellow price tag like a hand-painted
/// "Room for rent" sign on a Monrovia wall.
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.listing, this.large = false});
  final Listing listing;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final amount = formatPrice(listing.priceMonthly, listing.currency);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 11, vertical: large ? 8 : 6),
      decoration: BoxDecoration(
        color: Brand.sign,
        borderRadius: BorderRadius.circular(large ? 12 : 9),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
            text: amount,
            style: display(TextStyle(
              fontSize: large ? 24 : 18,
              fontWeight: FontWeight.w800,
              color: Brand.ink,
              letterSpacing: -0.4,
            )),
          ),
          TextSpan(
            text: ' /month',
            style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.w600, color: Brand.ink),
          ),
        ]),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color, icon) = switch (status) {
      'live' => ('Live', scheme.tertiary, Icons.circle),
      'pending' => ('Waiting for review', const Color(0xFFB7791F), Icons.schedule),
      'taken' => ('Taken', scheme.onSurfaceVariant, Icons.key_outlined),
      'hidden' => ('Hidden', scheme.onSurfaceVariant, Icons.visibility_off_outlined),
      'rejected' => ('Not approved', scheme.error, Icons.error_outline),
      _ => (status, scheme.onSurfaceVariant, Icons.circle_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: status == 'live' ? 8 : 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.onPhoto = false});
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: onPhoto ? Colors.white : green.withAlpha(28),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified, size: 15, color: onPhoto ? Brand.palm : green),
        const SizedBox(width: 4),
        Text('Verified',
            style: TextStyle(
                color: onPhoto ? Brand.palm : green, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// A chip with clear selected styling (filled Atlantic blue, white text).
class PickChip extends StatelessWidget {
  const PickChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 18, color: fg),
      label: Text(label),
      labelStyle: TextStyle(color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primary,
      side: BorderSide(color: selected ? scheme.primary : scheme.outline),
    );
  }
}

/// Big photo-first card used in search results.
class ListingPhotoCard extends StatelessWidget {
  const ListingPhotoCard({super.key, required this.listing, required this.onTap});
  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final features = <(IconData, String)>[
      if (l.type != 'single_room' && l.type != 'shop')
        (Icons.bed_outlined, '${l.bedrooms} bed${l.bedrooms == 1 ? '' : 's'}'),
      if (l.amenities['toilet_inside'] == true) (Icons.wc_outlined, 'Inside toilet'),
      if (l.amenities['lec_power'] == true) (Icons.bolt_outlined, 'LEC'),
      if (l.amenities['water_inside'] == true) (Icons.water_drop_outlined, 'Water'),
      if (l.amenities['fence_gate'] == true) (Icons.fence_outlined, 'Fenced'),
    ].take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(fit: StackFit.expand, children: [
                Hero(
                  tag: 'photo-${l.id}',
                  child: NetPhoto(l.coverPhoto == null ? null : thumbUrl(l.coverPhoto!, width: 900)),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x55000000)],
                    ),
                  ),
                ),
                Positioned(left: 12, bottom: 12, child: PriceTag(listing: l)),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Row(children: [
                    if (l.isFeatured)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                            color: Brand.ink.withAlpha(200), borderRadius: BorderRadius.circular(30)),
                        child: const Text('Featured',
                            style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ),
                    if (l.verified) const VerifiedBadge(onPhoto: true),
                  ]),
                ),
                if (l.photos.length > 1)
                  Positioned(
                    right: 12,
                    bottom: 14,
                    child: Row(children: [
                      const Icon(Icons.photo_library_outlined, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${l.photos.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.place_outlined, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('${typeLabel(l.type)} in ${l.community}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                ]),
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 14, runSpacing: 6, children: [
                    for (final f in features)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(f.$1, size: 17, color: scheme.primary),
                        const SizedBox(width: 5),
                        Text(f.$2, style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      ]),
                  ]),
                ],
                const SizedBox(height: 12),
                Text('Confirmed free ${daysAgo(l.lastConfirmedAt)}',
                    style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Compact row card used in saved places, my places and admin.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap, this.trailing, this.margin});
  final Listing listing;
  final VoidCallback onTap;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final content = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Brand.radiusS + 2),
            child: SizedBox(
              width: 104,
              height: 104,
              child: NetPhoto(l.coverPhoto == null ? null : thumbUrl(l.coverPhoto!, width: 300)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 2),
              Text(formatPrice(l.priceMonthly, l.currency),
                  style: display(TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: scheme.onSurface, letterSpacing: -0.4))),
              const SizedBox(height: 2),
              Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
              Text('${typeLabel(l.type)} in ${l.community}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (l.verified) const VerifiedBadge(),
                Text('Confirmed ${daysAgo(l.lastConfirmedAt)}',
                    style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
    if (margin != null) return Padding(padding: margin!, child: content);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(clipBehavior: Clip.antiAlias, child: content),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: Brand.sign.withAlpha(70), shape: BoxShape.circle),
            child: Icon(icon, size: 44, color: scheme.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45)),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ]),
      ),
    );
  }
}

/// A titled white panel used to group content on detail and form screens.
class Panel extends StatelessWidget {
  const Panel({super.key, this.title, this.subtitle, required this.child, this.padding});
  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null) Text(title!, style: text.titleLarge?.copyWith(fontSize: 18)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
          if (title != null || subtitle != null) const SizedBox(height: 14),
          child,
        ]),
      ),
    );
  }
}

const safetyTips = [
  'Never pay rent or a deposit before you have seen the place and met the owner.',
  'If you deal with an agent, ask to meet the landlord or see a letter from them.',
  'Get a written receipt or lease for every payment.',
  'Report any listing that asks for money before a viewing.',
];

class SafetyCard extends StatelessWidget {
  const SafetyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Brand.sign.withAlpha(45),
        borderRadius: BorderRadius.circular(Brand.radiusL),
        border: Border.all(color: Brand.sign.withAlpha(140)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.shield_outlined, color: Brand.ink),
          const SizedBox(width: 8),
          Text('Stay safe', style: text.titleMedium?.copyWith(color: Brand.ink)),
        ]),
        const SizedBox(height: 10),
        for (final tip in safetyTips)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check, size: 16, color: Brand.ink),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(tip, style: text.bodyMedium?.copyWith(color: Brand.ink))),
            ]),
          ),
      ]),
    );
  }
}
