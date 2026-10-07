import 'package:flutter/material.dart';

import '../theme.dart';

/// Fond dégradé commun à tous les écrans.
class FondDegrade extends StatelessWidget {
  const FondDegrade({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppCouleurs.degradeFond),
      child: SafeArea(bottom: false, child: child),
    );
  }
}

/// En-tête d'écran : pastille dégradée + titre + sous-titre.
class EnTeteEcran extends StatelessWidget {
  const EnTeteEcran({
    super.key,
    required this.icone,
    required this.titre,
    required this.sousTitre,
    this.action,
  });

  final IconData icone;
  final String titre;
  final String sousTitre;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppCouleurs.degradePrincipal,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppCouleurs.menthe.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icone, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(sousTitre, style: const TextStyle(color: AppCouleurs.gris)),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Carte blanche arrondie avec ombre douce.
class Carte extends StatelessWidget {
  const Carte({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rayon = BorderRadius.circular(24);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: rayon,
        boxShadow: [
          BoxShadow(
            color: AppCouleurs.encre.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: rayon,
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(22),
            child: child,
          ),
        ),
      ),
    );
  }
}

class TitreCarte extends StatelessWidget {
  const TitreCarte(
    this.icone,
    this.texte,
    this.couleur, {
    super.key,
    this.action,
  });

  final IconData icone;
  final String texte;
  final Color couleur;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: couleur, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texte,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Carte d'information quand il n'y a rien à afficher.
class CarteVide extends StatelessWidget {
  const CarteVide({super.key, required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Carte(
      child: Row(
        children: [
          Icon(
            icone,
            size: 40,
            color: AppCouleurs.menthe.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(texte, style: const TextStyle(color: AppCouleurs.gris)),
          ),
        ],
      ),
    );
  }
}

/// Avatar rond avec les initiales.
class AvatarInitiales extends StatelessWidget {
  const AvatarInitiales(this.initiales, {super.key, this.taille = 48});

  final String initiales;
  final double taille;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppCouleurs.degradePrincipal,
      ),
      child: Text(
        initiales,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: taille * 0.36,
        ),
      ),
    );
  }
}

/// Bouton principal avec dégradé.
class BoutonDegrade extends StatelessWidget {
  const BoutonDegrade({
    super.key,
    required this.icone,
    required this.label,
    required this.onPressed,
  });

  final IconData icone;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final actif = onPressed != null;
    return Opacity(
      opacity: actif ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppCouleurs.degradePrincipal,
          borderRadius: BorderRadius.circular(16),
          boxShadow: actif
              ? [
                  BoxShadow(
                    color: AppCouleurs.lavande.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      overflow: TextOverflow.ellipsis,
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
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

/// Demande confirmation avant une action destructrice.
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String message,
  String action = 'Supprimer',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(titre),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppCouleurs.corail),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
