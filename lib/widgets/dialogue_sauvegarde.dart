import 'package:flutter/material.dart';

import '../data/base_donnees.dart';
import '../data/modeles.dart';
import '../logic/calculs.dart';
import '../logic/format.dart';
import '../theme.dart';
import 'communs.dart';

/// Ouvre le popup d'enregistrement d'une consultation.
/// Retourne le nom complet du patient si l'enregistrement a réussi.
Future<String?> afficherDialogueSauvegarde(
  BuildContext context, {
  required double poids,
  double? poidsInitial,
  double? objectif,
  double? taille,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DialogueSauvegarde(
      poids: poids,
      poidsInitial: poidsInitial,
      objectif: objectif,
      taille: taille,
    ),
  );
}

class _DialogueSauvegarde extends StatefulWidget {
  const _DialogueSauvegarde({
    required this.poids,
    this.poidsInitial,
    this.objectif,
    this.taille,
  });

  final double poids;
  final double? poidsInitial;
  final double? objectif;
  final double? taille;

  @override
  State<_DialogueSauvegarde> createState() => _DialogueSauvegardeState();
}

class _DialogueSauvegardeState extends State<_DialogueSauvegarde> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _age = TextEditingController();
  late final _taille = TextEditingController(
    text: widget.taille == null ? '' : formatNombre(widget.taille!, 0),
  );

  late Future<List<Patient>> _patients;
  bool _enCours = false;
  String? _erreur;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _patients = DonneesScope.lire(context).patients();
  }

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _age, _taille]) {
      c.dispose();
    }
    super.dispose();
  }

  void _choisirPatient(Patient? p) {
    if (p == null) return;
    setState(() {
      _nom.text = p.nom;
      _prenom.text = p.prenom;
      _age.text = '${p.age}';
      if (_taille.text.trim().isEmpty) {
        _taille.text = formatNombre(p.taille, 0);
      }
    });
  }

  Future<void> _valider() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await DonneesScope.lire(context).enregistrerConsultation(
        nom: _nom.text,
        prenom: _prenom.text,
        age: int.parse(_age.text.trim()),
        taille: parseNombre(_taille.text)!,
        poids: widget.poids,
        poidsInitial: widget.poidsInitial,
        objectif: widget.objectif,
        date: DateTime.now(),
      );
      if (mounted) {
        Navigator.of(context).pop('${_prenom.text.trim()} ${_nom.text.trim()}');
      }
    } catch (e) {
      setState(() {
        _enCours = false;
        _erreur = 'Échec de l\'enregistrement : $e';
      });
    }
  }

  String? _requis(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TitreCarte(
                  Icons.save_rounded,
                  'Enregistrer la consultation',
                  AppCouleurs.lavande,
                ),
                const SizedBox(height: 16),
                _Recap(
                  poids: widget.poids,
                  poidsInitial: widget.poidsInitial,
                  objectif: widget.objectif,
                ),
                const SizedBox(height: 18),
                FutureBuilder<List<Patient>>(
                  future: _patients,
                  builder: (context, snap) {
                    final liste = snap.data ?? const <Patient>[];
                    if (liste.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<Patient>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Patient existant (facultatif)',
                          prefixIcon: Icon(
                            Icons.person_search_rounded,
                            color: AppCouleurs.gris,
                          ),
                        ),
                        items: [
                          for (final p in liste)
                            DropdownMenuItem(
                              value: p,
                              child: Text(p.nomComplet),
                            ),
                        ],
                        onChanged: _choisirPatient,
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prenom,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Prénom'),
                        validator: _requis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nom,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nom'),
                        validator: _requis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Âge',
                          suffixText: 'ans',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0 || n > 130) {
                            return 'Âge invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _taille,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Taille',
                          suffixText: 'cm',
                        ),
                        validator: (v) {
                          final n = parseNombre(v ?? '');
                          if (n == null || n < 50 || n > 260) {
                            return 'Taille invalide';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _valider(),
                      ),
                    ),
                  ],
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erreur!,
                    style: const TextStyle(color: AppCouleurs.corail),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _enCours
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),

                    BoutonDegrade(
                      icone: Icons.check_rounded,
                      label: _enCours ? 'Enregistrement…' : 'Sauvegarder',
                      onPressed: _enCours ? null : _valider,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Recap extends StatelessWidget {
  const _Recap({required this.poids, this.poidsInitial, this.objectif});

  final double poids;
  final double? poidsInitial;
  final double? objectif;

  @override
  Widget build(BuildContext context) {
    Widget puce(IconData i, String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppCouleurs.fond,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 16, color: AppCouleurs.gris),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        puce(Icons.event_rounded, formatDateHeure(DateTime.now())),
        puce(Icons.monitor_weight_outlined, formatKg(poids)),
        if (poidsInitial != null)
          puce(Icons.flag_outlined, 'Départ ${formatKg(poidsInitial!)}'),
        if (objectif != null)
          puce(Icons.emoji_events_outlined, 'Objectif ${formatKg(objectif!)}'),
      ],
    );
  }
}
