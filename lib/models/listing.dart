import 'package:cloud_firestore/cloud_firestore.dart';

import '../config.dart';

DateTime? _date(dynamic v) => v is Timestamp ? v.toDate() : null;

class Listing {
  Listing({
    this.id = '',
    required this.ownerId,
    this.postedBy = 'landlord',
    this.agentFee = '',
    required this.type,
    required this.title,
    this.description = '',
    required this.priceMonthly,
    this.currency = 'USD',
    this.advanceMonths = 1,
    this.county = 'Montserrado',
    required this.community,
    this.landmark = '',
    this.bedrooms = 1,
    Map<String, bool>? amenities,
    List<String>? photos,
    this.status = 'pending',
    this.approved = false,
    this.verified = false,
    this.verifiedAt,
    this.lastConfirmedAt,
    this.createdAt,
    this.featuredUntil,
    this.rejectReason = '',
  })  : amenities = amenities ?? {},
        photos = photos ?? [];

  final String id;
  final String ownerId;
  final String postedBy; // landlord | agent
  final String agentFee; // free text, e.g. "One month rent"
  final String type;
  final String title;
  final String description;
  final double priceMonthly;
  final String currency; // USD | LRD
  final int advanceMonths;
  final String county;
  final String community;
  final String landmark;
  final int bedrooms;
  final Map<String, bool> amenities;
  final List<String> photos;
  final String status; // pending | live | taken | hidden | rejected
  final bool approved;
  final bool verified;
  final DateTime? verifiedAt;
  final DateTime? lastConfirmedAt;
  final DateTime? createdAt;
  final DateTime? featuredUntil;
  final String rejectReason;

  double get priceUsd =>
      currency == 'LRD' ? priceMonthly / AppConfig.lrdPerUsd : priceMonthly;

  bool get isFeatured =>
      featuredUntil != null && featuredUntil!.isAfter(DateTime.now());

  bool get isFresh =>
      lastConfirmedAt != null &&
      DateTime.now().difference(lastConfirmedAt!).inDays < AppConfig.freshDays;

  bool get needsConfirming =>
      lastConfirmedAt == null ||
      DateTime.now().difference(lastConfirmedAt!).inDays >= AppConfig.freshDays - 4;

  String? get coverPhoto => photos.isEmpty ? null : photos.first;

  factory Listing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawAmenities = (d['amenities'] as Map?) ?? {};
    return Listing(
      id: doc.id,
      ownerId: d['ownerId'] ?? '',
      postedBy: d['postedBy'] ?? 'landlord',
      agentFee: d['agentFee'] ?? '',
      type: d['type'] ?? 'single_room',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      priceMonthly: (d['priceMonthly'] as num?)?.toDouble() ?? 0,
      currency: d['currency'] ?? 'USD',
      advanceMonths: (d['advanceMonths'] as num?)?.toInt() ?? 1,
      county: d['county'] ?? 'Montserrado',
      community: d['community'] ?? '',
      landmark: d['landmark'] ?? '',
      bedrooms: (d['bedrooms'] as num?)?.toInt() ?? 1,
      amenities: rawAmenities.map((k, v) => MapEntry(k.toString(), v == true)),
      photos: List<String>.from(d['photos'] ?? const []),
      status: d['status'] ?? 'pending',
      approved: d['approved'] == true,
      verified: d['verified'] == true,
      verifiedAt: _date(d['verifiedAt']),
      lastConfirmedAt: _date(d['lastConfirmedAt']),
      createdAt: _date(d['createdAt']),
      featuredUntil: _date(d['featuredUntil']),
      rejectReason: d['rejectReason'] ?? '',
    );
  }

  /// Fields the owner is allowed to write (must match firestore.rules).
  Map<String, dynamic> contentMap() => {
        'type': type,
        'title': title,
        'description': description,
        'priceMonthly': priceMonthly,
        'currency': currency,
        'advanceMonths': advanceMonths,
        'county': county,
        'community': community,
        'landmark': landmark,
        'bedrooms': bedrooms,
        'amenities': amenities,
        'photos': photos,
        'postedBy': postedBy,
        'agentFee': agentFee,
      };
}

class AppUser {
  AppUser({
    required this.uid,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.whatsapp = '',
    this.role = 'renter',
    this.banned = false,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String whatsapp;
  final String role; // renter | landlord | agent | admin
  final bool banned;

  bool get isAdmin => role == 'admin';
  bool get canList => role == 'landlord' || role == 'agent' || role == 'admin';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      whatsapp: d['whatsapp'] ?? '',
      role: d['role'] ?? 'renter',
      banned: d['banned'] == true,
    );
  }
}

class ListingContact {
  ListingContact({this.phone = '', this.whatsapp = '', this.name = ''});
  final String phone;
  final String whatsapp;
  final String name;
}

class Report {
  Report({
    required this.id,
    required this.listingId,
    required this.reporterId,
    required this.reason,
    this.note = '',
    this.createdAt,
  });

  final String id;
  final String listingId;
  final String reporterId;
  final String reason;
  final String note;
  final DateTime? createdAt;

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Report(
      id: doc.id,
      listingId: d['listingId'] ?? '',
      reporterId: d['reporterId'] ?? '',
      reason: d['reason'] ?? 'other',
      note: d['note'] ?? '',
      createdAt: _date(d['createdAt']),
    );
  }
}
