import 'package:intl/intl.dart';

final _fcfa = NumberFormat.decimalPattern('fr_FR');

/// Espace insécable : un montant ne se coupe jamais en fin de ligne.
const _nbsp = '\u00a0';

/// 12 500 000 FCFA
String fcfa(num amount) =>
    '${_fcfa.format(amount).replaceAll('\u202f', _nbsp).replaceAll(' ', _nbsp)}${_nbsp}FCFA';

/// 12,5 M — pour les chiffres compacts des cartes.
String fcfaCompact(num amount) {
  if (amount >= 1000000) {
    final m = amount / 1000000;
    final s = m == m.roundToDouble()
        ? m.toStringAsFixed(0)
        : m.toStringAsFixed(1).replaceAll('.', ',');
    return '$s${_nbsp}M';
  }
  if (amount >= 1000) return '${(amount / 1000).round()}${_nbsp}k';
  return amount.toString();
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int daysUntil(DateTime date, {DateTime? from}) =>
    dateOnly(date).difference(dateOnly(from ?? DateTime.now())).inDays;

/// J-42, Jour J, J+3
String countdownLabel(DateTime date) {
  final d = daysUntil(date);
  if (d == 0) return 'Jour J';
  return d > 0 ? 'J-$d' : 'J+${-d}';
}

String longDate(DateTime d) => DateFormat('EEEE d MMMM y', 'fr_FR').format(d);
String mediumDate(DateTime d) => DateFormat('d MMM y', 'fr_FR').format(d);
String shortDate(DateTime d) => DateFormat('d MMM', 'fr_FR').format(d);
String weekdayShort(DateTime d) =>
    DateFormat('EEE', 'fr_FR').format(d).replaceAll('.', '');
String timeOf(DateTime d) => DateFormat('HH:mm', 'fr_FR').format(d);

String relativeDue(DateTime due) {
  final d = daysUntil(due);
  if (d < -1) return 'En retard de ${-d} j';
  if (d == -1) return 'Hier';
  if (d == 0) return "Aujourd'hui";
  if (d == 1) return 'Demain';
  if (d < 7) return 'Dans $d jours';
  return shortDate(due);
}

String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 5 || h >= 18) return 'Bonsoir';
  return 'Bonjour';
}
