# Ma Balance

Application macOS de calcul et de suivi de perte de poids : calculateur
(perte en %, objectif, IMC), fiches patients enregistrées dans une base
SQLite locale et statistiques (courbes, diagrammes, camemberts).

L'application se présente comme une petite bulle au bord gauche de l'écran.
Un clic l'ouvre ; un clic ailleurs (ou Échap) la referme.

---

## Installer sur un Mac

1. Télécharger **MaBalance.dmg** :
   https://github.com/wad974/maBalance/releases/latest/download/MaBalance.dmg
2. Ouvrir le fichier téléchargé, puis glisser **Ma Balance** dans le dossier
   **Applications**.
3. Lancer **Ma Balance** depuis le Launchpad ou le dossier Applications.

### Premier lancement : « Apple ne peut pas vérifier… »

L'application n'est pas signée par Apple (cela nécessite un abonnement
développeur payant). macOS la bloque donc **la première fois uniquement** :

1. Cliquer sur **Terminé** dans le message d'alerte.
2. Ouvrir **Réglages Système → Confidentialité et sécurité**.
3. Descendre jusqu'au message concernant « Ma Balance » et cliquer sur
   **Ouvrir quand même**, puis confirmer avec le mot de passe du Mac.

Les lancements suivants se font normalement.

<details>
<summary>Alternative avec le Terminal</summary>

```sh
xattr -dr com.apple.quarantine "/Applications/Ma Balance.app"
```
</details>

### Utilisation

- **Bulle** : cliquer pour ouvrir ; la faire glisser verticalement pour la
  déplacer le long du bord gauche (sa position est mémorisée).
- **Fenêtre ouverte** : `−` ou **Échap** pour revenir à la bulle,
  ⏻ pour quitter. Elle se replie aussi quand on clique dans une autre
  application.
- **Menu du bas** : Stats à gauche, Calcul au centre, Patients à droite.

### Où sont les données ?

Uniquement sur le Mac, jamais sur Internet :

```
~/Library/Containers/com.jcwad.mabalance/Data/Library/Application Support/com.jcwad.mabalance/ma_balance.db
```

Pour une sauvegarde, copier ce fichier (application fermée).

---

## Développement

```sh
flutter pub get
flutter test
flutter run -d linux                      # mode bulle
flutter run -d linux --dart-define=BULLE=false   # fenêtre classique
```

Sous Linux, l'application force le passage par X11 (XWayland) : Wayland
n'autorise pas une application à se positionner elle-même à l'écran.

### Publier une nouvelle version pour Mac

La compilation macOS se fait sur les Mac de GitHub Actions
([.github/workflows/macos.yml](.github/workflows/macos.yml)) ; aucun Mac
n'est nécessaire.

1. Augmenter `version:` dans `pubspec.yaml` (ex. `1.0.1+2`).
2. Créer et envoyer le tag correspondant :

   ```sh
   git commit -am "Version 1.0.1"
   git tag v1.0.1
   git push && git push --tags
   ```

3. Après ~10 minutes, le `.dmg` est publié dans les *Releases* du dépôt ;
   le lien de téléchargement ci-dessus pointe toujours vers la dernière
   version.

Sur un Mac avec Flutter et Xcode, on peut aussi le faire localement :

```sh
flutter build macos --release
scripts/creer_dmg.sh        # crée dist/MaBalance.dmg
```

### Structure

| Dossier | Contenu |
|---|---|
| `lib/logic/` | Calculs (perte, objectif, IMC), statistiques, formats |
| `lib/data/` | Base SQLite (patients, consultations) |
| `lib/screens/` | Écrans : calcul, statistiques, patients, fiche patient |
| `lib/widgets/` | Composants communs, popup de sauvegarde, recherche |
| `lib/fenetre/` | Mode bulle (position, taille, transparence) |
