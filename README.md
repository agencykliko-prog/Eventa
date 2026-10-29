# Calandix

**Le budget parfait pour célébrer.**

Application d'organisation d'événements (Côte d'Ivoire, FCFA) : budget, planification des tâches, marketplace de prestataires, réservations, paiements et coordination d'équipe. Trois espaces : **Organisateur**, **Creator** (prestataires, agences) et **centre de contrôle** de l'équipe Calandix.

> Version de démonstration : données fictives locales, connexion simulée, paiements et agent IA simulés. Aucun backend n'est encore branché (Supabase prévu).

## Fonctionnalités

- **Organisateur** : accueil avec la mascotte, dashboard par événement, budget éditable avec répartition et export CSV, agenda Jour / Semaine / Mois, marketplace avec filtres et demande de devis, réservation en 7 étapes, coffre-fort et agent IA (Premium), collaborateurs avec droits, suggestions Premium contextuelles.
- **Creator – espace pro** (`/pro/...`) : profil et catalogue (forfaits, options, conditions de vente), disponibilités (dates bloquées, capacité, anti-double réservation), devis détaillés avec questions au client, suivi des commandes jusqu'à la clôture, revenus et reversements (relevés CSV), réputation et performance.
- **Centre de contrôle** (`/admin`) : vue d'ensemble temps réel et 10 modules (comptes, vérification des prestataires, catalogue, réservations et litiges, paiements, modèle économique, marketing, service client, analytics, rôles et sécurité avec journal d'audit).
- Mascotte animée (connexion, accueil, compte, agenda, chargements), mode sombre, français / anglais, effets sonores.
- Pages À propos et Politique de confidentialité (brouillon à valider par un juriste).
- Inscription et connexion pour les deux profils, photo de profil avec recadrage.
- Interface responsive : barre d'onglets sur mobile, rail latéral sur tablette et ordinateur.

## Tester sur mobile

Après `flutter build web --release`, servir `build/web` sur le réseau local (port 8080), puis scanner les QR codes générés à la racine du dossier projet (`eventa_qr_demo.html`).

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
