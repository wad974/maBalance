import 'package:flutter/material.dart';

import '../data/base_donnees.dart';
import '../data/modeles.dart';
import '../logic/format.dart';
import '../theme.dart';
import 'communs.dart';

/// Champ de recherche de patient : interroge la base à chaque frappe
/// (« %texte% » sur nom et prénom) et propose les résultats sous le champ.
class ChampRecherchePatient extends StatelessWidget {
  const ChampRecherchePatient({
    super.key,
    required this.selection,
    required this.onSelection,
  });

  /// Patient actuellement choisi (son nom est affiché dans le champ).
  final Patient? selection;
  final ValueChanged<Patient> onSelection;

  @override
  Widget build(BuildContext context) {
    final base = DonneesScope.lire(context);
    return Autocomplete<Patient>(
      // Recrée le champ quand la sélection change depuis l'extérieur.
      key: ValueKey(selection?.id),
      initialValue: TextEditingValue(text: selection?.nomComplet ?? ''),
      displayStringForOption: (p) => p.nomComplet,
      optionsBuilder: (valeur) {
        final texte = valeur.text.trim();
        // Pas de suggestions tant que le champ affiche le patient choisi.
        if (texte.isEmpty || texte == selection?.nomComplet) {
          return const <Patient>[];
        }
        return base.rechercherPatients(texte);
      },
      onSelected: (p) {
        FocusManager.instance.primaryFocus?.unfocus();
        onSelection(p);
      },
      fieldViewBuilder: (context, controleur, focus, valider) {
        return TextField(
          controller: controleur,
          focusNode: focus,
          onSubmitted: (_) => valider(),
          decoration: InputDecoration(
            labelText: 'Patient',
            hintText: 'Rechercher par nom ou prénom',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppCouleurs.gris,
            ),
            suffixIcon: ListenableBuilder(
              listenable: controleur,
              builder: (context, _) => controleur.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Effacer',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        controleur.clear();
                        focus.requestFocus();
                      },
                    ),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, choisir, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppCouleurs.encre.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 320,
                    maxWidth: 360,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final p = options.elementAt(i);
                      final actif =
                          AutocompleteHighlightedOption.of(context) == i;
                      return ListTile(
                        dense: true,
                        tileColor: actif
                            ? AppCouleurs.menthe.withValues(alpha: 0.12)
                            : null,
                        leading: AvatarInitiales(p.initiales, taille: 34),
                        title: Text(
                          p.nomComplet,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${p.age} ans · ${formatNombre(p.taille, 0)} cm',
                        ),
                        onTap: () => choisir(p),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
