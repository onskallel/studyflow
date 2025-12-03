class ObjectifQuotidien {
  final int? id;
  final int objectifMinutes;

  ObjectifQuotidien({
    this.id,
    required this.objectifMinutes,
  }) {
    _validerDonnees();
  }

  void _validerDonnees() {
    if (objectifMinutes <= 0) {
      throw ArgumentError("L'objectif doit être positif");
    }
    if (objectifMinutes > 720) {
      // 12 heures max
      throw ArgumentError("L'objectif ne peut pas dépasser 12 heures");
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'objectifMinutes': objectifMinutes,
    };
  }

  factory ObjectifQuotidien.fromMap(Map<String, dynamic> map) {
    return ObjectifQuotidien(
      id: map['id'],
      objectifMinutes: map['objectifMinutes'],
    );
  }

  String get objectifFormate {
    if (objectifMinutes < 60) {
      return '${objectifMinutes}min';
    } else {
      final heures = objectifMinutes ~/ 60;
      final minutes = objectifMinutes % 60;
      if (minutes == 0) {
        return '${heures}h';
      } else {
        return '${heures}h${minutes}min';
      }
    }
  }

  double get objectifEnHeures {
    return objectifMinutes / 60;
  }

  bool objectifAtteint(int minutesEtudiees) {
    return minutesEtudiees >= objectifMinutes;
  }

  double calculerProgression(int minutesEtudiees) {
    if (objectifMinutes == 0) return 0.0;
    final progression = minutesEtudiees / objectifMinutes;
    return progression > 1.0 ? 1.0 : progression;
  }

  String getMessageMotivation(int minutesEtudiees) {
    final progression = calculerProgression(minutesEtudiees);

    if (progression >= 1.0) {
      return "🎉 Objectif atteint ! Excellent travail !";
    } else if (progression >= 0.75) {
      return "💪 Presque là ! Continue comme ça !";
    } else if (progression >= 0.5) {
      return "🔥 Bon rythme, tu es sur la bonne voie !";
    } else if (progression >= 0.25) {
      return "📚 C'est un bon début, continue !";
    } else {
      return "🚀 Commence dès maintenant, chaque minute compte !";
    }
  }

  @override
  String toString() {
    return 'ObjectifQuotidien(id: $id, objectifMinutes: $objectifMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ObjectifQuotidien &&
        other.id == id &&
        other.objectifMinutes == objectifMinutes;
  }

  @override
  int get hashCode {
    return Object.hash(id, objectifMinutes);
  }
}
