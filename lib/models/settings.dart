// lib/models/settings.dart
import 'package:flutter/material.dart';

class AppSettings {
  final int? id;
  final bool modeSombre;
  final bool notificationsActives;
  final TimeOfDay heureRappel;
  final Color couleurPrincipale;
  final int dureePomodoro;

  AppSettings({
    this.id,
    required this.modeSombre,
    required this.notificationsActives,
    required this.heureRappel,
    required this.couleurPrincipale,
    required this.dureePomodoro,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mode_sombre': modeSombre, // ← boolean direct, pas 1 ou 0
      'notifications_actives': notificationsActives, // ← boolean direct
      'heure_rappel':
          '${heureRappel.hour.toString().padLeft(2, '0')}:${heureRappel.minute.toString().padLeft(2, '0')}',
      'couleur_principale': couleurPrincipale.value,
      'duree_pomodoro': dureePomodoro,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final heureParts = (map['heure_rappel'] as String? ?? '18:00').split(':');

    return AppSettings(
      id: map['id'],
      modeSombre: map['mode_sombre'] ?? false, // ← boolean direct
      notificationsActives:
          map['notifications_actives'] ?? true, // ← boolean direct
      heureRappel: TimeOfDay(
        hour: int.parse(heureParts[0]),
        minute: int.parse(heureParts[1]),
      ),
      couleurPrincipale: Color(map['couleur_principale'] ?? 4280391411),
      dureePomodoro: map['duree_pomodoro'] ?? 25,
    );
  }

  AppSettings copyWith({
    int? id,
    bool? modeSombre,
    bool? notificationsActives,
    TimeOfDay? heureRappel,
    Color? couleurPrincipale,
    int? dureePomodoro,
  }) {
    return AppSettings(
      id: id ?? this.id,
      modeSombre: modeSombre ?? this.modeSombre,
      notificationsActives: notificationsActives ?? this.notificationsActives,
      heureRappel: heureRappel ?? this.heureRappel,
      couleurPrincipale: couleurPrincipale ?? this.couleurPrincipale,
      dureePomodoro: dureePomodoro ?? this.dureePomodoro,
    );
  }

  // Factory pour les settings par défaut
  factory AppSettings.defaultSettings() {
    return AppSettings(
      modeSombre: false,
      notificationsActives: true,
      heureRappel: const TimeOfDay(hour: 18, minute: 0),
      couleurPrincipale: Colors.blue,
      dureePomodoro: 25,
    );
  }
}
