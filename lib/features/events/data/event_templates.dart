import 'package:flutter/widgets.dart';

import '../../../ui/theme/app_icons.dart';
import '../../../core/models/models.dart';
import 'demo_data.dart';

/// Modèles par famille : répartition du budget et checklist pré-remplie,
/// planifiée à rebours depuis la date (rétrocalendrier).
abstract final class EventTemplates {
  static const _covers = {
    EventCategory.wedding: 'assets/images/cover_wedding.jpg',
    EventCategory.birthday: 'assets/images/cover_birthday.jpg',
    EventCategory.baby: 'assets/images/cover_babyshower.jpg',
    EventCategory.friends: 'assets/images/v/venue_3.jpg',
    EventCategory.outing: 'assets/images/v/activity_1.jpg',
    EventCategory.pro: 'assets/images/v/planner_1.jpg',
    EventCategory.milestone: 'assets/images/onboarding_confetti.jpg',
    EventCategory.family: 'assets/images/v/food_3.jpg',
    EventCategory.charity: 'assets/images/v/venue_2.jpg',
    EventCategory.seasonal: 'assets/images/shop/candles.jpg',
  };

  static String cover(EventCategory c) => _covers[c]!;

  static Map<BudgetCategory, double> split(EventCategory c) => switch (c) {
    EventCategory.wedding => {
      BudgetCategory.venue: .24,
      BudgetCategory.catering: .29,
      BudgetCategory.decor: .1,
      BudgetCategory.photo: .07,
      BudgetCategory.music: .04,
      BudgetCategory.outfits: .07,
      BudgetCategory.drinks: .07,
      BudgetCategory.invitations: .02,
      BudgetCategory.transport: .02,
      BudgetCategory.contingency: .08,
    },
    EventCategory.birthday || EventCategory.friends => {
      BudgetCategory.venue: .3,
      BudgetCategory.catering: .25,
      BudgetCategory.drinks: .14,
      BudgetCategory.music: .1,
      BudgetCategory.cake: .06,
      BudgetCategory.decor: .1,
      BudgetCategory.contingency: .05,
    },
    EventCategory.outing => {
      BudgetCategory.activities: .35,
      BudgetCategory.catering: .3,
      BudgetCategory.transport: .2,
      BudgetCategory.rental: .1,
      BudgetCategory.contingency: .05,
    },
    EventCategory.pro => {
      BudgetCategory.venue: .3,
      BudgetCategory.catering: .3,
      BudgetCategory.rental: .12,
      BudgetCategory.staff: .08,
      BudgetCategory.photo: .06,
      BudgetCategory.transport: .06,
      BudgetCategory.contingency: .08,
    },
    _ => {
      BudgetCategory.venue: .25,
      BudgetCategory.catering: .35,
      BudgetCategory.decor: .15,
      BudgetCategory.photo: .1,
      BudgetCategory.gifts: .1,
      BudgetCategory.contingency: .05,
    },
  };

  /// (titre, jours avant l'événement, module, icône)
  static List<(String, int, Module, IconData)> checklist(EventCategory c) =>
      switch (c) {
        EventCategory.wedding => const [
          (
            'Fixer la date avec les deux familles',
            180,
            Module.team,
            AppIcons.calendarCheck,
          ),
          ('Définir le budget cible', 170, Module.budget, AppIcons.wallet),
          ('Visiter et réserver la salle', 150, Module.vendors, AppIcons.venue),
          (
            'Liste des invités par famille',
            140,
            Module.guests,
            AppIcons.guests,
          ),
          ('Choisir le traiteur', 120, Module.vendors, AppIcons.food),
          ('Préparer le déroulé de la dot', 100, Module.tasks, AppIcons.gift),
          (
            'Dossier de mairie et publication des bans',
            60,
            Module.tasks,
            AppIcons.buildings,
          ),
          ('Commander le pagne du cortège', 50, Module.tasks, AppIcons.dress),
          ('Envoyer les invitations', 45, Module.guests, AppIcons.mail),
          ('Réserver photographe et DJ', 40, Module.vendors, AppIcons.camera),
          ('Relancer les RSVP', 21, Module.guests, AppIcons.reminder),
          ('Plan de table', 14, Module.guests, AppIcons.table),
          ('Payer les soldes prestataires', 7, Module.budget, AppIcons.coins),
          ('Déroulé du jour J partagé', 3, Module.team, AppIcons.clock),
        ],
        EventCategory.birthday => const [
          (
            'Choisir le thème et le code vestimentaire',
            40,
            Module.tasks,
            AppIcons.palette,
          ),
          ('Réserver le lieu', 35, Module.vendors, AppIcons.venue),
          ('Créer le groupe secret', 30, Module.team, AppIcons.eyeOff),
          ('Envoyer les invitations', 25, Module.guests, AppIcons.mail),
          ('Commander le gâteau', 14, Module.vendors, AppIcons.birthday),
          ('Playlist collaborative', 10, Module.team, AppIcons.music),
          ('Plan de diversion', 3, Module.team, AppIcons.eyeOff),
          ('Courses boissons', 2, Module.budget, AppIcons.drinks),
        ],
        _ => const [
          ('Choisir la date et le lieu', 30, Module.vendors, AppIcons.venue),
          ('Définir le budget', 28, Module.budget, AppIcons.wallet),
          ('Lister les invités', 25, Module.guests, AppIcons.guests),
          ('Inviter les co-organisateurs', 24, Module.team, AppIcons.userPlus),
          ('Envoyer les invitations', 20, Module.guests, AppIcons.mail),
          ('Réserver les prestataires', 15, Module.vendors, AppIcons.vendors),
          ('Relancer les RSVP', 7, Module.guests, AppIcons.reminder),
          ('Préparer le déroulé', 2, Module.team, AppIcons.clock),
        ],
      };

  /// Budget « IA » : répartition de référence ajustée au nombre d'invités,
  /// en conservant ce qui est déjà engagé.
  static List<BudgetLine> aiBudget(Event e) {
    final ref = split(e.category);
    final perGuest = e.guests.invited == 0
        ? 0
        : e.targetBudget / e.guests.invited;
    // Plus le budget par invité est serré, plus on protège la restauration.
    final cateringBoost = perGuest < 40000 ? 0.04 : 0.0;
    final lines = <BudgetLine>[];
    for (final entry in ref.entries) {
      var share = entry.value;
      if (entry.key == BudgetCategory.catering) share += cateringBoost;
      if (entry.key == BudgetCategory.decor) share -= cateringBoost;
      final existing = e.line(entry.key);
      final estimated = (e.targetBudget * share / 5000).round() * 5000;
      lines.add(
        BudgetLine(
          category: entry.key,
          estimated: existing == null
              ? estimated
              : (estimated < existing.committed
                    ? existing.committed
                    : estimated),
          committed: existing?.committed ?? 0,
          paid: existing?.paid ?? 0,
          note: 'Proposé par l’IA',
        ),
      );
    }
    // Les postes engagés hors modèle sont conservés.
    for (final l in e.budget) {
      if (!ref.containsKey(l.category)) lines.add(l);
    }
    return lines;
  }

  static Event create({
    required EventCategory category,
    required List<String> subcategories,
    required String name,
    required DateTime date,
    required String city,
    required int guests,
    required int budget,
  }) {
    final id = '${category.name}-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final items = checklist(category);
    return Event(
      id: id,
      name: name,
      subtitle: subcategories.isEmpty
          ? category.short
          : subcategories.join(' · '),
      category: category,
      subcategories: subcategories,
      date: date,
      venue: 'Lieu à choisir',
      city: city,
      cover: cover(category),
      targetBudget: budget,
      budget: [
        for (final s in split(category).entries)
          BudgetLine(
            category: s.key,
            estimated: (budget * s.value / 5000).round() * 5000,
          ),
      ],
      tasks: [
        for (var i = 0; i < items.length; i++)
          () {
            var due = DateTime(
              date.year,
              date.month,
              date.day - items[i].$2,
              10,
            );
            // Échéance déjà passée : on la ramène à partir de demain.
            if (due.isBefore(now)) {
              due = DateTime(
                now.year,
                now.month,
                now.day + 1 + i ~/ 3,
                9 + (i % 3) * 3,
              );
            }
            return EventTask(
              id: '$id-t$i',
              title: items[i].$1,
              due: due,
              module: items[i].$3,
              icon: items[i].$4,
              assigneeId: 'awa',
              urgent: i == 0,
            );
          }(),
      ],
      vendors: const [],
      team: const [DemoData.currentUser],
      activity: [
        Activity(
          memberId: 'awa',
          text: 'a créé l’événement',
          at: now,
          module: Module.team,
        ),
      ],
      guests: Guests.fromList(const [], expected: guests),
    );
  }
}
