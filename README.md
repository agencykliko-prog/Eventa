# Eventa

**Le budget parfait pour célébrer.**

Application d'organisation d'événements (Côte d'Ivoire, FCFA) : budget, planification des tâches, marketplace de prestataires, réservations, paiements et coordination d'équipe. Deux profils : **Organisateur** et **Creator** (prestataires, agences).

> Version de démonstration : données fictives locales, connexion simulée, paiements et agent IA simulés. Aucun backend n'est encore branché (Supabase prévu).

## Fonctionnalités

- **Organisateur** : accueil (événement à venir, budget, échéances, actions prioritaires), dashboard par événement, budget éditable avec répartition et export CSV, agenda Jour / Semaine / Mois, marketplace avec filtres et demande de devis, réservation en 7 étapes, coffre-fort et agent IA (Premium), collaborateurs avec droits.
- **Creator** : tableau de bord (chiffre d'affaires, demandes à traiter, prestations), boîte des demandes de devis, agenda, profil public, offre Business / Creator et Publicité Premium.
- Inscription et connexion pour les deux profils, photo de profil avec recadrage.
- Interface responsive : barre d'onglets sur mobile, rail latéral sur tablette et ordinateur.

## Stack

Flutter (Dart 3) · Riverpod · go_router · Inter · icônes Phosphor (polices embarquées).

## Lancer le projet

```bash
flutter pub get
flutter run -d chrome
```

Tests et analyse :

```bash
flutter analyze
flutter test
```

Version web :

```bash
flutter build web --release
```

## Structure

```
lib/
  core/        thème, routeur, composants partagés, utilitaires
  features/    une dossier par fonctionnalité (auth, home, dashboard,
               budget, planning, marketplace, booking, creator, …)
test/          tests unitaires et de widgets
```

Le contexte produit est décrit dans [PRODUCT.md](PRODUCT.md).
