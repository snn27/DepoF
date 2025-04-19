import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String userId,
    required String role,
    String? fullName,
    DateTime? updatedAt,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);
  
  // Create a profile model with default employee role
  factory ProfileModel.defaultEmployee(String userId, String? fullName) => ProfileModel(
    userId: userId,
    role: 'employee',
    fullName: fullName,
    updatedAt: DateTime.now(),
  );
  
  // Create a profile model with default admin role
  factory ProfileModel.defaultAdmin(String userId, String? fullName) => ProfileModel(
    userId: userId,
    role: 'admin',
    fullName: fullName,
    updatedAt: DateTime.now(),
  );
} 