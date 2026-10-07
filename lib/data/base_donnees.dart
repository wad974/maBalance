import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'modeles.dart';

/// Accès à la base SQLite. Notifie ses écouteurs après chaque écriture
/// pour que les écrans se rafraîchissent.
class BaseDonnees extends ChangeNotifier {
  BaseDonnees._(this._db);

  final Database _db;

  /// Ouvre (ou crée) la base. [chemin] et [fabrique] servent aux tests.
  static Future<BaseDonnees> ouvrir({
    String? chemin,
    DatabaseFactory? fabrique,
  }) async {
    sqfliteFfiInit();
    final factory = fabrique ?? databaseFactoryFfi;
    final cheminFinal =
        chemin ??
        p.join((await getApplicationSupportDirectory()).path, 'ma_balance.db');

    final db = await factory.openDatabase(
      cheminFinal,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE patients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nom TEXT NOT NULL,
              prenom TEXT NOT NULL,
              age INTEGER NOT NULL,
              taille REAL NOT NULL,
              cree_le INTEGER NOT NULL
            )''');
          await db.execute('''
            CREATE TABLE consultations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              patient_id INTEGER NOT NULL
                REFERENCES patients(id) ON DELETE CASCADE,
              date INTEGER NOT NULL,
              poids REAL NOT NULL,
              poids_initial REAL,
              objectif REAL,
              taille REAL NOT NULL,
              age INTEGER NOT NULL
            )''');
          await db.execute(
            'CREATE INDEX idx_consult_patient ON consultations(patient_id, date)',
          );
        },
      ),
    );
    return BaseDonnees._(db);
  }

  Future<void> fermer() => _db.close();

  // -------------------------------------------------------------------------
  // Lecture

  Future<List<Patient>> patients() async {
    final rows = await _db.query(
      'patients',
      orderBy: 'nom COLLATE NOCASE, prenom COLLATE NOCASE',
    );
    return rows.map(Patient.depuisMap).toList();
  }

  Future<Patient?> patient(int id) async {
    final rows = await _db.query('patients', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Patient.depuisMap(rows.first);
  }

  /// Recherche « %terme% » sur le nom, le prénom et le nom complet
  /// (dans les deux ordres), sans tenir compte de la casse.
  Future<List<Patient>> rechercherPatients(
    String terme, {
    int limite = 20,
  }) async {
    final t = terme.trim();
    if (t.isEmpty) return const [];
    // Les caractères spéciaux de LIKE saisis par l'utilisateur sont échappés.
    final motif =
        '%${t.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    final rows = await _db.query(
      'patients',
      where:
          r"nom LIKE ? ESCAPE '\' OR prenom LIKE ? ESCAPE '\' "
          r"OR (prenom || ' ' || nom) LIKE ? ESCAPE '\' "
          r"OR (nom || ' ' || prenom) LIKE ? ESCAPE '\'",
      whereArgs: [motif, motif, motif, motif],
      orderBy: 'nom COLLATE NOCASE, prenom COLLATE NOCASE',
      limit: limite,
    );
    return rows.map(Patient.depuisMap).toList();
  }

  /// Patient de la consultation la plus récente, sinon le premier patient
  /// par ordre alphabétique. Null s'il n'y a aucun patient.
  Future<Patient?> patientParDefaut() async {
    final rows = await _db.rawQuery('''
      SELECT p.* FROM patients p
      LEFT JOIN consultations c ON c.patient_id = p.id
      ORDER BY c.date IS NULL, c.date DESC,
        p.nom COLLATE NOCASE, p.prenom COLLATE NOCASE
      LIMIT 1
    ''');
    return rows.isEmpty ? null : Patient.depuisMap(rows.first);
  }

  Future<List<ResumePatient>> resumes() async {
    final rows = await _db.rawQuery('''
      SELECT p.*,
        (SELECT COUNT(*) FROM consultations c WHERE c.patient_id = p.id) AS nb,
        (SELECT COALESCE(c.poids_initial, c.poids) FROM consultations c
           WHERE c.patient_id = p.id ORDER BY c.date ASC LIMIT 1) AS depart,
        (SELECT c.poids FROM consultations c
           WHERE c.patient_id = p.id ORDER BY c.date DESC LIMIT 1) AS dernier,
        (SELECT MAX(c.date) FROM consultations c
           WHERE c.patient_id = p.id) AS derniere_date
      FROM patients p
      ORDER BY p.nom COLLATE NOCASE, p.prenom COLLATE NOCASE
    ''');
    return rows
        .map(
          (r) => ResumePatient(
            patient: Patient.depuisMap(r),
            nbConsultations: r['nb'] as int,
            poidsDepart: (r['depart'] as num?)?.toDouble(),
            dernierPoids: (r['dernier'] as num?)?.toDouble(),
            derniereDate: r['derniere_date'] == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    r['derniere_date'] as int,
                  ),
          ),
        )
        .toList();
  }

  /// Consultations d'un patient par date croissante, éventuellement
  /// limitées à l'intervalle [debut, fin] (bornes incluses).
  Future<List<Consultation>> consultations(
    int patientId, {
    DateTime? debut,
    DateTime? fin,
  }) async {
    final where = StringBuffer('patient_id = ?');
    final args = <Object>[patientId];
    if (debut != null) {
      where.write(' AND date >= ?');
      args.add(debut.millisecondsSinceEpoch);
    }
    if (fin != null) {
      where.write(' AND date <= ?');
      args.add(fin.millisecondsSinceEpoch);
    }
    final rows = await _db.query(
      'consultations',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'date ASC',
    );
    return rows.map(Consultation.depuisMap).toList();
  }

  // -------------------------------------------------------------------------
  // Écriture

  /// Enregistre une consultation. Le patient est retrouvé par nom + prénom
  /// (sans tenir compte de la casse) ou créé s'il n'existe pas ; son âge et
  /// sa taille sont mis à jour. Retourne l'id du patient.
  Future<int> enregistrerConsultation({
    required String nom,
    required String prenom,
    required int age,
    required double taille,
    required double poids,
    double? poidsInitial,
    double? objectif,
    DateTime? date,
  }) async {
    final quand = date ?? DateTime.now();
    final patientId = await _db.transaction((txn) async {
      final existants = await txn.query(
        'patients',
        columns: ['id'],
        where: 'nom = ? COLLATE NOCASE AND prenom = ? COLLATE NOCASE',
        whereArgs: [nom.trim(), prenom.trim()],
        limit: 1,
      );

      final int id;
      if (existants.isNotEmpty) {
        id = existants.first['id'] as int;
        await txn.update(
          'patients',
          {'age': age, 'taille': taille},
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        id = await txn.insert(
          'patients',
          Patient(
            nom: nom.trim(),
            prenom: prenom.trim(),
            age: age,
            taille: taille,
            creeLe: quand,
          ).versMap(),
        );
      }

      await txn.insert(
        'consultations',
        Consultation(
          patientId: id,
          date: quand,
          poids: poids,
          poidsInitial: poidsInitial,
          objectif: objectif,
          taille: taille,
          age: age,
        ).versMap(),
      );
      return id;
    });
    notifyListeners();
    return patientId;
  }

  Future<void> modifierPatient(Patient patient) async {
    await _db.update(
      'patients',
      patient.versMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
    notifyListeners();
  }

  Future<void> supprimerPatient(int id) async {
    await _db.delete('patients', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> supprimerConsultation(int id) async {
    await _db.delete('consultations', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }
}

/// Rend la base accessible à tout l'arbre de widgets. Les widgets qui
/// l'utilisent via [DonneesScope.of] sont reconstruits après chaque écriture.
class DonneesScope extends InheritedNotifier<BaseDonnees> {
  const DonneesScope({
    super.key,
    required BaseDonnees base,
    required super.child,
  }) : super(notifier: base);

  static BaseDonnees of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DonneesScope>()!.notifier!;

  /// Accès sans abonnement aux changements (pour les actions ponctuelles).
  static BaseDonnees lire(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DonneesScope>()!.notifier!;
}
