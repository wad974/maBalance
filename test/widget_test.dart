import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mon_app/data/base_donnees.dart';
import 'package:mon_app/data/modeles.dart';
import 'package:mon_app/logic/calculs.dart';
import 'package:mon_app/logic/stats.dart';
import 'package:mon_app/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<BaseDonnees> baseMemoire() => BaseDonnees.ouvrir(
  chemin: inMemoryDatabasePath,
  fabrique: databaseFactoryFfiNoIsolate,
);

Consultation pesee(DateTime d, double poids, {double? initial, double? obj}) =>
    Consultation(
      patientId: 1,
      date: d,
      poids: poids,
      poidsInitial: initial,
      objectif: obj,
      taille: 170,
      age: 40,
    );

/// Laisse la base répondre (I/O réelle) jusqu'à ce que [f] apparaisse.
Future<void> attendre(WidgetTester tester, Finder f) async {
  for (var i = 0; i < 50 && f.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('calculs', () {
    test('parseNombre accepte la virgule', () {
      expect(parseNombre('72,5'), 72.5);
      expect(parseNombre(''), isNull);
      expect(parseNombre('abc'), isNull);
    });

    test('pourcentagePerte', () {
      expect(pourcentagePerte(100, 90), closeTo(10, 1e-9));
      expect(pourcentagePerte(80, 84), closeTo(-5, 1e-9));
    });

    test('progressionObjectif', () {
      expect(progressionObjectif(100, 90, 80), closeTo(50, 1e-9));
      expect(progressionObjectif(100, 75, 80), 100);
      expect(progressionObjectif(100, 105, 80), 0);
    });

    test('imc et catégorie', () {
      final v = imc(70, 175);
      expect(v, closeTo(22.86, 0.01));
      expect(categorieImc(v), CategorieImc.normal);
      expect(categorieImc(31), CategorieImc.obesiteModeree);
    });
  });

  group('base de données', () {
    test('réutilise le patient existant (nom + prénom, sans casse)', () async {
      final base = await baseMemoire();
      final id1 = await base.enregistrerConsultation(
        nom: 'Dupont',
        prenom: 'Marie',
        age: 40,
        taille: 165,
        poids: 80,
      );
      final id2 = await base.enregistrerConsultation(
        nom: 'dupont ',
        prenom: 'MARIE',
        age: 41,
        taille: 165,
        poids: 78,
      );
      expect(id2, id1);

      final patients = await base.patients();
      expect(patients, hasLength(1));
      expect(patients.single.age, 41);
      expect(await base.consultations(id1), hasLength(2));

      final resume = (await base.resumes()).single;
      expect(resume.nbConsultations, 2);
      expect(resume.poidsDepart, 80);
      expect(resume.dernierPoids, 78);
      await base.fermer();
    });

    test('supprimer un patient supprime ses consultations', () async {
      final base = await baseMemoire();
      final id = await base.enregistrerConsultation(
        nom: 'A',
        prenom: 'B',
        age: 30,
        taille: 170,
        poids: 70,
      );
      await base.supprimerPatient(id);
      expect(await base.patients(), isEmpty);
      expect(await base.consultations(id), isEmpty);
      await base.fermer();
    });

    test('filtre les consultations par dates', () async {
      final base = await baseMemoire();
      final id = await base.enregistrerConsultation(
        nom: 'A',
        prenom: 'B',
        age: 30,
        taille: 170,
        poids: 70,
        date: DateTime(2026, 1, 1),
      );
      await base.enregistrerConsultation(
        nom: 'A',
        prenom: 'B',
        age: 30,
        taille: 170,
        poids: 69,
        date: DateTime(2026, 3, 1),
      );
      final r = await base.consultations(id, debut: DateTime(2026, 2, 1));
      expect(r.single.poids, 69);
      await base.fermer();
    });
  });

  group('recherche de patients', () {
    late BaseDonnees base;
    setUp(() async {
      base = await baseMemoire();
      for (final (prenom, nom) in [
        ('Marie', 'Dupont'),
        ('Jean', 'Dupuis'),
        ('Léo', 'Martin'),
        ('Anna', 'Martinez'),
        ('Paul', '100%_Bio'),
      ]) {
        await base.enregistrerConsultation(
          nom: nom,
          prenom: prenom,
          age: 30,
          taille: 170,
          poids: 70,
        );
      }
    });
    tearDown(() => base.fermer());

    Future<List<String>> noms(String t) async => [
      for (final p in await base.rechercherPatients(t)) p.nomComplet,
    ];

    test('partielle, sans casse, sur nom ou prénom', () async {
      expect(await noms('dup'), ['Marie Dupont', 'Jean Dupuis']);
      expect(await noms('MARTIN'), ['Léo Martin', 'Anna Martinez']);
      expect(await noms('ann'), ['Anna Martinez']);
      expect(await noms('  '), isEmpty);
      expect(await noms('zzz'), isEmpty);
    });

    test('sur le nom complet dans les deux ordres', () async {
      expect(await noms('marie dup'), ['Marie Dupont']);
      expect(await noms('dupuis je'), ['Jean Dupuis']);
    });

    test('% et _ saisis sont cherchés littéralement', () async {
      expect(await noms('%'), ['Paul 100%_Bio']);
      expect(await noms('0%_b'), ['Paul 100%_Bio']);
      expect(await noms('_'), ['Paul 100%_Bio']);
    });

    test('limite le nombre de résultats', () async {
      expect(await base.rechercherPatients('a', limite: 2), hasLength(2));
    });

    test('patient par défaut = dernière consultation', () async {
      await base.enregistrerConsultation(
        nom: 'Martin',
        prenom: 'Léo',
        age: 30,
        taille: 170,
        poids: 69,
        date: DateTime.now().add(const Duration(minutes: 1)),
      );
      expect((await base.patientParDefaut())!.nomComplet, 'Léo Martin');
    });
  });

  group('statistiques', () {
    final toutes = [
      pesee(DateTime(2026, 1, 1), 98, initial: 100, obj: 80),
      pesee(DateTime(2026, 2, 1), 95),
      pesee(DateTime(2026, 3, 1), 95.05),
      pesee(DateTime(2026, 4, 1), 96),
      pesee(DateTime(2026, 5, 1), 90),
    ];

    test('sur toute la durée', () {
      final s = StatsPatient.calculer(toutes)!;
      expect(s.poidsDepart, 100);
      expect(s.poidsActuel, 90);
      expect(s.perteTotalePct, closeTo(10, 1e-9));
      expect(s.progression, closeTo(50, 1e-9));
      expect(s.nbPertes, 2);
      expect(s.nbStables, 1);
      expect(s.nbPrises, 1);
    });

    test('sur une période : variation calculée avec la pesée précédente', () {
      final s = StatsPatient.calculer(toutes, debut: DateTime(2026, 4, 1))!;
      expect(s.periode, hasLength(2));
      expect(s.variations.first.delta, closeTo(0.95, 1e-9));
      expect(s.pertePeriodeKg, closeTo(6, 1e-9));
      expect(s.poidsDepart, 100);
    });

    test('période vide', () {
      expect(StatsPatient.calculer(toutes, debut: DateTime(2027)), isNull);
    });
  });

  testWidgets('calcul, sauvegarde puis statistiques', (tester) async {
    tester.view.physicalSize = const Size(1300, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final base = (await tester.runAsync(baseMemoire))!;
    addTearDown(() => tester.runAsync(base.fermer));
    await tester.pumpWidget(MonApp(base: base));
    await tester.pumpAndSettle();

    final champs = find.byType(TextField);
    await tester.enterText(champs.at(0), '170');
    await tester.enterText(champs.at(1), '90');
    await tester.enterText(champs.at(2), '81');
    await tester.pumpAndSettle();
    expect(find.text('10,0 %'), findsOneWidget);
    expect(find.text('Bravo ! Tu as perdu 9,0 kg.'), findsOneWidget);

    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();
    expect(find.text('Enregistrer la consultation'), findsOneWidget);

    final dialogue = find.byType(Dialog);
    await tester.enterText(
      find.descendant(of: dialogue, matching: find.byType(TextFormField)).at(0),
      'Marie',
    );
    await tester.enterText(
      find.descendant(of: dialogue, matching: find.byType(TextFormField)).at(1),
      'Dupont',
    );
    await tester.enterText(
      find.descendant(of: dialogue, matching: find.byType(TextFormField)).at(2),
      '42',
    );
    await tester.tap(
      find.descendant(of: dialogue, matching: find.text('Sauvegarder')),
    );
    await attendre(tester, find.textContaining('Consultation enregistrée'));

    expect(
      find.text('Consultation enregistrée pour Marie Dupont'),
      findsOneWidget,
    );
    final consultations = (await tester.runAsync(
      () async => base.consultations((await base.patients()).single.id!),
    ))!;
    expect(consultations.single.poids, 81);
    expect(consultations.single.poidsInitial, 90);

    // Onglet patients
    await tester.tap(find.text('Patients'));
    await attendre(tester, find.text('Marie Dupont'));
    expect(find.text('Marie Dupont'), findsWidgets);

    // Onglet stats
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Depuis le départ'), findsOneWidget);
    expect(find.text('Évolution du poids (kg)'), findsOneWidget);
  });

  for (final largeur in [1300.0, 420.0]) {
    testWidgets('stats et fiche avec historique (largeur $largeur)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(largeur, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final base = (await tester.runAsync(() async {
        final b = await baseMemoire();
        final debut = DateTime.now().subtract(const Duration(days: 120));
        final poids = [92.0, 90.5, 90.5, 91.2, 88.4, 87.0, 86.1];
        for (var i = 0; i < poids.length; i++) {
          await b.enregistrerConsultation(
            nom: 'Martin',
            prenom: 'Léo',
            age: 35,
            taille: 180,
            poids: poids[i],
            poidsInitial: i == 0 ? 94 : null,
            objectif: 80,
            date: debut.add(Duration(days: i * 18)),
          );
        }
        return b;
      }))!;
      addTearDown(() => tester.runAsync(base.fermer));

      await tester.pumpWidget(MonApp(base: base));
      await attendre(tester, find.text('Ma Balance'));

      await tester.tap(find.text('Stats'));
      await attendre(tester, find.text('Bilan des consultations'));
      expect(find.text('Bilan des consultations'), findsOneWidget);
      expect(find.text('Objectif 80,0 kg'), findsOneWidget);

      // Recherche d'un autre patient dans le champ de saisie.
      await tester.runAsync(
        () => base.enregistrerConsultation(
          nom: 'Dupont',
          prenom: 'Marie',
          age: 42,
          taille: 165,
          poids: 74,
          date: DateTime.now().subtract(const Duration(days: 400)),
        ),
      );
      await attendre(tester, find.text('Léo Martin'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Léo Martin'),
        'dup',
      );
      await attendre(tester, find.text('Marie Dupont'));
      await tester.tap(find.text('Marie Dupont'));
      await attendre(tester, find.text('74,0 kg'));
      expect(
        find.text('Le bilan apparaîtra dès la deuxième consultation.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Marie Dupont'),
        'mart',
      );
      await attendre(tester, find.text('Léo Martin'));
      await tester.tap(find.text('Léo Martin'));
      await attendre(tester, find.text('Bilan des consultations'));

      await tester.tap(find.text('30 jours'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Patients'));
      await attendre(tester, find.text('Léo Martin'));
      await tester.tap(find.text('Léo Martin'));
      await attendre(tester, find.text('Historique des consultations (7)'));
      expect(find.text('Historique des consultations (7)'), findsOneWidget);
    });
  }
}
