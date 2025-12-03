// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'objectif.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ObjectifQuotidienAdapter extends TypeAdapter<ObjectifQuotidien> {
  @override
  final int typeId = 2;

  @override
  ObjectifQuotidien read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ObjectifQuotidien(
      id: fields[0] as int,
      objectifMinutes: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ObjectifQuotidien obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.objectifMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObjectifQuotidienAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
