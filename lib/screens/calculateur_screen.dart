import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/calculs.dart';
import '../logic/format.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/dialogue_sauvegarde.dart';

class CalculateurScreen extends StatefulWidget {
  const CalculateurScreen({super.key});

  @override
  State<CalculateurScreen> createState() => _CalculateurScreenState();
}

class _CalculateurScreenState extends State<CalculateurScreen> {
  final _taille = TextEditingController();
  final _initial = TextEditingController();
  final _actuel = TextEditingController();
  final _objectif = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [_taille, _initial, _actuel, _objectif]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_taille, _initial, _actuel, _objectif]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reinitialiser() {
    for (final c in [_taille, _initial, _actuel, _objectif]) {
      c.clear();
    }
  }

  Future<void> _sauvegarder({
    required double poids,
    double? poidsInitial,
    double? objectif,
    double? taille,
  }) async {
    final patient = await afficherDialogueSauvegarde(
      context,
      poids: poids,
      poidsInitial: poidsInitial,
      objectif: objectif,
      taille: taille,
    );
    if (patient == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppCouleurs.mentheFonce,
        content: Text('Consultation enregistrée pour $patient'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taille = parseNombre(_taille.text);
    final initial = parseNombre(_initial.text);
    final actuel = parseNombre(_actuel.text);
    final objectif = parseNombre(_objectif.text);

    final formulaire = _CarteFormulaire(
      taille: _taille,
      initial: _initial,
      actuel: _actuel,
      objectif: _objectif,
      onReset: _reinitialiser,
      onSauvegarder: actuel != null && actuel > 0
          ? () => _sauvegarder(
              poids: actuel,
              poidsInitial: initial,
              objectif: objectif,
              taille: taille,
            )
          : null,
    );

    final resultats = <Widget>[
      if (initial != null && actuel != null && initial > 0)
        _CartePerte(initial: initial, actuel: actuel)
      else
        const CarteVide(
          icone: Icons.trending_down_rounded,
          texte:
              'Saisis ton poids initial et ton poids actuel '
              'pour voir ta progression.',
        ),
      if (initial != null && actuel != null && objectif != null)
        _CarteObjectif(initial: initial, actuel: actuel, objectif: objectif),
      if (actuel != null && taille != null && taille > 0)
        _CarteImc(valeur: imc(actuel, taille)),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondDegrade(
        child: LayoutBuilder(
          builder: (context, contraintes) {
            final large = contraintes.maxWidth >= 760;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const EnTeteEcran(
                        icone: Icons.monitor_weight_outlined,
                        titre: 'Ma Balance',
                        sousTitre:
                            'Calcule ta perte de poids en un clin d\'œil',
                      ),
                      const SizedBox(height: 24),
                      if (large)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: formulaire),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 6,
                              child: Column(children: _espacer(resultats)),
                            ),
                          ],
                        )
                      else ...[
                        formulaire,
                        const SizedBox(height: 16),
                        ..._espacer(resultats),
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

  List<Widget> _espacer(List<Widget> cartes) => [
    for (var i = 0; i < cartes.length; i++) ...[
      if (i > 0) const SizedBox(height: 16),
      cartes[i],
    ],
  ];
}

// ---------------------------------------------------------------------------
// Formulaire

class _CarteFormulaire extends StatelessWidget {
  const _CarteFormulaire({
    required this.taille,
    required this.initial,
    required this.actuel,
    required this.objectif,
    required this.onReset,
    required this.onSauvegarder,
  });

  final TextEditingController taille;
  final TextEditingController initial;
  final TextEditingController actuel;
  final TextEditingController objectif;
  final VoidCallback onReset;
  final VoidCallback? onSauvegarder;

  @override
  Widget build(BuildContext context) {
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: TitreCarte(
                  Icons.edit_note_rounded,
                  'Tes mesures',
                  AppCouleurs.lavande,
                ),
              ),
              IconButton(
                tooltip: 'Effacer',
                onPressed: onReset,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppCouleurs.gris,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Champ(taille, 'Taille', 'cm', Icons.height_rounded),
          const SizedBox(height: 12),
          _Champ(initial, 'Poids initial', 'kg', Icons.flag_outlined),
          const SizedBox(height: 12),
          _Champ(actuel, 'Poids actuel', 'kg', Icons.monitor_weight_outlined),
          const SizedBox(height: 12),
          _Champ(
            objectif,
            'Objectif (facultatif)',
            'kg',
            Icons.emoji_events_outlined,
          ),
          const SizedBox(height: 20),
          BoutonDegrade(
            icone: Icons.save_rounded,
            label: 'Sauvegarder',
            onPressed: onSauvegarder,
          ),
        ],
      ),
    );
  }
}

class _Champ extends StatelessWidget {
  const _Champ(this.controleur, this.label, this.unite, this.icone);

  final TextEditingController controleur;
  final String label;
  final String unite;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final invalide =
        controleur.text.trim().isNotEmpty &&
        parseNombre(controleur.text) == null;
    return TextField(
      controller: controleur,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icone, color: AppCouleurs.gris),
        suffixText: unite,
        errorText: invalide ? 'Nombre invalide' : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Résultat : perte de poids

class _CartePerte extends StatelessWidget {
  const _CartePerte({required this.initial, required this.actuel});

  final double initial;
  final double actuel;

  @override
  Widget build(BuildContext context) {
    final pct = pourcentagePerte(initial, actuel);
    final kg = initial - actuel;
    final perte = kg > 0;
    final couleur = perte ? AppCouleurs.mentheFonce : AppCouleurs.peche;

    final String message;
    if (kg.abs() < 0.05) {
      message = 'Poids stable, continue comme ça !';
    } else if (perte) {
      message = 'Bravo ! Tu as perdu ${formatKg(kg)}.';
    } else {
      message = 'Prise de ${formatKg(-kg)}. On garde le cap !';
    }

    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitreCarte(
            Icons.trending_down_rounded,
            'Perte de poids',
            AppCouleurs.menthe,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Anneau(
                fraction: (pct.abs() / 20).clamp(0, 1).toDouble(),
                couleurs: perte
                    ? const [AppCouleurs.menthe, AppCouleurs.lavande]
                    : const [AppCouleurs.soleil, AppCouleurs.peche],
                centre: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct >= 0 ? '' : '+'}${pct.abs().toStringAsFixed(1).replaceAll('.', ',')} %',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: couleur,
                      ),
                    ),
                    Text(
                      perte || kg.abs() < 0.05 ? 'perdus' : 'pris',
                      style: const TextStyle(color: AppCouleurs.gris),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Ligne('Départ', formatKg(initial)),
                    _Ligne('Aujourd\'hui', formatKg(actuel)),
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

// ---------------------------------------------------------------------------
// Résultat : objectif

class _CarteObjectif extends StatelessWidget {
  const _CarteObjectif({
    required this.initial,
    required this.actuel,
    required this.objectif,
  });

  final double initial;
  final double actuel;
  final double objectif;

  @override
  Widget build(BuildContext context) {
    final valide = objectif < initial;
    final progression = progressionObjectif(initial, actuel, objectif);
    final restant = actuel - objectif;

    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitreCarte(
            Icons.emoji_events_outlined,
            'Objectif',
            AppCouleurs.soleil,
          ),
          const SizedBox(height: 18),
          if (!valide)
            const Text(
              'L\'objectif doit être inférieur au poids initial.',
              style: TextStyle(color: AppCouleurs.gris),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${progression.toStringAsFixed(0)} %',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text(
                    'du chemin parcouru',
                    style: TextStyle(color: AppCouleurs.gris),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BarreProgression(fraction: progression / 100),
            const SizedBox(height: 12),
            Text(
              restant <= 0
                  ? 'Objectif atteint ! Félicitations.'
                  : 'Plus que ${formatKg(restant)} pour atteindre ${formatKg(objectif)}.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarreProgression extends StatelessWidget {
  const _BarreProgression({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 14,
        child: Stack(
          children: [
            Container(color: const Color(0xFFEEF1F7)),
            TweenAnimationBuilder<double>(
              tween: Tween(end: fraction.clamp(0, 1)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppCouleurs.soleil, AppCouleurs.peche],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Résultat : IMC

class _CarteImc extends StatelessWidget {
  const _CarteImc({required this.valeur});

  final double valeur;

  static const _min = 15.0;
  static const _max = 40.0;
  static const _zones = [
    (18.5, Color(0xFF6FB7FF)),
    (25.0, AppCouleurs.menthe),
    (30.0, AppCouleurs.soleil),
    (35.0, AppCouleurs.peche),
    (40.0, AppCouleurs.corail),
  ];

  Color _couleur(CategorieImc c) => switch (c) {
    CategorieImc.maigreur => const Color(0xFF4A9EF0),
    CategorieImc.normal => AppCouleurs.mentheFonce,
    CategorieImc.surpoids => const Color(0xFFE0A526),
    CategorieImc.obesiteModeree => AppCouleurs.peche,
    _ => AppCouleurs.corail,
  };

  @override
  Widget build(BuildContext context) {
    final categorie = categorieImc(valeur);
    final couleur = _couleur(categorie);
    final position = ((valeur - _min) / (_max - _min)).clamp(0.0, 1.0);

    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitreCarte(
            Icons.favorite_outline_rounded,
            'IMC',
            AppCouleurs.corail,
          ),
          const SizedBox(height: 18),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                formatNombre(valeur),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  categorie.libelle,
                  style: TextStyle(color: couleur, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) => SizedBox(
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          for (var i = 0; i < _zones.length; i++)
                            Expanded(
                              flex:
                                  ((_zones[i].$1 -
                                              (i == 0
                                                  ? _min
                                                  : _zones[i - 1].$1)) *
                                          10)
                                      .round(),
                              child: Container(
                                height: 10,
                                color: _zones[i].$2.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    left: position * c.maxWidth - 9,
                    top: 2,
                    child: Container(
                      width: 18,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: couleur, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '15',
                style: TextStyle(color: AppCouleurs.gris, fontSize: 12),
              ),
              Text(
                '25',
                style: TextStyle(color: AppCouleurs.gris, fontSize: 12),
              ),
              Text(
                '40',
                style: TextStyle(color: AppCouleurs.gris, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Éléments communs

class _Ligne extends StatelessWidget {
  const _Ligne(this.label, this.valeur);

  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('$label : ', style: const TextStyle(color: AppCouleurs.gris)),
          Text(valeur, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Anneau de progression animé avec dégradé.
class _Anneau extends StatelessWidget {
  const _Anneau({
    required this.fraction,
    required this.couleurs,
    required this.centre,
  });

  final double fraction;
  final List<Color> couleurs;
  final Widget centre;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fraction),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => CustomPaint(
        painter: _PeintreAnneau(v, couleurs),
        child: SizedBox(width: 130, height: 130, child: Center(child: centre)),
      ),
    );
  }
}

class _PeintreAnneau extends CustomPainter {
  _PeintreAnneau(this.fraction, this.couleurs);

  final double fraction;
  final List<Color> couleurs;

  @override
  void paint(Canvas canvas, Size size) {
    const epaisseur = 12.0;
    final rect = Offset.zero & size;
    final cercle = rect.deflate(epaisseur / 2);

    canvas.drawArc(
      cercle,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = epaisseur
        ..color = const Color(0xFFEEF1F7),
    );

    if (fraction <= 0) return;
    canvas.drawArc(
      cercle,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = epaisseur
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: couleurs,
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_PeintreAnneau old) =>
      old.fraction != fraction || old.couleurs != couleurs;
}
