// Fonctions de calcul pures, sans dépendance à l'interface.

/// Convertit une saisie utilisateur ("72,5" ou "72.5") en nombre.
/// Retourne null si la saisie est vide ou invalide.
double? parseNombre(String saisie) {
  final texte = saisie.trim().replaceAll(',', '.');
  if (texte.isEmpty) return null;
  return double.tryParse(texte);
}

/// Pourcentage de poids perdu entre [initial] et [actuel].
/// Valeur négative en cas de prise de poids.
double pourcentagePerte(double initial, double actuel) {
  if (initial <= 0) return 0;
  return (initial - actuel) / initial * 100;
}

/// Progression (0 à 100 %) vers le poids [objectif].
double progressionObjectif(double initial, double actuel, double objectif) {
  final aPerdre = initial - objectif;
  if (aPerdre <= 0) return 0;
  return ((initial - actuel) / aPerdre * 100).clamp(0, 100).toDouble();
}

/// Indice de masse corporelle : poids (kg) / taille (m)².
double imc(double poidsKg, double tailleCm) {
  if (tailleCm <= 0) return 0;
  final m = tailleCm / 100;
  return poidsKg / (m * m);
}

enum CategorieImc {
  maigreur('Maigreur'),
  normal('Corpulence normale'),
  surpoids('Surpoids'),
  obesiteModeree('Obésité modérée'),
  obesiteSevere('Obésité sévère'),
  obesiteMassive('Obésité massive');

  const CategorieImc(this.libelle);
  final String libelle;
}

/// Catégorie selon les seuils de l'OMS.
CategorieImc categorieImc(double valeur) {
  if (valeur < 18.5) return CategorieImc.maigreur;
  if (valeur < 25) return CategorieImc.normal;
  if (valeur < 30) return CategorieImc.surpoids;
  if (valeur < 35) return CategorieImc.obesiteModeree;
  if (valeur < 40) return CategorieImc.obesiteSevere;
  return CategorieImc.obesiteMassive;
}
