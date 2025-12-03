class SessionEtude {
  final int? id;
  final int matiereId;
  final int duree;
  final DateTime date;
  final String note;

  SessionEtude({
    this.id,
    required this.matiereId,
    required this.duree,
    required this.date,
    required this.note,
  }) {
    _validerDonnees();
  }

  void _validerDonnees() {
    if (matiereId <= 0) {
      throw ArgumentError("L'ID de la matière doit être positif");
    }
    if (duree <= 0) {
      throw ArgumentError("La durée doit être positive");
    }
    if (duree > 480) {
      // 8 heures max
      throw ArgumentError("La durée ne peut pas dépasser 8 heures");
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matiereId': matiereId,
      'duree': duree,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory SessionEtude.fromMap(Map<String, dynamic> map) {
    return SessionEtude(
      id: map['id'],
      matiereId: map['matiereId'],
      duree: map['duree'],
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }

  String get dureeFormatee {
    if (duree < 60) {
      return '${duree}min';
    } else {
      final heures = duree ~/ 60;
      final minutes = duree % 60;
      if (minutes == 0) {
        return '${heures}h';
      } else {
        return '${heures}h${minutes}min';
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matiereId': matiereId,
      'duree': duree,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory SessionEtude.fromJson(Map<String, dynamic> json) {
    return SessionEtude(
      id: json['id'],
      matiereId: json['matiereId'],
      duree: json['duree'],
      date: DateTime.parse(json['date']),
      note: json['note'],
    );
  }

  @override
  String toString() {
    return 'SessionEtude(id: $id, matiereId: $matiereId, duree: ${duree}min, date: $date, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionEtude &&
        other.id == id &&
        other.matiereId == matiereId &&
        other.duree == duree &&
        other.date == date &&
        other.note == note;
  }

  @override
  int get hashCode {
    return Object.hash(id, matiereId, duree, date, note);
  }
}
