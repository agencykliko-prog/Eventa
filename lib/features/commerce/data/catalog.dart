import 'package:flutter/widgets.dart';

import '../../../core/theme/app_icons.dart';
import '../../events/domain/models.dart';
import '../domain/commerce_models.dart';

/// Catalogue de démonstration — prestataires, produits et offres fictifs.
abstract final class Catalog {
  static const _v = 'assets/images/v';

  static const vendors = <Vendor>[
    // Lieux
    Vendor(
      id: 'latrille',
      name: 'Espace Latrille Events',
      category: VendorCategory.venue,
      tagline: 'Salle de réception · 500 places',
      description:
          'Grande salle climatisée au cœur de Cocody, parking 150 places, '
          'cuisine traiteur équipée et jardin pour les photos.',
      priceFrom: 2500000,
      image: '$_v/venue_2.jpg',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 212,
      sponsor: Sponsor.ofTheMonth,
      responseTime: '30 min',
      packages: [
        VendorPackage('Soirée', 2500000, 'Salle 18 h – 3 h, mobilier inclus'),
        VendorPackage('Journée', 3800000, 'Salle et jardin 10 h – 3 h'),
        VendorPackage('Week-end', 6200000, 'Dot + réception, 2 jours'),
      ],
    ),
    Vendor(
      id: 'domaine-lagune',
      name: 'Domaine de la Lagune',
      category: VendorCategory.venue,
      tagline: 'Domaine en plein air · 300 places',
      description:
          'Pelouse face à la lagune Ébrié, idéal pour cérémonies laïques et '
          'cocktails au coucher du soleil.',
      priceFrom: 1800000,
      image: '$_v/venue_1.jpg',
      zone: 'Bingerville',
      rating: 4.7,
      reviews: 96,
      available: false,
      nextAvailable: 'Libre à partir du 14 déc.',
      packages: [
        VendorPackage('Cérémonie', 1800000, 'Pelouse et arche, 4 h'),
        VendorPackage('Journée complète', 2900000, 'Cérémonie et réception'),
      ],
    ),
    Vendor(
      id: 'villa-azur',
      name: 'Villa Azur Assinie',
      category: VendorCategory.venue,
      tagline: 'Villa avec piscine · 80 personnes',
      description:
          'Villa pieds dans l’eau à Assinie, 6 chambres, piscine à débordement. '
          'Parfaite pour EVJF, anniversaires et pool parties.',
      priceFrom: 650000,
      unit: 'nuit',
      image: '$_v/venue_3.jpg',
      zone: 'Assinie',
      rating: 4.8,
      reviews: 141,
      sponsor: Sponsor.featured,
      packages: [
        VendorPackage('Nuit', 650000, '6 chambres, piscine, ménage inclus'),
        VendorPackage('Week-end', 1200000, '2 nuits, chef sur demande'),
      ],
    ),
    // Décoration
    Vendor(
      id: 'ines-deco',
      name: 'Maison Inès Déco',
      category: VendorCategory.decor,
      tagline: 'Fleurs & scénographie',
      description:
          'Compositions florales fraîches, arches, centres de table et '
          'scénographie sur mesure. Moodboard offert.',
      priceFrom: 450000,
      image: '$_v/decor_1.jpg',
      zone: 'Riviera',
      rating: 4.8,
      reviews: 178,
      sponsor: Sponsor.recommended,
      packages: [
        VendorPackage('Essentiel', 450000, 'Arche + 10 centres de table'),
        VendorPackage('Signature', 1200000, 'Scénographie complète'),
      ],
    ),
    Vendor(
      id: 'ballon-studio',
      name: 'Ballon Studio CI',
      category: VendorCategory.decor,
      tagline: 'Arches & installations ballons',
      description:
          'Arches organiques, murs de ballons et photocalls pour anniversaires, '
          'baby showers et lancements.',
      priceFrom: 85000,
      image: '$_v/decor_2.jpg',
      zone: 'Marcory',
      rating: 4.6,
      reviews: 88,
      packages: [
        VendorPackage('Arche', 85000, 'Arche organique 3 m'),
        VendorPackage('Photocall', 160000, 'Mur + arche + néon'),
      ],
    ),
    Vendor(
      id: 'table-lumiere',
      name: 'Table & Lumière',
      category: VendorCategory.decor,
      tagline: 'Art de la table & bougies',
      description:
          'Nappage, vaisselle dorée, bougies et chemins de table pour des '
          'dîners élégants.',
      priceFrom: 180000,
      image: '$_v/decor_3.jpg',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 54,
      verified: false,
    ),
    // Restauration
    Vendor(
      id: 'saveurs',
      name: 'Saveurs d’Ivoire',
      category: VendorCategory.catering,
      tagline: 'Traiteur · cuisine ivoirienne & fusion',
      description:
          'Garba revisité, kedjenou, alloco, buffets froids et chauds. '
          'Service à table possible, dégustation offerte dès 100 couverts.',
      priceFrom: 13500,
      unit: 'pers.',
      image: '$_v/food_1.jpg',
      zone: 'Marcory',
      rating: 4.8,
      reviews: 264,
      sponsor: Sponsor.recommended,
      responseTime: '45 min',
      packages: [
        VendorPackage('Buffet', 13500, 'Par personne, 3 plats + dessert'),
        VendorPackage(
          'Service à table',
          19500,
          'Par personne, serveurs inclus',
        ),
      ],
    ),
    Vendor(
      id: 'tantie-aya',
      name: 'Chez Tantie Aya',
      category: VendorCategory.catering,
      tagline: 'Traiteur familial · grands groupes',
      description:
          'Riz gras, attiéké poisson, poulet braisé : la cuisine de maison '
          'pour 50 à 800 invités, livrée chaude.',
      priceFrom: 8500,
      unit: 'pers.',
      image: '$_v/food_3.jpg',
      zone: 'Yopougon',
      rating: 4.6,
      reviews: 131,
    ),
    Vendor(
      id: 'douce-heure',
      name: 'Douce Heure',
      category: VendorCategory.catering,
      tagline: 'Pâtisserie & wedding cakes',
      description:
          'Pièces montées, layer cakes, cupcakes et bars à desserts. '
          'Dégustation sur rendez-vous.',
      priceFrom: 60000,
      image: '$_v/food_2.jpg',
      zone: 'Deux-Plateaux',
      rating: 4.9,
      reviews: 97,
    ),
    // Photo & vidéo
    Vendor(
      id: 'studio-lumiere',
      name: 'Studio Lumière',
      category: VendorCategory.photo,
      tagline: 'Photographe mariage & portrait',
      description:
          'Reportage complet de la préparation à la soirée, galerie privée '
          'en ligne sous 3 semaines, album imprimé en option.',
      priceFrom: 450000,
      image: '$_v/photo_1.jpg',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 156,
      sponsor: Sponsor.recommended,
      packages: [
        VendorPackage('Reportage', 450000, '8 h, 400 photos retouchées'),
        VendorPackage('Photo + album', 650000, 'Reportage et album 30×30'),
      ],
    ),
    Vendor(
      id: 'motion-films',
      name: 'Motion Films CI',
      category: VendorCategory.photo,
      tagline: 'Vidéaste & drone',
      description:
          'Film de mariage cinématique, teaser 1 min pour les réseaux et '
          'prises de vue par drone.',
      priceFrom: 550000,
      image: '$_v/photo_2.jpg',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 72,
      available: false,
      nextAvailable: 'Libre à partir du 20 nov.',
    ),
    // Animation
    Vendor(
      id: 'lagune-sound',
      name: 'Lagune Sound',
      category: VendorCategory.music,
      tagline: 'DJ & sonorisation',
      description:
          'DJ ambianceur coupé-décalé, afrobeats et classiques, sono et '
          'lumières incluses jusqu’à 400 invités.',
      priceFrom: 300000,
      image: '$_v/music_1.jpg',
      zone: 'Plateau',
      rating: 4.6,
      reviews: 119,
      sponsor: Sponsor.result,
    ),
    Vendor(
      id: 'groove-band',
      name: 'Groove Live Band',
      category: VendorCategory.music,
      tagline: 'Orchestre live · 6 musiciens',
      description:
          'Orchestre pour cocktail et première danse, répertoire highlife, '
          'zouk, rumba et variétés.',
      priceFrom: 750000,
      image: '$_v/music_2.jpg',
      zone: 'Cocody',
      rating: 4.8,
      reviews: 61,
    ),
    // Location
    Vendor(
      id: 'location-prestige',
      name: 'Abidjan Location Prestige',
      category: VendorCategory.rental,
      tagline: 'Chaises, tables & vaisselle',
      description:
          'Chaises Chiavari, tables rondes, vaisselle et nappage. Livraison et '
          'installation incluses à Abidjan.',
      priceFrom: 2500,
      unit: 'chaise',
      image: '$_v/rental_1.jpg',
      zone: 'Koumassi',
      rating: 4.5,
      reviews: 83,
    ),
    Vendor(
      id: 'tentes-co',
      name: 'Tentes & Co',
      category: VendorCategory.rental,
      tagline: 'Chapiteaux & tentes',
      description:
          'Chapiteaux de 50 à 600 places, plancher, éclairage et '
          'climatisation mobile.',
      priceFrom: 350000,
      image: '$_v/rental_2.jpg',
      zone: 'Bingerville',
      rating: 4.6,
      reviews: 47,
    ),
    // Mode & beauté
    Vendor(
      id: 'glam-fatim',
      name: 'Glam by Fatim',
      category: VendorCategory.beauty,
      tagline: 'Maquillage & coiffure',
      description:
          'Mise en beauté de la mariée et du cortège, essai inclus, '
          'déplacement à domicile.',
      priceFrom: 120000,
      image: '$_v/beauty_1.jpg',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 203,
      sponsor: Sponsor.result,
    ),
    Vendor(
      id: 'pagne-royal',
      name: 'Atelier Pagne Royal',
      category: VendorCategory.beauty,
      tagline: 'Couture & pagne du cortège',
      description:
          'Tenues sur mesure, pagne commun pour la famille et le cortège, '
          'gestion des tailles et de la distribution.',
      priceFrom: 25000,
      unit: 'tenue',
      image: '$_v/beauty_2.jpg',
      zone: 'Treichville',
      rating: 4.7,
      reviews: 112,
    ),
    // Papeterie
    Vendor(
      id: 'papeterie-kente',
      name: 'Papeterie Kente',
      category: VendorCategory.paper,
      tagline: 'Faire-part & papeterie',
      description:
          'Faire-part, menus, marque-places et plans de table assortis, '
          'impression locale en 5 jours.',
      priceFrom: 1200,
      unit: 'carte',
      image: '$_v/paper_1.jpg',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 66,
    ),
    Vendor(
      id: 'merci-studio',
      name: 'Merci Studio',
      category: VendorCategory.paper,
      tagline: 'Cartes de remerciement & cadeaux',
      description:
          'Cartes de remerciement, étiquettes et cadeaux invités '
          'personnalisés.',
      priceFrom: 900,
      unit: 'carte',
      image: '$_v/paper_2.jpg',
      zone: 'Riviera',
      rating: 4.6,
      reviews: 38,
      verified: false,
    ),
    // Transport
    Vendor(
      id: 'prestige-limo',
      name: 'Prestige Limousine CI',
      category: VendorCategory.transport,
      tagline: 'Voitures de mariés',
      description:
          'Limousines et berlines décorées avec chauffeur en tenue, '
          'forfait demi-journée.',
      priceFrom: 250000,
      image: '$_v/transport_1.jpg',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 58,
    ),
    Vendor(
      id: 'navette-express',
      name: 'Navette Express',
      category: VendorCategory.transport,
      tagline: 'Navettes invités · 30 à 70 places',
      description:
          'Cars climatisés pour transporter vos invités entre cérémonies, '
          'hôtel et réception.',
      priceFrom: 180000,
      unit: 'car',
      image: '$_v/transport_2.jpg',
      zone: 'Port-Bouët',
      rating: 4.5,
      reviews: 44,
    ),
    // Personnel
    Vendor(
      id: 'service-elegance',
      name: 'Service Élégance',
      category: VendorCategory.staff,
      tagline: 'Serveurs & hôtesses',
      description:
          'Équipes de service formées, hôtesses d’accueil et maîtres d’hôtel '
          'pour vos réceptions.',
      priceFrom: 25000,
      unit: 'serveur',
      image: '$_v/staff_1.jpg',
      zone: 'Cocody',
      rating: 4.6,
      reviews: 77,
    ),
    Vendor(
      id: 'barmen',
      name: 'Barmen d’Abidjan',
      category: VendorCategory.staff,
      tagline: 'Bar à cocktails mobile',
      description:
          'Bar mobile, mixologues et carte de cocktails avec ou sans alcool.',
      priceFrom: 220000,
      image: '$_v/staff_2.jpg',
      zone: 'Marcory',
      rating: 4.8,
      reviews: 52,
    ),
    // Organisation
    Vendor(
      id: 'atelier-celebration',
      name: 'Atelier Célébration',
      category: VendorCategory.planner,
      tagline: 'Wedding planner',
      description:
          'Organisation complète ou partielle, coordination du jour J, '
          'gestion des familles et des prestataires.',
      priceFrom: 800000,
      image: '$_v/planner_1.jpg',
      zone: 'Cocody',
      rating: 4.9,
      reviews: 89,
    ),
    Vendor(
      id: 'jour-j',
      name: 'Jour J Conciergerie',
      category: VendorCategory.planner,
      tagline: 'Coordination du jour J',
      description:
          'Une coordinatrice dédiée le jour J pour que vous profitiez, '
          'du réveil au dernier invité.',
      priceFrom: 250000,
      image: '$_v/planner_2.jpg',
      zone: 'Plateau',
      rating: 4.7,
      reviews: 41,
    ),
    // Activités
    Vendor(
      id: 'assinie-boat',
      name: 'Assinie Boat Tours',
      category: VendorCategory.activity,
      tagline: 'Sorties en bateau',
      description:
          'Croisières privées sur la lagune, déjeuner à bord et baignade '
          'sur une île.',
      priceFrom: 35000,
      unit: 'pers.',
      image: '$_v/activity_1.jpg',
      zone: 'Assinie',
      rating: 4.8,
      reviews: 134,
    ),
    Vendor(
      id: 'spa-zen',
      name: 'Spa Ivoire Zen',
      category: VendorCategory.activity,
      tagline: 'Spa & bien-être de groupe',
      description:
          'Journées spa privatisées pour EVJF et équipes : massages, hammam, '
          'brunch.',
      priceFrom: 45000,
      unit: 'pers.',
      image: '$_v/activity_2.jpg',
      zone: 'Cocody',
      rating: 4.7,
      reviews: 69,
    ),
  ];

  static Vendor vendor(String id) => vendors.firstWhere((v) => v.id == id);

  static const reviews = [
    Review(
      'Aminata K.',
      5,
      'Équipe réactive et très professionnelle, tout était prêt à l’heure.',
      '12 oct. 2026',
    ),
    Review(
      'Jean-Marc B.',
      5,
      'Rapport qualité-prix excellent, nos invités en parlent encore.',
      '28 sept. 2026',
    ),
    Review(
      'Mariette D.',
      4,
      'Très bon service, un petit retard au montage vite rattrapé.',
      '9 sept. 2026',
    ),
    Review(
      'Koffi A.',
      5,
      'Devis clair, aucune surprise le jour J. Je recommande.',
      '22 août 2026',
    ),
    Review(
      'Sarah T.',
      4,
      'Belle prestation, communication un peu lente avant l’événement.',
      '3 août 2026',
    ),
    Review(
      'Ibrahim S.',
      5,
      'Exactement ce que nous avions imaginé, merci !',
      '15 juil. 2026',
    ),
  ];

  // ─── Abonnements ─────────────────────────────────────────────────────

  static const planFeatures = <Plan, List<String>>{
    Plan.free: [
      'Événements illimités',
      'Budget manuel et checklist',
      '2 collaborateurs offerts',
      'Marketplace et réservations',
    ],
    Plan.azur: [
      'Budget créé par l’IA',
      'Graphiques et export du budget',
      'Jusqu’à 5 collaborateurs',
      'Rappels WhatsApp et SMS',
      'QR code RSVP',
    ],
    Plan.signature: [
      'Tout Azur',
      'Agent IA de votre type d’événement',
      'Coffre-fort numérique (5 Go)',
      'Collaborateurs illimités',
      'Négociation de devis par l’IA',
    ],
    Plan.privilege: [
      'Tout Signature',
      'Concierge IA prioritaire',
      'Coffre-fort 50 Go et album privé',
      'Support prioritaire 7 j/7',
      'Accès anticipé aux nouveautés',
    ],
  };

  // ─── Agents IA ───────────────────────────────────────────────────────

  static AgentProfile agent(EventCategory c) => switch (c) {
    EventCategory.wedding => const AgentProfile(
      'Wedding Planner IA',
      'Votre organisatrice de mariage, disponible jour et nuit.',
      [
        AgentSkill('Créer le budget', AppIcons.wallet, AgentAction.budget),
        AgentSkill(
          'Négocier un devis',
          AppIcons.handshake,
          AgentAction.negotiate,
        ),
        AgentSkill(
          'Trouver des économies',
          AppIcons.piggy,
          AgentAction.savings,
        ),
        AgentSkill(
          'Générer le planning',
          AppIcons.calendarCheck,
          AgentAction.planning,
        ),
        AgentSkill('Plan de table', AppIcons.table, AgentAction.seating),
        AgentSkill('Invitations', AppIcons.mail, AgentAction.invitations),
        AgentSkill(
          'Messages aux invités',
          AppIcons.message,
          AgentAction.guestMessage,
        ),
        AgentSkill(
          'Dépenses restantes',
          AppIcons.calculator,
          AgentAction.remaining,
        ),
      ],
    ),
    EventCategory.birthday => const AgentProfile(
      'Party Planner IA',
      'Thème, surprise et quantités : la fête calculée au plus juste.',
      [
        AgentSkill(
          'Orchestrer la surprise',
          AppIcons.eyeOff,
          AgentAction.planning,
        ),
        AgentSkill(
          'Quantités gâteau & boissons',
          AppIcons.calculator,
          AgentAction.remaining,
        ),
        AgentSkill(
          'Trouver des économies',
          AppIcons.piggy,
          AgentAction.savings,
        ),
        AgentSkill('Invitations', AppIcons.mail, AgentAction.invitations),
      ],
    ),
    EventCategory.baby => const AgentProfile(
      'Baby Planner IA',
      'Tout organiser sans fatiguer les futurs parents.',
      [
        AgentSkill('Liste de naissance', AppIcons.gift, AgentAction.savings),
        AgentSkill(
          'Planning doux',
          AppIcons.calendarCheck,
          AgentAction.planning,
        ),
        AgentSkill('Faire-part', AppIcons.mail, AgentAction.invitations),
        AgentSkill(
          'Budget restant',
          AppIcons.calculator,
          AgentAction.remaining,
        ),
      ],
    ),
    EventCategory.friends => const AgentProfile(
      'Squad Planner IA',
      'Qui doit quoi, qui vient, qui dort où.',
      [
        AgentSkill(
          'Partager les frais',
          AppIcons.handCoins,
          AgentAction.remaining,
        ),
        AgentSkill('Sondage express', AppIcons.chart, AgentAction.planning),
        AgentSkill(
          'Relancer le groupe',
          AppIcons.message,
          AgentAction.guestMessage,
        ),
        AgentSkill(
          'Trouver des économies',
          AppIcons.piggy,
          AgentAction.savings,
        ),
      ],
    ),
    EventCategory.outing => const AgentProfile(
      'Trip Planner IA',
      'Météo, matériel et trajets pour une sortie sans oubli.',
      [
        AgentSkill('Météo & plan B', AppIcons.sun, AgentAction.planning),
        AgentSkill('Liste du matériel', AppIcons.tasks, AgentAction.seating),
        AgentSkill(
          'Courses par personne',
          AppIcons.calculator,
          AgentAction.remaining,
        ),
        AgentSkill(
          'Message au groupe',
          AppIcons.message,
          AgentAction.guestMessage,
        ),
      ],
    ),
    EventCategory.pro => const AgentProfile(
      'Event Ops IA',
      'Budget validé, programme tenu, ROI mesuré.',
      [
        AgentSkill('Budget & validation', AppIcons.wallet, AgentAction.budget),
        AgentSkill('Programme', AppIcons.calendarCheck, AgentAction.planning),
        AgentSkill(
          'Négocier un devis',
          AppIcons.handshake,
          AgentAction.negotiate,
        ),
        AgentSkill('Rapport ROI', AppIcons.chartUp, AgentAction.remaining),
      ],
    ),
    EventCategory.milestone => const AgentProfile(
      'Hommage IA',
      'Un pot réussi en 48 h, des mots justes.',
      [
        AgentSkill(
          'Organisation express',
          AppIcons.lightning,
          AgentAction.planning,
        ),
        AgentSkill(
          'Écrire le discours',
          AppIcons.mic,
          AgentAction.guestMessage,
        ),
        AgentSkill('Cagnotte', AppIcons.handCoins, AgentAction.remaining),
      ],
    ),
    EventCategory.family => const AgentProfile(
      'Family Coordinator IA',
      'Cotisations, branches et commissions coordonnées.',
      [
        AgentSkill(
          'Suivi des cotisations',
          AppIcons.handCoins,
          AgentAction.remaining,
        ),
        AgentSkill('Programme', AppIcons.calendarCheck, AgentAction.planning),
        AgentSkill(
          'Message aux familles',
          AppIcons.message,
          AgentAction.guestMessage,
        ),
      ],
    ),
    EventCategory.charity => const AgentProfile(
      'Impact Planner IA',
      'Collecte, bénévoles et transparence.',
      [
        AgentSkill(
          'Objectif de collecte',
          AppIcons.chartUp,
          AgentAction.remaining,
        ),
        AgentSkill(
          'Remercier les donateurs',
          AppIcons.message,
          AgentAction.guestMessage,
        ),
        AgentSkill(
          'Trouver des économies',
          AppIcons.piggy,
          AgentAction.savings,
        ),
      ],
    ),
    EventCategory.seasonal => const AgentProfile(
      'Season Planner IA',
      'Réservez avant la hausse des prix, offrez sans oublier personne.',
      [
        AgentSkill(
          'Alertes prix de saison',
          AppIcons.reminder,
          AgentAction.savings,
        ),
        AgentSkill('Secret Santa', AppIcons.gift, AgentAction.seating),
        AgentSkill('Menu & courses', AppIcons.food, AgentAction.planning),
      ],
    ),
  };

  // ─── Business / Creator ──────────────────────────────────────────────

  static const businessAudience = [
    'Wedding planners',
    'Event planners',
    'Agences événementielles',
    'Hôtels',
    'Salles de réception',
    'Entreprises',
    'Associations',
    'Freelances',
  ];

  static const businessFeatures = <(IconData, String)>[
    (AppIcons.confetti, 'Événements illimités'),
    (AppIcons.crm, 'CRM clients'),
    (AppIcons.file, 'Devis'),
    (AppIcons.contract, 'Contrats'),
    (AppIcons.invoice, 'Facturation'),
    (AppIcons.team, 'Équipe multi-utilisateurs'),
    (AppIcons.palette, 'Marque blanche'),
    (AppIcons.chartUp, 'Tableau de bord financier'),
    (AppIcons.lightning, 'Automatisations'),
    (AppIcons.code, 'API'),
    (AppIcons.plugs, 'Intégrations'),
    (AppIcons.chart, 'Statistiques avancées'),
  ];

  static const adFormats = <(Sponsor, String)>[
    (
      Sponsor.recommended,
      'Badge « Recommandé » sur votre fiche et dans les sélections.',
    ),
    (
      Sponsor.ofTheMonth,
      'La bannière en tête de la marketplace pendant un mois.',
    ),
    (Sponsor.featured, 'Votre fiche en grand format dans « Mises en avant ».'),
    (
      Sponsor.result,
      'Première position sur les recherches de votre catégorie.',
    ),
  ];
}

enum AgentAction {
  budget,
  negotiate,
  savings,
  planning,
  seating,
  invitations,
  guestMessage,
  remaining,
}

@immutable
class AgentSkill {
  const AgentSkill(this.label, this.icon, this.action);
  final String label;
  final IconData icon;
  final AgentAction action;
}

@immutable
class AgentProfile {
  const AgentProfile(this.name, this.pitch, this.skills);
  final String name;
  final String pitch;
  final List<AgentSkill> skills;
}
