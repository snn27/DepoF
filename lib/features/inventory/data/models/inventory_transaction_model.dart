import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'inventory_transaction_model.freezed.dart';
part 'inventory_transaction_model.g.dart';

enum TransactionType {
  approvedEntry,
  dispatch,
  correctionPlus,
  correctionMinus
}

@freezed
class InventoryTransactionModel with _$InventoryTransactionModel {
  const factory InventoryTransactionModel({
    int? id,
    required String customerId,
    required String productId,
    required String warehouseId,
    required String floorId,
    required String transactionType,
    required double quantity,
    DateTime? transactionDate,
    required String relatedUserId,
    String? pendingEntryId,
    String? notes,
    
    // Joined data for display purposes - not part of the actual DB table
    String? customerName,
    String? productName,
    String? productSku,
    String? warehouseName,
    String? floorName,
    String? relatedUserName,
  }) = _InventoryTransactionModel;

  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) => _$InventoryTransactionModelFromJson(json);
  
  // Helper to check if transaction is an entry
  bool get isEntry => transactionType == 'approved_entry' || 
                      transactionType == 'correction_plus';
  
  // Helper to check if transaction is a dispatch
  bool get isDispatch => transactionType == 'dispatch' || 
                        transactionType == 'correction_minus';
                        
  // Helper to get formatted transaction type in Turkish
  String get formattedType {
    switch (transactionType) {
      case 'approved_entry':
        return 'Giriş';
      case 'dispatch':
        return 'Çıkış';
      case 'correction_plus':
        return 'Düzeltme (+)';
      case 'correction_minus':
        return 'Düzeltme (-)';
      default:
        return transactionType;
    }
  }
} 