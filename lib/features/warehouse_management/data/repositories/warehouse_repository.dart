import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/warehouse_model.dart';
import '../models/floor_model.dart';

part 'warehouse_repository.g.dart';

class WarehouseRepository {
  final SupabaseService _supabaseService;
  static const String _warehouseTable = 'warehouses';
  static const String _floorTable = 'floors';

  WarehouseRepository(this._supabaseService);

  // Tüm depoları getir
  Future<List<WarehouseModel>> getAllWarehouses({
    String? searchTerm,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
      final query = _supabaseService.client.from(_warehouseTable).select();
      
      // Arama terimi varsa filtrele
      if (searchTerm != null && searchTerm.isNotEmpty) {
        query.ilike('name', '%$searchTerm%');
      }
      
      // Sıralama
      if (sortBy != null) {
        query.order(sortBy, ascending: ascending);
      } else {
        query.order('name', ascending: true);
      }
      
      final data = await query;
      
      return data.map((warehouse) => WarehouseModel.fromJson(warehouse)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ID'ye göre depo getir
  Future<WarehouseModel> getWarehouseById(String id) async {
    try {
      final data = await _supabaseService.readById(_warehouseTable, id);
      return WarehouseModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Yeni depo oluştur
  Future<WarehouseModel> createWarehouse(WarehouseModel warehouse) async {
    try {
      final data = await _supabaseService.create(_warehouseTable, warehouse.toJson());
      return WarehouseModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Depo güncelle
  Future<WarehouseModel> updateWarehouse(WarehouseModel warehouse) async {
    try {
      if (warehouse.id == null) {
        throw Exception('Depo ID boş olamaz');
      }
      
      final data = await _supabaseService.update(_warehouseTable, warehouse.id!, warehouse.toJson());
      return WarehouseModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Depo sil
  Future<void> deleteWarehouse(String id) async {
    try {
      await _supabaseService.delete(_warehouseTable, id);
    } catch (e) {
      rethrow;
    }
  }
  
  // Depoya ait katları getir
  Future<List<FloorModel>> getFloorsByWarehouseId(String warehouseId) async {
    try {
      final data = await _supabaseService.client
          .from(_floorTable)
          .select()
          .eq('warehouse_id', warehouseId)
          .order('floor_number', ascending: true);
      
      return data.map((floor) => FloorModel.fromJson(floor)).toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // ID'ye göre kat getir
  Future<FloorModel> getFloorById(String id) async {
    try {
      final data = await _supabaseService.readById(_floorTable, id);
      return FloorModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }
  
  // Yeni kat oluştur
  Future<FloorModel> createFloor(FloorModel floor) async {
    try {
      // Aynı depoda aynı kat numarası varsa kontrol et
      final existing = await _supabaseService.client
          .from(_floorTable)
          .select()
          .eq('warehouse_id', floor.warehouseId)
          .eq('floor_number', floor.floorNumber)
          .maybeSingle();
          
      if (existing != null) {
        throw Exception('Bu depoda bu kat numarası zaten mevcut');
      }
      
      final data = await _supabaseService.create(_floorTable, floor.toJson());
      return FloorModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }
  
  // Kat güncelle
  Future<FloorModel> updateFloor(FloorModel floor) async {
    try {
      if (floor.id == null) {
        throw Exception('Kat ID boş olamaz');
      }
      
      // Eğer kat numarası değiştiyse, çakışma kontrolü yap
      final originalFloor = await getFloorById(floor.id!);
      if (originalFloor.floorNumber != floor.floorNumber) {
        final existing = await _supabaseService.client
            .from(_floorTable)
            .select()
            .eq('warehouse_id', floor.warehouseId)
            .eq('floor_number', floor.floorNumber)
            .maybeSingle();
            
        if (existing != null) {
          throw Exception('Bu depoda bu kat numarası zaten mevcut');
        }
      }
      
      final data = await _supabaseService.update(_floorTable, floor.id!, floor.toJson());
      return FloorModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }
  
  // Kat sil
  Future<void> deleteFloor(String id) async {
    try {
      await _supabaseService.delete(_floorTable, id);
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
WarehouseRepository warehouseRepository(WarehouseRepositoryRef ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return WarehouseRepository(supabaseService);
} 