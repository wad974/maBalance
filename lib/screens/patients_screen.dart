import 'package:flutter/material.dart';

import '../data/base_donnees.dart';
import '../data/modeles.dart';
import '../logic/format.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import 'fiche_patient_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key, required this.onVoirStats});

  final ValueChanged<int> onVoirStats;

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<ResumePatient>? _resumes;
  String _recherche = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _charger(DonneesScope.of(context));
  }

  Future<void> _charger(BaseDonnees base) async {
    final r = await base.resumes();
    if (mounted) setState(() => _resumes = r);
  }

  void _ouvrir(Patient p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FichePatientScreen(
          patientId: p.id!,
          onVoirStats: widget.onVoirStats,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resumes = _resumes;
    final q = _recherche.trim().toLowerCase();
    final filtres = resumes
        ?.where(
          (r) => q.isEmpty || r.patient.nomComplet.toLowerCase().contains(q),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondDegrade(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EnTeteEcran(
                    icone: Icons.people_alt_rounded,
                    titre: 'Patients',
                    sousTitre: resumes == null
                        ? 'Chargement…'
                        : '${resumes.length} patient${resumes.length > 1 ? 's' : ''} suivi${resumes.length > 1 ? 's' : ''}',
                  ),
                  const SizedBox(height: 24),
                  if (resumes == null)
                    const Center(child: CircularProgressIndicator())
                  else if (resumes.isEmpty)
                    const CarteVide(
                      icone: Icons.person_add_alt_rounded,
                      texte:
                          'Aucun patient pour le moment. Fais un calcul '
                          'puis appuie sur « Sauvegarder ».',
                    )
                  else ...[
                    TextField(
                      onChanged: (v) => setState(() => _recherche = v),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un patient',
                        fillColor: Colors.white,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppCouleurs.gris,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (filtres!.isEmpty)
                      const CarteVide(
                        icone: Icons.search_off_rounded,
                        texte: 'Aucun patient ne correspond à la recherche.',
                      ),
                    for (final r in filtres) ...[
                      _CartePatient(resume: r, onTap: () => _ouvrir(r.patient)),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartePatient extends StatelessWidget {
  const _CartePatient({required this.resume, required this.onTap});

  final ResumePatient resume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = resume.patient;
    final depart = resume.poidsDepart;
    final dernier = resume.dernierPoids;
    final perte = depart != null && dernier != null ? depart - dernier : null;

    return Carte(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          AvatarInitiales(p.initiales),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nomComplet,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.age} ans · ${formatNombre(p.taille, 0)} cm · '
                  '${resume.nbConsultations} consultation${resume.nbConsultations > 1 ? 's' : ''}',
                  style: const TextStyle(color: AppCouleurs.gris, fontSize: 13),
                ),
                if (resume.derniereDate != null)
                  Text(
                    'Dernière visite le ${formatDate(resume.derniereDate!)}',
                    style: const TextStyle(
                      color: AppCouleurs.gris,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (dernier != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatKg(dernier),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (perte != null) ...[
                  const SizedBox(height: 4),
                  PuceVariation(perte: perte),
                ],
              ],
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppCouleurs.gris),
        ],
      ),
    );
  }
}

/// Pastille « −3,2 kg » (perte) ou « +1,0 kg » (prise).
class PuceVariation extends StatelessWidget {
  const PuceVariation({super.key, required this.perte});

  /// Kg perdus (négatif = prise de poids).
  final double perte;

  @override
  Widget build(BuildContext context) {
    final couleur = perte >= 0.05
        ? CouleursGraph.perte
        : (perte <= -0.05 ? CouleursGraph.prise : AppCouleurs.gris);
    final icone = perte >= 0.05
        ? Icons.south_east_rounded
        : (perte <= -0.05 ? Icons.north_east_rounded : Icons.east_rounded);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: couleur),
          const SizedBox(width: 4),
          Text(
            formatEcart(perte),
            style: TextStyle(
              color: AppCouleurs.encre,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
