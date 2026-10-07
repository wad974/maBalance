import 'package:intl/intl.dart';

/// "72,5 kg"
String formatKg(double v) => '${formatNombre(v)} kg';

/// Kg perdus affichés comme un écart : "−3,2 kg", "+1,0 kg" ou "0,0 kg".
String formatEcart(double kgPerdus) {
  if (kgPerdus.abs() < 0.05) return formatKg(0);
  return '${kgPerdus > 0 ? '−' : '+'}${formatKg(kgPerdus.abs())}';
}

/// Nombre à une décimale avec virgule.
String formatNombre(double v, [int decimales = 1]) =>
    v.toStringAsFixed(decimales).replaceAll('.', ',');

/// "07/10/2026"
String formatDate(DateTime d) => DateFormat('dd/MM/yyyy', 'fr_FR').format(d);

/// "07/10/2026 à 14:32"
String formatDateHeure(DateTime d) =>
    DateFormat("dd/MM/yyyy 'à' HH:mm", 'fr_FR').format(d);

/// "7 oct."
String formatDateCourte(DateTime d) => DateFormat('d MMM', 'fr_FR').format(d);
