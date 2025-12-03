// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionEtudeAdapter extends TypeAdapter<SessionEtude> {
  @override
  final int typeId = 1;

  @override
  SessionEtude read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionEtude(
      id: fields[0] as int?,
      matiereId: fields[1] as int,
      duree: fields[2] as int,
      date: fields[3] as DateTime,
      note: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SessionEtude obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.matiereId)
      ..writeByte(2)
      ..write(obj.duree)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionEtudeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
