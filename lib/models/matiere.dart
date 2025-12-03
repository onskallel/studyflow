class Matiere {
  final int? id;
  final String nom;
  final String couleur;
  final int priorite;
  final int objectifHebdo;

  Matiere({
    this.id,
    required this.nom,
    required this.couleur,
    required this.priorite,
    this.objectifHebdo = 0,
  }) {
    _validerDonnees();
  }

  void _validerDonnees() {
    if (nom.isEmpty) {
      throw ArgumentError("Le nom de la matière ne peut pas être vide");
    }
    if (priorite < 0 || priorite > 2) {
      throw ArgumentError("La priorité doit être entre 0 (Basse) et 2 (Haute)");
    }
    if (objectifHebdo < 0) {
      throw ArgumentError("L'objectif hebdomadaire ne peut pas être négatif");
    }
    if (!couleur.startsWith('#') || couleur.length != 7) {
      throw ArgumentError(
          "La couleur doit être au format hexadécimal: #FF5733");
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'couleur': couleur,
      'priorite': priorite,
      'objectifHebdo': objectifHebdo,
    };
  }

  factory Matiere.fromMap(Map<String, dynamic> map) {
    return Matiere(
      id: map['id'],
      nom: map['nom'],
      couleur: map['couleur'],
      priorite: map['priorite'],
      objectifHebdo: map['objectifHebdo'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'couleur': couleur,
      'priorite': priorite,
      'objectifHebdo': objectifHebdo,
    };
  }

  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      id: json['id'],
      nom: json['nom'],
      couleur: json['couleur'],
      priorite: json['priorite'],
      objectifHebdo: json['objectifHebdo'],
    );
  }

  @override
  String toString() {
    return 'Matiere(id: $id, nom: $nom, couleur: $couleur, priorite: $priorite, objectifHebdo: ${objectifHebdo}min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Matiere &&
        other.id == id &&
        other.nom == nom &&
        other.couleur == couleur &&
        other.priorite == priorite &&
        other.objectifHebdo == objectifHebdo;
  }

  @override
  int get hashCode {
    return Object.hash(id, nom, couleur, priorite, objectifHebdo);
  }
}

class Priorites {
  static const int basse = 0;
  static const int moyenne = 1;
  static const int haute = 2;

  static String getLibelle(int priorite) {
    switch (priorite) {
      case basse:
        return 'Basse';
      case moyenne:
        return 'Moyenne';
      case haute:
        return 'Haute';
      default:
        return 'Inconnue';
    }
  }
}
