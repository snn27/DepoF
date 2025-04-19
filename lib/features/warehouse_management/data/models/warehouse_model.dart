import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'warehouse_model.freezed.dart';
part 'warehouse_model.g.dart';

@freezed
class WarehouseModel with _$WarehouseModel {
  const factory WarehouseModel({
    String? id,
    required String name,
    required String address,
    String? phone,
    String? email,
    String? description,
    @Default(false) bool isActive,
    @Default(0.0) double totalCapacity,
    @Default(0.0) double currentStock,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _WarehouseModel;

  factory WarehouseModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseModelFromJson(json);
  
  // Helper to calculate usage percentage
  double get usagePercentage => 
      totalCapacity > 0 ? (currentStock / totalCapacity) * 100 : 0;
      
  // Helper to determine if warehouse is almost full (>90%)
  bool get isAlmostFull => usagePercentage >= 90;
} 