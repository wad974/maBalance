import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'fenetre_bulle.dart';

/// Affiche la bulle ou l'application complète selon l'état de la fenêtre.
/// L'application reste montée en mode bulle pour conserver la saisie en cours.
class CadreFenetre extends StatelessWidget {
  const CadreFenetre({super.key, required this.fenetre, required this.child});

  final FenetreBulle fenetre;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fenetre,
      builder: (context, _) {
        final reduit = fenetre.reduit;
        return Stack(
          children: [
            Offstage(
              offstage: reduit,
              child: reduit
                  // Taille fixe tant que la fenêtre est minuscule, pour éviter
                  // des erreurs de mise en page invisibles.
                  ? OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: FenetreBulle.largeurApp,
                      maxWidth: FenetreBulle.largeurApp,
                      minHeight: FenetreBulle.hauteurApp,
                      maxHeight: FenetreBulle.hauteurApp,
                      child: _FenetreApp(fenetre: fenetre, child: child),
                    )
                  : _FenetreApp(fenetre: fenetre, child: child),
            ),
            if (reduit) _Bulle(fenetre: fenetre),
          ],
        );
      },
    );
  }
}

class _FenetreApp extends StatelessWidget {
  const _FenetreApp({required this.fenetre, required this.child});

  final FenetreBulle fenetre;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): fenetre.reduire,
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: AppCouleurs.fond,
          child: Column(
            children: [
              _BarreTitre(fenetre: fenetre),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarreTitre extends StatelessWidget {
  const _BarreTitre({required this.fenetre});

  final FenetreBulle fenetre;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppCouleurs.degradePrincipal,
              ),
              child: const Icon(
                Icons.monitor_weight_outlined,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Ma Balance',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppCouleurs.encre,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: fenetre.reduire,
              icon: const Icon(Icons.remove_rounded, color: AppCouleurs.gris),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: fenetre.quitter,
              icon: const Icon(
                Icons.power_settings_new_rounded,
                color: AppCouleurs.corail,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _Bulle extends StatefulWidget {
  const _Bulle({required this.fenetre});

  final FenetreBulle fenetre;

  @override
  State<_Bulle> createState() => _BulleState();
}

class _BulleState extends State<_Bulle> {
  bool _survol = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _survol = true),
        onExit: (_) => setState(() => _survol = false),
        child: GestureDetector(
          onTap: widget.fenetre.agrandir,
          onPanStart: (_) => widget.fenetre.commencerDeplacement(),
          child: AnimatedScale(
            scale: _survol ? 1.08 : 1,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppCouleurs.degradePrincipal,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppCouleurs.lavande.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.monitor_weight_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
