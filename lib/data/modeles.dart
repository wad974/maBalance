class Patient {
  const Patient({
    this.id,
    required this.nom,
    required this.prenom,
    required this.age,
    required this.taille,
    required this.creeLe,
  });

  final int? id;
  final String nom;
  final String prenom;
  final int age;
  final double taille;
  final DateTime creeLe;

  String get nomComplet => '$prenom $nom';

  String get initiales =>
      '${prenom.isEmpty ? '' : prenom[0]}${nom.isEmpty ? '' : nom[0]}'
          .toUpperCase();

  Patient copyWith({String? nom, String? prenom, int? age, double? taille}) =>
      Patient(
        id: id,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        age: age ?? this.age,
        taille: taille ?? this.taille,
        creeLe: creeLe,
      );

  Map<String, Object?> versMap() => {
    if (id != null) 'id': id,
    'nom': nom,
    'prenom': prenom,
    'age': age,
    'taille': taille,
    'cree_le': creeLe.millisecondsSinceEpoch,
  };

  factory Patient.depuisMap(Map<String, Object?> m) => Patient(
    id: m['id'] as int,
    nom: m['nom'] as String,
    prenom: m['prenom'] as String,
    age: m['age'] as int,
    taille: (m['taille'] as num).toDouble(),
    creeLe: DateTime.fromMillisecondsSinceEpoch(m['cree_le'] as int),
  );
}

/// Une pesée enregistrée depuis le calculateur.
class Consultation {
  const Consultation({
    this.id,
    required this.patientId,
    required this.date,
    required this.poids,
    this.poidsInitial,
    this.objectif,
    required this.taille,
    required this.age,
  });

  final int? id;
  final int patientId;
  final DateTime date;
  final double poids;
  final double? poidsInitial;
  final double? objectif;
  final double taille;
  final int age;

  Map<String, Object?> versMap() => {
    if (id != null) 'id': id,
    'patient_id': patientId,
    'date': date.millisecondsSinceEpoch,
    'poids': poids,
    'poids_initial': poidsInitial,
    'objectif': objectif,
    'taille': taille,
    'age': age,
  };

  factory Consultation.depuisMap(Map<String, Object?> m) => Consultation(
    id: m['id'] as int,
    patientId: m['patient_id'] as int,
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
    poids: (m['poids'] as num).toDouble(),
    poidsInitial: (m['poids_initial'] as num?)?.toDouble(),
    objectif: (m['objectif'] as num?)?.toDouble(),
    taille: (m['taille'] as num).toDouble(),
    age: m['age'] as int,
  );
}

/// Patient accompagné d'un résumé de ses consultations, pour les listes.
class ResumePatient {
  const ResumePatient({
    required this.patient,
    required this.nbConsultations,
    this.poidsDepart,
    this.dernierPoids,
    this.derniereDate,
  });

  final Patient patient;
  final int nbConsultations;
  final double? poidsDepart;
  final double? dernierPoids;
  final DateTime? derniereDate;
}
