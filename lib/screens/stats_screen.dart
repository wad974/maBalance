import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/base_donnees.dart';
import '../data/modeles.dart';
import '../logic/calculs.dart';
import '../logic/format.dart';
import '../logic/stats.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/recherche_patient.dart';

enum Periode {
  tout('Tout'),
  mois('30 jours'),
  trimestre('3 mois'),
  annee('1 an'),
  personnalisee('Dates…');

  const Periode(this.libelle);
  final String libelle;
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.patientId,
    required this.onPatientChange,
  });

  /// Patient sélectionné (géré par l'écran parent pour pouvoir y accéder
  /// depuis la fiche patient).
  final int? patientId;
  final ValueChanged<int?> onPatientChange;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  /// Patient affiché ; par défaut le dernier venu en consultation.
  Patient? _patient;
  List<Consultation> _consultations = const [];
  bool _charge = false;

  Periode _periode = Periode.tout;
  DateTimeRange? _plage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Appelé au démarrage et après chaque écriture dans la base.
    _charger(DonneesScope.of(context));
  }

  @override
  void didUpdateWidget(StatsScreen old) {
    super.didUpdateWidget(old);
    if (old.patientId != widget.patientId) {
      _charger(DonneesScope.lire(context));
    }
  }

  Future<void> _charger(BaseDonnees base) async {
    final id = widget.patientId;
    final patient =
        (id == null ? null : await base.patient(id)) ??
        await base.patientParDefaut();
    final consultations = patient == null
        ? <Consultation>[]
        : await base.consultations(patient.id!);
    if (!mounted) return;
    setState(() {
      _patient = patient;
      _consultations = consultations;
      _charge = true;
    });
  }

  (DateTime?, DateTime?) get _bornes {
    final maintenant = DateTime.now();
    return switch (_periode) {
      Periode.tout => (null, null),
      Periode.mois => (maintenant.subtract(const Duration(days: 30)), null),
      Periode.trimestre => (
        maintenant.subtract(const Duration(days: 91)),
        null,
      ),
      Periode.annee => (maintenant.subtract(const Duration(days: 365)), null),
      Periode.personnalisee => (
        _plage?.start,
        _plage == null
            ? null
            : DateTime(
                _plage!.end.year,
                _plage!.end.month,
                _plage!.end.day,
                23,
                59,
                59,
              ),
      ),
    };
  }

  Future<void> _choisirPeriode(Periode p) async {
    if (p != Periode.personnalisee) {
      setState(() => _periode = p);
      return;
    }
    final maintenant = DateTime.now();
    final premiere = _consultations.isEmpty
        ? maintenant
        : _consultations.first.date;
    final plage = await showDateRangePicker(
      context: context,
      locale: const Locale('fr', 'FR'),
      firstDate: DateTime(premiere.year - 1),
      lastDate: DateTime(maintenant.year + 1),
      initialDateRange:
          _plage ??
          DateTimeRange(
            start: DateTime(premiere.year, premiere.month, premiere.day),
            end: DateTime(maintenant.year, maintenant.month, maintenant.day),
          ),
    );
    if (plage == null) return;
    setState(() {
      _periode = Periode.personnalisee;
      _plage = plage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final (debut, fin) = _bornes;
    final stats = StatsPatient.calculer(_consultations, debut: debut, fin: fin);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondDegrade(
        child: LayoutBuilder(
          builder: (context, c) {
            final large = c.maxWidth >= 860;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const EnTeteEcran(
                        icone: Icons.insights_rounded,
                        titre: 'Statistiques',
                        sousTitre: 'Suis l\'évolution de chaque patient',
                      ),
                      const SizedBox(height: 24),
                      if (!_charge)
                        const Center(child: CircularProgressIndicator())
                      else if (_patient == null)
                        const CarteVide(
                          icone: Icons.person_add_alt_rounded,
                          texte:
                              'Aucun patient pour le moment. Fais un calcul '
                              'puis appuie sur « Sauvegarder ».',
                        )
                      else ...[
                        _barreFiltres(),
                        const SizedBox(height: 16),
                        if (stats == null)
                          const CarteVide(
                            icone: Icons.event_busy_rounded,
                            texte: 'Aucune consultation sur cette période.',
                          )
                        else
                          ..._contenu(stats, large),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _barreFiltres() {
    return Carte(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: ChampRecherchePatient(
              selection: _patient,
              onSelection: (p) => widget.onPatientChange(p.id),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final p in Periode.values)
                ChoiceChip(
                  label: Text(
                    p == Periode.personnalisee && _plage != null
                        ? '${formatDate(_plage!.start)} → ${formatDate(_plage!.end)}'
                        : p.libelle,
                  ),
                  avatar: p == Periode.personnalisee
                      ? const Icon(Icons.date_range_rounded, size: 18)
                      : null,
                  selected: _periode == p,
                  showCheckmark: false,
                  selectedColor: AppCouleurs.menthe.withValues(alpha: 0.2),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (_) => _choisirPeriode(p),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _contenu(StatsPatient s, bool large) {
    final categorie = categorieImc(s.imcActuel);
    final tuiles = [
      _Tuile(
        'Poids actuel',
        formatKg(s.poidsActuel),
        'au ${formatDate(s.derniere.date)}',
        Icons.monitor_weight_outlined,
      ),
      _Tuile(
        'Depuis le départ',
        formatEcart(s.perteTotaleKg),
        '${formatNombre(s.perteTotalePct.abs())} % '
            '${s.perteTotaleKg >= 0 ? 'perdus' : 'pris'} '
            '(départ ${formatKg(s.poidsDepart)})',
        Icons.trending_down_rounded,
      ),
      _Tuile(
        'Sur la période',
        formatEcart(s.pertePeriodeKg),
        'min ${formatKg(s.poidsMin)} · max ${formatKg(s.poidsMax)}',
        Icons.date_range_rounded,
      ),
      _Tuile(
        'IMC',
        formatNombre(s.imcActuel),
        categorie.libelle,
        Icons.favorite_outline_rounded,
      ),
      _Tuile(
        'Consultations',
        '${s.periode.length}',
        'moyenne ${formatKg(s.poidsMoyen)}',
        Icons.event_note_rounded,
      ),
    ];

    final courbe = _GraphCourbe(stats: s);
    final barres = _GraphVariations(stats: s);
    final camObjectif = _CamembertObjectif(stats: s);
    final camBilan = _CamembertBilan(stats: s);

    return [
      LayoutBuilder(
        builder: (context, c) {
          final colonnes = c.maxWidth >= 900 ? 5 : (c.maxWidth >= 560 ? 3 : 2);
          final largeur = (c.maxWidth - (colonnes - 1) * 12) / colonnes;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final t in tuiles) SizedBox(width: largeur, child: t),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      courbe,
      const SizedBox(height: 16),
      if (large) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: barres),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                children: [camObjectif, const SizedBox(height: 16), camBilan],
              ),
            ),
          ],
        ),
      ] else ...[
        barres,
        const SizedBox(height: 16),
        camObjectif,
        const SizedBox(height: 16),
        camBilan,
      ],
      const SizedBox(height: 16),
      _TableauHistorique(stats: s),
    ];
  }
}

// ---------------------------------------------------------------------------
// Tuiles de chiffres clés

class _Tuile extends StatelessWidget {
  const _Tuile(this.titre, this.valeur, this.detail, this.icone);

  final String titre;
  final String valeur;
  final String detail;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Carte(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 16, color: AppCouleurs.gris),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titre,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppCouleurs.gris, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valeur,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppCouleurs.gris, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Courbe d'évolution du poids

const _styleAxe = TextStyle(color: AppCouleurs.gris, fontSize: 11);

LineTouchTooltipData _infobulleLigne(List<String> Function(int) textes) =>
    LineTouchTooltipData(
      getTooltipColor: (_) => AppCouleurs.encre,
      tooltipBorderRadius: BorderRadius.circular(10),
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipItems: (spots) => [
        for (final s in spots)
          if (s.barIndex == 0)
            LineTooltipItem(
              '${textes(s.spotIndex)[0]}\n',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              children: [
                TextSpan(
                  text: textes(s.spotIndex)[1],
                  style: const TextStyle(
                    color: Color(0xFFB9C2D6),
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else
            null,
      ],
    );

class _GraphCourbe extends StatelessWidget {
  const _GraphCourbe({required this.stats});

  final StatsPatient stats;

  @override
  Widget build(BuildContext context) {
    final points = stats.periode;
    final t0 = points.first.date;
    double x(DateTime d) => d.difference(t0).inMinutes / 1440;

    final spots = [for (final c in points) FlSpot(x(c.date), c.poids)];
    final objectif = stats.objectif;

    final valeurs = [...points.map((c) => c.poids), ?objectif];
    final bas = valeurs.reduce(math.min);
    final haut = valeurs.reduce(math.max);
    final marge = math.max(1.0, (haut - bas) * 0.15);
    final minY = (bas - marge).floorToDouble();
    final maxY = (haut + marge).ceilToDouble();
    final pasY = _pasAxe(maxY - minY);

    final maxX = math.max(1.0, spots.last.x);
    final pasX = math.max(1.0, maxX / 4);

    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitreCarte(
            Icons.show_chart_rounded,
            'Évolution du poids (kg)',
            CouleursGraph.ligne,
          ),
          const SizedBox(height: 20),
          if (points.length < 2)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Il faut au moins deux consultations sur la période '
                'pour tracer la courbe.',
                style: TextStyle(color: AppCouleurs.gris),
              ),
            )
          else
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: pasY,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: CouleursGraph.grille,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: pasY,
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(formatNombre(v, 0), style: _styleAxe),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: pasX,
                        maxIncluded: false,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            formatDateCourte(
                              t0.add(Duration(minutes: (v * 1440).round())),
                            ),
                            style: _styleAxe,
                          ),
                        ),
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (objectif != null)
                        HorizontalLine(
                          y: objectif,
                          color: AppCouleurs.gris,
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: const TextStyle(
                              color: AppCouleurs.gris,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            labelResolver: (_) =>
                                'Objectif ${formatKg(objectif)}',
                          ),
                        ),
                    ],
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: _infobulleLigne(
                      (i) => [
                        formatKg(points[i].poids),
                        formatDateHeure(points[i].date),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      preventCurveOverShooting: true,
                      color: CouleursGraph.ligne,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                          radius: 4.5,
                          color: CouleursGraph.ligne,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            CouleursGraph.ligne.withValues(alpha: 0.18),
                            CouleursGraph.ligne.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pas « rond » pour environ 4 à 6 graduations.
double _pasAxe(double etendue) {
  for (final pas in [0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0]) {
    if (etendue / pas <= 6) return pas;
  }
  return 100;
}

/// Plus petite valeur « ronde » supérieure ou égale à [v].
double _arrondiHaut(double v) {
  for (final b in [0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 15.0, 20.0]) {
    if (v <= b) return b;
  }
  return (v / 10).ceil() * 10;
}

// ---------------------------------------------------------------------------
// Diagramme en barres des variations

class _GraphVariations extends StatelessWidget {
  const _GraphVariations({required this.stats});

  final StatsPatient stats;

  static const _max = 24;

  Color _couleur(double d) => d <= -seuilStable
      ? CouleursGraph.perte
      : (d >= seuilStable ? CouleursGraph.prise : CouleursGraph.stable);

  @override
  Widget build(BuildContext context) {
    final toutes = stats.variations;
    final vars = toutes.length > _max
        ? toutes.sublist(toutes.length - _max)
        : toutes;
    final amplitude = vars.isEmpty
        ? 1.0
        : vars.map((v) => v.delta.abs()).reduce(math.max);
    final borne = _arrondiHaut(amplitude * 1.15);

    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitreCarte(
            Icons.bar_chart_rounded,
            'Variation entre consultations (kg)',
            AppCouleurs.lavande,
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Legende(CouleursGraph.perte, 'Perte'),
              _Legende(CouleursGraph.stable, 'Stable'),
              _Legende(CouleursGraph.prise, 'Prise'),
            ],
          ),
          const SizedBox(height: 18),
          if (vars.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Pas encore de variation : il faut au moins deux consultations.',
                style: TextStyle(color: AppCouleurs.gris),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  minY: -borne,
                  maxY: borne,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: borne / 2,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: v == 0 ? AppCouleurs.gris : CouleursGraph.grille,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: borne / 2,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${v > 0 ? '+' : ''}${formatNombre(v)}',
                            style: _styleAxe,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          // Une étiquette sur deux si beaucoup de barres.
                          if (vars.length > 8 && i.isOdd) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              formatDateCourte(vars[i].consultation.date),
                              style: _styleAxe,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppCouleurs.encre,
                      tooltipBorderRadius: BorderRadius.circular(10),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, _, _, _) {
                        final v = vars[group.x];
                        return BarTooltipItem(
                          '${v.delta > 0 ? '+' : ''}${formatKg(v.delta)}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(
                              text: formatDateHeure(v.consultation.date),
                              style: const TextStyle(
                                color: Color(0xFFB9C2D6),
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < vars.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            fromY: 0,
                            // Une variation nulle reste visible.
                            toY: vars[i].delta.abs() < 0.02
                                ? borne * 0.02
                                : vars[i].delta,
                            color: _couleur(vars[i].delta),
                            width: vars.length > 12 ? 10 : 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          if (toutes.length > _max)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$_max dernières variations affichées',
                style: const TextStyle(color: AppCouleurs.gris, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Camemberts

class _Legende extends StatelessWidget {
  const _Legende(this.couleur, this.texte, {this.valeur});

  final Color couleur;
  final String texte;
  final String? valeur;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texte,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (valeur != null) ...[
          const SizedBox(width: 6),
          Text(
            valeur!,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

class _Camembert extends StatelessWidget {
  const _Camembert({
    required this.icone,
    required this.titre,
    required this.couleurTitre,
    required this.parts,
    required this.centre,
    required this.legende,
  });

  final IconData icone;
  final String titre;
  final Color couleurTitre;
  final List<(double, Color)> parts;
  final String centre;
  final List<Widget> legende;

  @override
  Widget build(BuildContext context) {
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitreCarte(icone, titre, couleurTitre),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        sectionsSpace: 2,
                        centerSpaceRadius: 42,
                        pieTouchData: PieTouchData(enabled: false),
                        sections: [
                          for (final (valeur, couleur) in parts)
                            if (valeur > 0)
                              PieChartSectionData(
                                value: valeur,
                                color: couleur,
                                radius: 20,
                                showTitle: false,
                              ),
                        ],
                      ),
                    ),
                    Text(
                      centre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final l in legende)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: l,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CamembertObjectif extends StatelessWidget {
  const _CamembertObjectif({required this.stats});

  final StatsPatient stats;

  @override
  Widget build(BuildContext context) {
    final objectif = stats.objectif;
    final progression = stats.progression;
    if (objectif == null ||
        progression == null ||
        objectif >= stats.poidsDepart) {
      return const CarteVide(
        icone: Icons.emoji_events_outlined,
        texte:
            'Aucun objectif défini. Renseigne un objectif dans le '
            'calculateur avant de sauvegarder.',
      );
    }
    final restant = math.max(0.0, stats.poidsActuel - objectif);
    return _Camembert(
      icone: Icons.emoji_events_outlined,
      titre: 'Objectif ${formatKg(objectif)}',
      couleurTitre: AppCouleurs.soleil,
      centre: '${progression.round()} %',
      parts: [
        (progression, CouleursGraph.perte),
        (100 - progression, CouleursGraph.piste),
      ],
      legende: [
        _Legende(
          CouleursGraph.perte,
          'Parcouru',
          valeur: formatKg(math.max(0.0, stats.perteTotaleKg)),
        ),
        _Legende(CouleursGraph.piste, 'Restant', valeur: formatKg(restant)),
      ],
    );
  }
}

class _CamembertBilan extends StatelessWidget {
  const _CamembertBilan({required this.stats});

  final StatsPatient stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.variations.length;
    if (total == 0) {
      return const CarteVide(
        icone: Icons.pie_chart_outline_rounded,
        texte: 'Le bilan apparaîtra dès la deuxième consultation.',
      );
    }
    return _Camembert(
      icone: Icons.pie_chart_outline_rounded,
      titre: 'Bilan des consultations',
      couleurTitre: AppCouleurs.mentheFonce,
      centre: '$total',
      parts: [
        (stats.nbPertes.toDouble(), CouleursGraph.perte),
        (stats.nbStables.toDouble(), CouleursGraph.stable),
        (stats.nbPrises.toDouble(), CouleursGraph.prise),
      ],
      legende: [
        _Legende(CouleursGraph.perte, 'En perte', valeur: '${stats.nbPertes}'),
        _Legende(CouleursGraph.stable, 'Stables', valeur: '${stats.nbStables}'),
        _Legende(CouleursGraph.prise, 'En prise', valeur: '${stats.nbPrises}'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tableau des consultations de la période

class _TableauHistorique extends StatelessWidget {
  const _TableauHistorique({required this.stats});

  final StatsPatient stats;

  @override
  Widget build(BuildContext context) {
    final deltas = {
      for (final v in stats.variations) v.consultation.id: v.delta,
    };
    const entete = TextStyle(
      color: AppCouleurs.gris,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitreCarte(
            Icons.table_rows_rounded,
            'Détail de la période',
            AppCouleurs.peche,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 40,
              horizontalMargin: 4,
              columnSpacing: 32,
              columns: const [
                DataColumn(label: Text('Date', style: entete)),
                DataColumn(label: Text('Poids', style: entete), numeric: true),
                DataColumn(
                  label: Text('Variation', style: entete),
                  numeric: true,
                ),
                DataColumn(label: Text('IMC', style: entete), numeric: true),
              ],
              rows: [
                for (final c in stats.periode.reversed)
                  DataRow(
                    cells: [
                      DataCell(Text(formatDateHeure(c.date))),
                      DataCell(
                        Text(
                          formatKg(c.poids),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          deltas[c.id] == null
                              ? '—'
                              : '${deltas[c.id]! > 0 ? '+' : ''}${formatKg(deltas[c.id]!)}',
                        ),
                      ),
                      DataCell(Text(formatNombre(imc(c.poids, c.taille)))),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
