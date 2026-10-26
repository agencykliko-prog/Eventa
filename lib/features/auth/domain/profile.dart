import 'package:flutter/foundation.dart';

import '../../../core/i18n/tr.dart';
import '../../events/domain/models.dart';

/// Deux profils, deux interfaces : chacun ne voit que ce qui le concerne.
enum UserRole {
  organizer('Organisateur', 'Je prépare une fête'),
  creator('Creator', 'Prestataire, agence');

  const UserRole(this._label, this._pitch);
  final String _label;
  String get label => _label.tr;
  final String _pitch;
  String get pitch => _pitch.tr;
}

enum CreatorKind {
  freelancer('Prestataire indépendant'),
  agency('Agence événementielle');

  const CreatorKind(this._label);
  final String _label;
  String get label => _label.tr;
}

/// Informations professionnelles d'un Creator.
@immutable
class CreatorInfo {
  const CreatorInfo({
    required this.kind,
    required this.businessName,
    required this.category,
    required this.zone,
    required this.description,
    required this.displayName,
    required this.priceFrom,
    required this.address,
    this.rccm,
    this.website,
    this.portfolio,
  });

  final CreatorKind kind;
  final String businessName;
  final VendorCategory category;
  final String zone;
  final String? rccm;
  final String description;
  final String displayName;
  final int priceFrom;
  final String address;
  final String? website;
  final String? portfolio;

  CreatorInfo copyWith({
    String? displayName,
    int? priceFrom,
    String? description,
    String? address,
    String? website,
    String? zone,
  }) => CreatorInfo(
    kind: kind,
    businessName: businessName,
    category: category,
    zone: zone ?? this.zone,
    rccm: rccm,
    description: description ?? this.description,
    displayName: displayName ?? this.displayName,
    priceFrom: priceFrom ?? this.priceFrom,
    address: address ?? this.address,
    website: website ?? this.website,
    portfolio: portfolio,
  );
}

@immutable
class UserProfile {
  const UserProfile({
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    this.photoAsset,
    this.photoBytes,
    this.creator,
  });

  final UserRole role;
  final String name;
  final String email;
  final String phone;
  final String city;

  /// Photo de démonstration (asset) ou photo importée puis recadrée.
  final String? photoAsset;
  final Uint8List? photoBytes;
  final CreatorInfo? creator;

  bool get isCreator => role == UserRole.creator;
  String get firstName => name.split(' ').first;
  String get initials => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? city,
    Uint8List? photoBytes,
    CreatorInfo? creator,
  }) => UserProfile(
    role: role,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    photoAsset: photoBytes == null ? photoAsset : null,
    photoBytes: photoBytes ?? this.photoBytes,
    creator: creator ?? this.creator,
  );

  static const demoOrganizer = UserProfile(
    role: UserRole.organizer,
    name: 'Awa Traoré',
    email: 'awa.traore@gmail.com',
    phone: '+225 07 08 12 34 56',
    city: 'Abidjan',
    photoAsset: 'assets/images/avatar_1.jpg',
  );

  static const demoCreator = UserProfile(
    role: UserRole.creator,
    name: 'Inès Kouadio',
    email: 'contact@inesdeco.ci',
    phone: '+225 05 44 21 09 87',
    city: 'Abidjan',
    photoAsset: 'assets/images/avatar_3.jpg',
    creator: CreatorInfo(
      kind: CreatorKind.freelancer,
      businessName: 'Maison Inès Déco',
      category: VendorCategory.decor,
      zone: 'Abidjan · Riviera',
      description:
          'Compositions florales fraîches, arches, centres de table et '
          'scénographie sur mesure. Moodboard offert.',
      displayName: 'Maison Inès Déco',
      priceFrom: 450000,
      address: 'Riviera 3, Cocody, Abidjan',
      website: 'inesdeco.ci',
      portfolio: 'instagram.com/maisoninesdeco',
    ),
  );
}
