import 'package:flutter/material.dart';

import '../theme.dart';
import 'calculateur_screen.dart';
import 'patients_screen.dart';
import 'stats_screen.dart';

/// Écran principal : trois onglets et le menu en bas
/// (Stats à gauche, Calcul au centre, Patients à droite).
class Accueil extends StatefulWidget {
  const Accueil({super.key});

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  static const _stats = 0;
  static const _calcul = 1;
  static const _patients = 2;

  int _onglet = _calcul;
  int? _patientStats;

  void _voirStats(int patientId) => setState(() {
    _patientStats = patientId;
    _onglet = _stats;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _onglet,
        children: [
          StatsScreen(
            patientId: _patientStats,
            onPatientChange: (id) => setState(() => _patientStats = id),
          ),
          const CalculateurScreen(),
          PatientsScreen(onVoirStats: _voirStats),
        ],
      ),
      bottomNavigationBar: _MenuBas(
        onglet: _onglet,
        onChange: (i) => setState(() => _onglet = i),
      ),
    );
  }
}

class _MenuBas extends StatelessWidget {
  const _MenuBas({required this.onglet, required this.onChange});

  final int onglet;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SizedBox(
              height: 84,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppCouleurs.encre.withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ItemMenu(
                            icone: Icons.insights_rounded,
                            label: 'Stats',
                            actif: onglet == _AccueilState._stats,
                            onTap: () => onChange(_AccueilState._stats),
                          ),
                        ),
                        const SizedBox(width: 84),
                        Expanded(
                          child: _ItemMenu(
                            icone: Icons.people_alt_rounded,
                            label: 'Patients',
                            actif: onglet == _AccueilState._patients,
                            onTap: () => onChange(_AccueilState._patients),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: _BoutonCentral(
                      actif: onglet == _AccueilState._calcul,
                      onTap: () => onChange(_AccueilState._calcul),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.icone,
    required this.label,
    required this.actif,
    required this.onTap,
  });

  final IconData icone;
  final String label;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? AppCouleurs.mentheFonce : AppCouleurs.gris;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: actif
                  ? AppCouleurs.menthe.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: couleur),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: couleur,
              fontSize: 12,
              fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonCentral extends StatelessWidget {
  const _BoutonCentral({required this.actif, required this.onTap});

  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Calcul',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: actif ? 1 : 0.92,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppCouleurs.degradePrincipal,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppCouleurs.lavande.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
