import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/liberia.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../services/photo_service.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _minPhotos = 3;
const _maxPhotos = 8;

/// Add a new place, or edit one (editing sends it back for review).
class ListingFormScreen extends StatefulWidget {
  const ListingFormScreen({super.key, this.existing});
  final Listing? existing;

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _description, _price, _landmark, _agentFee,
      _contactName, _phone, _whatsapp;

  String _type = 'single_room';
  String _currency = 'USD';
  int _advance = 1;
  int _bedrooms = 1;
  String _county = 'Montserrado';
  String? _community;
  String _postedBy = 'landlord';
  final Map<String, bool> _amenities = {};
  final List<String> _existingPhotos = [];
  final List<XFile> _newPhotos = [];
  final Map<String, Uint8List> _previews = {};

  bool _saving = false;
  String _progress = '';

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final me = Session.instance.profile;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(text: e == null ? '' : e.priceMonthly.round().toString());
    _landmark = TextEditingController(text: e?.landmark ?? '');
    _agentFee = TextEditingController(text: e?.agentFee ?? '');
    _contactName = TextEditingController(text: me?.name ?? '');
    _phone = TextEditingController(text: me?.phone ?? '');
    _whatsapp = TextEditingController(text: me?.whatsapp ?? '');
    if (e != null) {
      _type = e.type;
      _currency = e.currency;
      _advance = e.advanceMonths;
      _bedrooms = e.bedrooms;
      _county = e.county;
      _community = communities.contains(e.community) ? e.community : 'Other';
      _postedBy = e.postedBy;
      _amenities.addAll(e.amenities);
      _existingPhotos.addAll(e.photos);
      _loadContact(e.id);
    } else if (me?.role == 'agent') {
      _postedBy = 'agent';
    }
  }

  Future<void> _loadContact(String id) async {
    try {
      final c = await ListingService.instance.contactFor(id);
      if (c != null && mounted) {
        setState(() {
          _contactName.text = c.name;
          _phone.text = c.phone;
          _whatsapp.text = c.whatsapp;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _price, _landmark, _agentFee, _contactName, _phone, _whatsapp]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _photoCount => _existingPhotos.length + _newPhotos.length;

  Future<void> _addPhotos({bool camera = false}) async {
    try {
      final List<XFile> picked;
      if (camera) {
        final shot = await PhotoService.instance.takePhoto();
        picked = shot == null ? <XFile>[] : <XFile>[shot];
      } else {
        picked = await PhotoService.instance.pickPhotos();
      }
      final room = _maxPhotos - _photoCount;
      final take = picked.take(room).toList();
      for (final f in take) {
        _previews[f.path] = await f.readAsBytes();
      }
      setState(() => _newPhotos.addAll(take));
      if (picked.length > room && mounted) {
        showMessage(context, 'Only $_maxPhotos photos allowed.');
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      showMessage(context, 'Please fill in the missing details.');
      return;
    }
    if (_community == null) {
      showMessage(context, 'Choose the community.');
      return;
    }
    if (_photoCount < _minPhotos) {
      showMessage(context, 'Add at least $_minPhotos clear photos.');
      return;
    }
    setState(() => _saving = true);
    try {
      final urls = [..._existingPhotos];
      for (var i = 0; i < _newPhotos.length; i++) {
        setState(() => _progress = 'Uploading photo ${i + 1} of ${_newPhotos.length}...');
        urls.add(await PhotoService.instance.upload(_newPhotos[i]));
      }
      setState(() => _progress = 'Saving...');
      final listing = Listing(
        id: widget.existing?.id ?? '',
        ownerId: widget.existing?.ownerId ?? Session.instance.user!.uid,
        postedBy: _postedBy,
        agentFee: _postedBy == 'agent' ? _agentFee.text.trim() : '',
        type: _type,
        title: _title.text.trim(),
        description: _description.text.trim(),
        priceMonthly: double.parse(_price.text.replaceAll(',', '').trim()),
        currency: _currency,
        advanceMonths: _advance,
        county: _county,
        community: _community!,
        landmark: _landmark.text.trim(),
        bedrooms: _bedrooms,
        amenities: Map.of(_amenities)..removeWhere((_, v) => !v),
        photos: urls,
      );
      final contact = ListingContact(
        name: _contactName.text,
        phone: _phone.text,
        whatsapp: _whatsapp.text,
      );
      if (_editing) {
        await ListingService.instance.updateContent(listing, contact);
      } else {
        await ListingService.instance.create(listing, contact);
      }
      if (!mounted) return;
      showMessage(context, 'Saved. We will review it and put it live soon.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _progress = '';
        });
      }
    }
  }

  /// Step heading: the steps really are a sequence, so they carry numbers.
  Widget _section(String title, [String? hint]) {
    final m = RegExp(r'^(\d+)\.\s*(.*)$').firstMatch(title);
    final number = m?.group(1);
    final label = m?.group(2) ?? title;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (number != null) ...[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Brand.sign, shape: BoxShape.circle),
            child: Text(number,
                style: display(const TextStyle(color: Brand.ink, fontWeight: FontWeight.w800, fontSize: 15))),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(label, style: text.titleLarge?.copyWith(fontSize: 18)),
            ),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(hint,
                    style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _counter(String label, int value, int min, int max, ValueChanged<int> onChanged) =>
      Row(children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.center)),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit place' : 'Add a place')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), children: [
            if (_editing)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Changes go back to review before the place shows again.'),
              ),
            _section('1. What kind of place?'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in listingTypes.entries)
                PickChip(
                  label: e.value,
                  selected: _type == e.key,
                  onTap: () => setState(() => _type = e.key),
                ),
            ]),
            if (_type.startsWith('apartment') || _type == 'house')
              _counter('Bedrooms', _bedrooms, 1, 10, (v) => setState(() => _bedrooms = v)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Short title',
                hintText: 'e.g. Clean room with inside toilet near ELWA junction',
              ),
              maxLength: 80,
              validator: (v) => (v ?? '').trim().length < 8 ? 'Write a short title' : null,
            ),
            _section('2. Price'),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Rent per month'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '').trim());
                    return n == null || n <= 0 ? 'Enter the monthly rent' : null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'USD', label: Text('US\$')),
                    ButtonSegment(value: 'LRD', label: Text('L\$')),
                  ],
                  selected: {_currency},
                  onSelectionChanged: (s) => setState(() => _currency = s.first),
                ),
              ),
            ]),
            _counter('Months of rent due before moving in', _advance, 0, 24,
                (v) => setState(() => _advance = v)),
            _section('3. Where is it?'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _county,
              decoration: const InputDecoration(labelText: 'County'),
              items: [for (final c in counties) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _county = v ?? _county),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _community,
              decoration: const InputDecoration(labelText: 'Community'),
              items: [for (final c in communities) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _community = v),
              validator: (v) => v == null ? 'Choose the community' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _landmark,
              decoration: const InputDecoration(
                labelText: 'Landmark or directions',
                hintText: 'e.g. Behind ELWA junction, second right after the church',
              ),
            ),
            _section('4. What does it have?', 'Tick only what is really there.'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in amenityLabels.entries)
                PickChip(
                  label: e.value,
                  icon: amenityIcons[e.key],
                  selected: _amenities[e.key] == true,
                  onTap: () => setState(() => _amenities[e.key] = !(_amenities[e.key] ?? false)),
                ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'More details (optional)',
                hintText: 'Condition, rules, who it suits, nearby transport...',
              ),
              maxLines: 4,
              maxLength: 800,
            ),
            _section('5. Photos', 'Add $_minPhotos to $_maxPhotos clear photos: outside, rooms, toilet, kitchen.'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final url in _existingPhotos)
                _thumb(NetPhoto(url), () => setState(() => _existingPhotos.remove(url))),
              for (final f in _newPhotos)
                _thumb(
                  _previews[f.path] == null
                      ? const NetPhoto(null)
                      : Image.memory(_previews[f.path]!, fit: BoxFit.cover),
                  () => setState(() => _newPhotos.remove(f)),
                ),
              if (_photoCount < _maxPhotos) ...[
                _addTile(Icons.photo_library_outlined, 'Gallery', () => _addPhotos()),
                if (!kIsWeb) _addTile(Icons.photo_camera_outlined, 'Camera', () => _addPhotos(camera: true)),
              ],
            ]),
            _section('6. Who is posting and how to reach you'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              PickChip(
                label: 'I am the landlord',
                icon: Icons.person_outline,
                selected: _postedBy == 'landlord',
                onTap: () => setState(() => _postedBy = 'landlord'),
              ),
              PickChip(
                label: 'I am an agent',
                icon: Icons.badge_outlined,
                selected: _postedBy == 'agent',
                onTap: () => setState(() => _postedBy = 'agent'),
              ),
            ]),
            if (_postedBy == 'agent') const SizedBox(height: 12),
            if (_postedBy == 'agent')
              TextFormField(
                controller: _agentFee,
                decoration: const InputDecoration(
                  labelText: 'Agent fee (must be stated)',
                  hintText: 'e.g. Half of one month rent',
                ),
                validator: (v) =>
                    _postedBy == 'agent' && (v ?? '').trim().isEmpty ? 'State your agent fee' : null,
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactName,
              decoration: const InputDecoration(labelText: 'Contact name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone number', hintText: '0777 123 456'),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v ?? '').replaceAll(RegExp(r'[^0-9]'), '').length < 7 ? 'Enter a phone number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _whatsapp,
              decoration: const InputDecoration(
                labelText: 'WhatsApp number (if different)',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Text(
              'Renters who sign in can see this number. Never ask for money before a viewing; '
              'fake listings are removed and the account is banned.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_progress.isNotEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_progress)),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_editing ? 'Save changes' : 'Send for review'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _thumb(Widget image, VoidCallback onRemove) => SizedBox(
        width: 96,
        height: 96,
        child: Stack(fit: StackFit.expand, children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ]),
      );

  Widget _addTile(IconData icon, String label, VoidCallback onTap) => SizedBox(
        width: 96,
        height: 96,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ]),
        ),
      );
}
