import '../data/modeles.dart';
import 'calculs.dart';

/// Écart (kg) en dessous duquel deux pesées sont considérées identiques.
const seuilStable = 0.1;

class Variation {
  const Variation(this.consultation, this.delta);

  final Consultation consultation;

  /// Poids actuel − poids de la consultation précédente (négatif = perte).
  final double delta;
}

/// Statistiques d'un patient sur une période.
class StatsPatient {
  StatsPatient._({
    required this.periode,
    required this.poidsDepart,
    required this.variations,
    required this.objectif,
  });

  /// [toutes] : toutes les consultations du patient (date croissante).
  /// La période est [debut, fin] (null = sans borne).
  /// Retourne null si aucune consultation dans la période.
  static StatsPatient? calculer(
    List<Consultation> toutes, {
    DateTime? debut,
    DateTime? fin,
  }) {
    if (toutes.isEmpty) return null;
    bool dansPeriode(Consultation c) =>
        (debut == null || !c.date.isBefore(debut)) &&
        (fin == null || !c.date.isAfter(fin));

    final periode = toutes.where(dansPeriode).toList();
    if (periode.isEmpty) return null;

    final premiere = toutes.first;
    final variations = <Variation>[];
    for (var i = 1; i < toutes.length; i++) {
      if (dansPeriode(toutes[i])) {
        variations.add(
          Variation(toutes[i], toutes[i].poids - toutes[i - 1].poids),
        );
      }
    }

    // Dernier objectif saisi jusqu'à la fin de la période.
    double? objectif;
    for (final c in toutes) {
      if (fin != null && c.date.isAfter(fin)) break;
      if (c.objectif != null) objectif = c.objectif;
    }

    return StatsPatient._(
      periode: periode,
      poidsDepart: premiere.poidsInitial ?? premiere.poids,
      variations: variations,
      objectif: objectif,
    );
  }

  final List<Consultation> periode;

  /// Poids de départ du suivi (poids initial de la 1re consultation).
  final double poidsDepart;
  final List<Variation> variations;
  final double? objectif;

  Consultation get derniere => periode.last;
  double get poidsActuel => derniere.poids;

  double get perteTotaleKg => poidsDepart - poidsActuel;
  double get perteTotalePct => pourcentagePerte(poidsDepart, poidsActuel);

  double get pertePeriodeKg => periode.first.poids - poidsActuel;

  double get imcActuel => imc(derniere.poids, derniere.taille);

  double get poidsMin =>
      periode.map((c) => c.poids).reduce((a, b) => a < b ? a : b);
  double get poidsMax =>
      periode.map((c) => c.poids).reduce((a, b) => a > b ? a : b);
  double get poidsMoyen =>
      periode.map((c) => c.poids).reduce((a, b) => a + b) / periode.length;

  int get nbPertes => variations.where((v) => v.delta <= -seuilStable).length;
  int get nbPrises => variations.where((v) => v.delta >= seuilStable).length;
  int get nbStables => variations.length - nbPertes - nbPrises;

  double? get progression => objectif == null
      ? null
      : progressionObjectif(poidsDepart, poidsActuel, objectif!);
}
