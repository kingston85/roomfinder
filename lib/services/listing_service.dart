import 'package:cloud_firestore/cloud_firestore.dart';

import '../config.dart';
import '../models/listing.dart';

/// All Firestore reads and writes for listings, saves and reports.
class ListingService {
  ListingService._();
  static final ListingService instance = ListingService._();

  final _db = FirebaseFirestore.instance;
  static final _epoch = DateTime(2000);

  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection('listings');

  // ---------- Renter side ----------

  /// Live listings confirmed in the last [AppConfig.freshDays] days, newest
  /// confirmation first. Community and type are filtered on the phone, so the
  /// only index needed is status + lastConfirmedAt (already created).
  Stream<List<Listing>> searchLive({String? community, String? type}) {
    final cutoff = DateTime.now().subtract(Duration(days: AppConfig.freshDays));
    return _listings
        .where('status', isEqualTo: 'live')
        .where('lastConfirmedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('lastConfirmedAt', descending: true)
        .limit(300)
        .snapshots()
        .map((s) => s.docs
            .map(Listing.fromDoc)
            .where((l) => community == null || l.community == community)
            .where((l) => type == null || l.type == type)
            .toList());
  }

  Stream<Listing?> watch(String id) => _listings
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Listing.fromDoc(d) : null);

  Future<ListingContact?> contactFor(String listingId) async {
    final d = await _db.collection('listingContacts').doc(listingId).get();
    if (!d.exists) return null;
    final m = d.data()!;
    return ListingContact(
      phone: m['phone'] ?? '',
      whatsapp: m['whatsapp'] ?? '',
      name: m['name'] ?? '',
    );
  }

  // ---------- Saves (users/{uid}/saves/{listingId}) ----------

  CollectionReference<Map<String, dynamic>> _saves(String uid) =>
      _db.collection('users').doc(uid).collection('saves');

  Stream<Set<String>> savedIds(String uid) =>
      _saves(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> toggleSave(String uid, String listingId, bool save) => save
      ? _saves(uid).doc(listingId).set({'createdAt': FieldValue.serverTimestamp()})
      : _saves(uid).doc(listingId).delete();

  /// Loads saved listings one by one so a hidden or deleted listing (which the
  /// rules no longer let this user read) simply drops out of the list.
  Future<List<Listing>> loadListings(Iterable<String> ids) async {
    final out = <Listing>[];
    for (final id in ids) {
      try {
        final d = await _listings.doc(id).get();
        if (d.exists) out.add(Listing.fromDoc(d));
      } on FirebaseException {
        // Not readable any more (no longer live).
      }
    }
    return out;
  }

  // ---------- Landlord / agent side ----------

  /// Sorted on the phone so no extra index is needed.
  Stream<List<Listing>> myListings(String uid) => _listings
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map(Listing.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? _epoch).compareTo(a.createdAt ?? _epoch)));

  Future<String> create(Listing l, ListingContact contact) async {
    final ref = await _listings.add({
      ...l.contentMap(),
      'ownerId': l.ownerId,
      'status': 'pending',
      'approved': false,
      'verified': false,
      'featuredUntil': null,
      'rejectReason': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastConfirmedAt': FieldValue.serverTimestamp(),
    });
    await _setContact(ref.id, contact);
    return ref.id;
  }

  /// Any change to the content sends the listing back for review.
  Future<void> updateContent(Listing l, ListingContact contact) async {
    await _listings.doc(l.id).update({
      ...l.contentMap(),
      'status': 'pending',
      'approved': false,
      'verified': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastConfirmedAt': FieldValue.serverTimestamp(),
    });
    await _setContact(l.id, contact);
  }

  Future<void> _setContact(String id, ListingContact c) =>
      _db.collection('listingContacts').doc(id).set({
        'phone': c.phone.trim(),
        'whatsapp': c.whatsapp.trim(),
        'name': c.name.trim(),
      });

  /// "Yes, it's still free": refreshes the date and puts an approved
  /// listing back in search.
  Future<void> confirmAvailable(Listing l) => _listings.doc(l.id).update({
        'status': l.approved && l.status != 'rejected' ? 'live' : l.status,
        'lastConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> markTaken(String id) => _listings.doc(id).update({
        'status': 'taken',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Deletes the contact first: the rules check ownership through the listing.
  Future<void> delete(String id) async {
    try {
      await _db.collection('listingContacts').doc(id).delete();
    } on FirebaseException {
      // Contact doc may not exist.
    }
    await _listings.doc(id).delete();
  }

  // ---------- Reports ----------

  Future<void> report(String listingId, String reporterId, String reason, String note) =>
      _db.collection('reports').add({
        'listingId': listingId,
        'reporterId': reporterId,
        'reason': reason,
        'note': note.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

  // ---------- Admin ----------

  Stream<List<Listing>> pending() => _listings
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.map(Listing.fromDoc).toList()
        ..sort((a, b) => (a.createdAt ?? _epoch).compareTo(b.createdAt ?? _epoch)));

  Future<void> approve(String id, {required bool verified, required String adminId}) =>
      _listings.doc(id).update({
        'status': 'live',
        'approved': true,
        'verified': verified,
        'verifiedBy': verified ? adminId : null,
        'verifiedAt': verified ? FieldValue.serverTimestamp() : null,
        'rejectReason': '',
        'lastConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setVerified(String id, bool verified, String adminId) =>
      _listings.doc(id).update({
        'verified': verified,
        'verifiedBy': verified ? adminId : null,
        'verifiedAt': verified ? FieldValue.serverTimestamp() : null,
      });

  Future<void> reject(String id, String reason) => _listings.doc(id).update({
        'status': 'rejected',
        'approved': false,
        'rejectReason': reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> hide(String id) => _listings.doc(id).update({
        'status': 'hidden',
        'approved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<List<Report>> openReports() => _db
      .collection('reports')
      .where('status', isEqualTo: 'open')
      .snapshots()
      .map((s) => s.docs.map(Report.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? _epoch).compareTo(a.createdAt ?? _epoch)));

  Future<void> resolveReport(String id, String action) =>
      _db.collection('reports').doc(id).update({
        'status': 'resolved',
        'action': action,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

  Future<void> banUser(String uid) =>
      _db.collection('users').doc(uid).update({'banned': true});
}
