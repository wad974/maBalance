import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/base_donnees.dart';
import 'fenetre/cadre_fenetre.dart';
import 'fenetre/fenetre_bulle.dart';
import 'screens/accueil.dart';
import 'theme.dart';

/// Mode bulle activé par défaut sur ordinateur. Pour lancer l'application
/// en fenêtre classique : `flutter run --dart-define=BULLE=false`.
const _bulleDemandee = bool.fromEnvironment('BULLE', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final base = await BaseDonnees.ouvrir();
  final bureau = !kIsWeb && (Platform.isMacOS || Platform.isLinux);
  final fenetre = bureau && _bulleDemandee
      ? await FenetreBulle.initialiser()
      : null;
  runApp(MonApp(base: base, fenetre: fenetre));
}

class MonApp extends StatelessWidget {
  const MonApp({super.key, required this.base, this.fenetre});

  final BaseDonnees base;

  /// Null : fenêtre classique (tests, mobile, BULLE=false).
  final FenetreBulle? fenetre;

  @override
  Widget build(BuildContext context) {
    final f = fenetre;
    return DonneesScope(
      base: base,
      child: MaterialApp(
        title: 'Ma Balance',
        debugShowCheckedModeBanner: false,
        theme: construireTheme(),
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        color: Colors.transparent,
        builder: f == null
            ? null
            : (context, child) => CadreFenetre(fenetre: f, child: child!),
        home: const Accueil(),
      ),
    );
  }
}
