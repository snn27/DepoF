import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'pending_entry_model.freezed.dart';
part 'pending_entry_model.g.dart';

enum PendingEntryStatus {
  pending,
  approved,
  rejected
}

@freezed
class PendingEntryModel with _$PendingEntryModel {
  const factory PendingEntryModel({
    String? id,
    required String customerId,
    required String productId,
    required String warehouseId,
    required String floorId,
    required double quantity,
    required String unit,
    required String requestedByUserId,
    @Default('pending') String status,
    DateTime? requestTimestamp,
    String? approvalUserId,
    DateTime? approvalTimestamp,
    String? notes,
    
    // Joined data for display purposes - not part of the actual DB table
    String? customerName,
    String? productName,
    String? warehouseName,
    String? floorName,
    String? requestedByUserName,
    String? approvalUserName,
  }) = _PendingEntryModel;

  factory PendingEntryModel.fromJson(Map<String, dynamic> json) => _$PendingEntryModelFromJson(json);
  
  // Helper to check if entry is pending
  bool get isPending => status == 'pending';
  
  // Helper to check if entry is approved
  bool get isApproved => status == 'approved';
  
  // Helper to check if entry is rejected
  bool get isRejected => status == 'rejected';
} 