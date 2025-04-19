import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'customer_model.freezed.dart';
part 'customer_model.g.dart';

@freezed
class CustomerModel with _$CustomerModel {
  const factory CustomerModel({
    String? id,
    required String firstName,
    required String lastName,
    String? phone,
    String? district,
    String? village,
    String? tcKimlikNo,
    DateTime? createdAt,
  }) = _CustomerModel;

  factory CustomerModel.fromJson(Map<String, dynamic> json) => _$CustomerModelFromJson(json);
  
  // Helper method to get full name
  @override
  String toString() => '${firstName} ${lastName}';
} 