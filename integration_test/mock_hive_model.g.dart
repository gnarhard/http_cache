// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MockHiveModelAdapter extends TypeAdapter<MockHiveModel> {
  @override
  final int typeId = 0;

  @override
  MockHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MockHiveModel(
      name: fields[1] as String,
      cachedMilliseconds: fields[2] as int,
      id: fields[0] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MockHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.cachedMilliseconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MockHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MockHiveModel _$MockHiveModelFromJson(Map<String, dynamic> json) =>
    MockHiveModel(
      name: json['name'] as String,
      cachedMilliseconds: json['cachedMilliseconds'] as int? ?? 0,
      id: json['id'] as int,
    );

Map<String, dynamic> _$MockHiveModelToJson(MockHiveModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'cachedMilliseconds': instance.cachedMilliseconds,
    };
