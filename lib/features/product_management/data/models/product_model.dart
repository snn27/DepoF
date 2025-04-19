import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    String? id,
    required String sku,
    required String name,
    String? category,
    required String unit,
    double? minStockLevel,
    DateTime? createdAt,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);
  
  // Helper method to check if product is below minimum stock level
  bool isBelowMinimumStock(double currentStock) {
    if (minStockLevel == null) return false;
    return currentStock < minStockLevel!;
  }
} 