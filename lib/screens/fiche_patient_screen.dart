import 'package:flutter/material.dart';

import '../data/base_donnees.dart';
import '../data/modeles.dart';
import '../logic/calculs.dart';
import '../logic/format.dart';
import '../logic/stats.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import 'patients_screen.dart';

/// Fiche détaillée d'un patient : informations et historique.
class FichePatientScreen extends StatefulWidget {
  const FichePatientScreen({
    super.key,
    required this.patientId,
    required this.onVoirStats,
  });

  final int patientId;
  final ValueChanged<int> onVoirStats;

  @override
  State<FichePatientScreen> createState() => _FichePatientScreenState();
}

class _FichePatientScreenState extends State<FichePatientScreen> {
  Patient? _patient;
  List<Consultation> _consultations = const [];
  bool _charge = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _charger(DonneesScope.of(context));
  }

  Future<void> _charger(BaseDonnees base) async {
    final p = await base.patient(widget.patientId);
    final c = p == null
        ? <Consultation>[]
        : await base.consultations(widget.patientId);
    if (!mounted) return;
    setState(() {
      _patient = p;
      _consultations = c;
      _charge = true;
    });
  }

  Future<void> _modifier() async {
    final modifie = await showDialog<Patient>(
      context: context,
      builder: (_) => _DialogueModification(patient: _patient!),
    );
    if (modifie != null && mounted) {
      await DonneesScope.lire(context).modifierPatient(modifie);
    }
  }

  Future<void> _supprimer() async {
    final p = _patient!;
    final ok = await confirmer(
      context,
      titre: 'Supprimer ${p.nomComplet} ?',
      message:
          'Le patient et ses ${_consultations.length} consultation(s) '
          'seront définitivement supprimés.',
    );
    if (!ok || !mounted) return;
    final base = DonneesScope.lire(context);
    Navigator.of(context).pop();
    await base.supprimerPatient(p.id!);
  }

  Future<void> _supprimerConsultation(Consultation c) async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer cette consultation ?',
      message: 'Pesée de ${formatKg(c.poids)} du ${formatDateHeure(c.date)}.',
    );
    if (ok && mounted) {
      await DonneesScope.lire(context).supprimerConsultation(c.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _patient;
    return Scaffold(
      backgroundColor: AppCouleurs.fond,
      body: FondDegrade(
        child: !_charge
            ? const Center(child: CircularProgressIndicator())
            : p == null
            ? const Center(child: Text('Patient introuvable'))
            : _contenu(p),
      ),
    );
  }

  Widget _contenu(Patient p) {
    final stats = StatsPatient.calculer(_consultations);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Retour',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Modifier',
                    onPressed: _modifier,
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: AppCouleurs.gris,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Supprimer le patient',
                    onPressed: _supprimer,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppCouleurs.corail,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Carte(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AvatarInitiales(p.initiales, taille: 64),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nomComplet,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${p.age} ans · ${formatNombre(p.taille, 0)} cm',
                                style: const TextStyle(color: AppCouleurs.gris),
                              ),
                              Text(
                                'Suivi depuis le ${formatDate(p.creeLe)}',
                                style: const TextStyle(
                                  color: AppCouleurs.gris,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    BoutonDegrade(
                      icone: Icons.insights_rounded,
                      label: 'Voir les statistiques',
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onVoirStats(p.id!);
                      },
                    ),
                  ],
                ),
              ),
              if (stats != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Info('Départ', formatKg(stats.poidsDepart)),
                    _Info('Actuel', formatKg(stats.poidsActuel)),
                    _Info('Perte', '${formatNombre(stats.perteTotalePct)} %'),
                    _Info(
                      'IMC',
                      '${formatNombre(stats.imcActuel)} · '
                          '${categorieImc(stats.imcActuel).libelle}',
                    ),
                    if (stats.objectif != null)
                      _Info('Objectif', formatKg(stats.objectif!)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Carte(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitreCarte(
                      Icons.history_rounded,
                      'Historique des consultations (${_consultations.length})',
                      AppCouleurs.lavande,
                    ),
                    const SizedBox(height: 8),
                    if (_consultations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Aucune consultation.',
                          style: TextStyle(color: AppCouleurs.gris),
                        ),
                      ),
                    for (var i = _consultations.length - 1; i >= 0; i--)
                      _LigneConsultation(
                        consultation: _consultations[i],
                        precedente: i > 0 ? _consultations[i - 1] : null,
                        onSupprimer: () =>
                            _supprimerConsultation(_consultations[i]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.valeur);

  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppCouleurs.gris, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            valeur,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _LigneConsultation extends StatelessWidget {
  const _LigneConsultation({
    required this.consultation,
    required this.precedente,
    required this.onSupprimer,
  });

  final Consultation consultation;
  final Consultation? precedente;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    final details = [
      'IMC ${formatNombre(imc(c.poids, c.taille))}',
      if (c.poidsInitial != null) 'départ ${formatKg(c.poidsInitial!)}',
      if (c.objectif != null) 'objectif ${formatKg(c.objectif!)}',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppCouleurs.fond,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_rounded, size: 18, color: AppCouleurs.gris),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDateHeure(c.date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  details,
                  style: const TextStyle(color: AppCouleurs.gris, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatKg(c.poids),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (precedente != null) ...[
                const SizedBox(height: 4),
                PuceVariation(perte: precedente!.poids - c.poids),
              ],
            ],
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: onSupprimer,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppCouleurs.gris,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogueModification extends StatefulWidget {
  const _DialogueModification({required this.patient});

  final Patient patient;

  @override
  State<_DialogueModification> createState() => _DialogueModificationState();
}

class _DialogueModificationState extends State<_DialogueModification> {
  final _form = GlobalKey<FormState>();
  late final _nom = TextEditingController(text: widget.patient.nom);
  late final _prenom = TextEditingController(text: widget.patient.prenom);
  late final _age = TextEditingController(text: '${widget.patient.age}');
  late final _taille = TextEditingController(
    text: formatNombre(widget.patient.taille, 0),
  );

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _age, _taille]) {
      c.dispose();
    }
    super.dispose();
  }

  void _valider() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      widget.patient.copyWith(
        nom: _nom.text.trim(),
        prenom: _prenom.text.trim(),
        age: int.parse(_age.text.trim()),
        taille: parseNombre(_taille.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? requis(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Obligatoire' : null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Modifier le patient'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _prenom,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: requis,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nom,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: requis,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _age,
                decoration: const InputDecoration(
                  labelText: 'Âge',
                  suffixText: 'ans',
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  return n == null || n <= 0 || n > 130 ? 'Âge invalide' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taille,
                decoration: const InputDecoration(
                  labelText: 'Taille',
                  suffixText: 'cm',
                ),
                validator: (v) {
                  final n = parseNombre(v ?? '');
                  return n == null || n < 50 || n > 260
                      ? 'Taille invalide'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _valider, child: const Text('Enregistrer')),
      ],
    );
  }
}
