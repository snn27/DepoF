import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'floor_model.freezed.dart';
part 'floor_model.g.dart';

@freezed
class FloorModel with _$FloorModel {
  const factory FloorModel({
    String? id,
    required String warehouseId,
    required int floorNumber,
    required String name,
    required double area,
    String? description,
    @Default(true) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _FloorModel;

  factory FloorModel.fromJson(Map<String, dynamic> json) =>
      _$FloorModelFromJson(json);
  
  // Helper to get display name
  String get displayName => 
      name != null && name!.isNotEmpty 
          ? '$floorNumber - $name' 
          : '$floorNumber. Kat';
} 