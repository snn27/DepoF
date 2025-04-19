import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/product_model.dart';

part 'product_repository.g.dart';

class ProductRepository {
  final SupabaseService _supabaseService;
  static const String _tableName = 'products';

  ProductRepository(this._supabaseService);

  // Tüm ürünleri getir
  Future<List<ProductModel>> getAllProducts({
    String? searchTerm,
    String? sortBy,
    bool ascending = true,
    String? category,
  }) async {
    try {
      final query = _supabaseService.client.from(_tableName).select();
      
      // Arama terimi varsa filtrele
      if (searchTerm != null && searchTerm.isNotEmpty) {
        query.or('name.ilike.%${searchTerm}%,sku.ilike.%${searchTerm}%');
      }
      
      // Kategori filtresi varsa uygula
      if (category != null && category.isNotEmpty) {
        query.eq('category', category);
      }
      
      // Sıralama
      if (sortBy != null) {
        query.order(sortBy, ascending: ascending);
      } else {
        query.order('name', ascending: true);
      }
      
      final data = await query;
      
      // Verileri ProductModel nesnelerine dönüştür
      return data.map((product) => ProductModel.fromJson(product)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ID'ye göre ürün getir
  Future<ProductModel> getProductById(String id) async {
    try {
      final data = await _supabaseService.readById(_tableName, id);
      return ProductModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // SKU'ya göre ürün getir
  Future<ProductModel?> getProductBySku(String sku) async {
    try {
      final data = await _supabaseService.client
          .from(_tableName)
          .select()
          .eq('sku', sku)
          .single();
      
      return ProductModel.fromJson(data);
    } catch (e) {
      return null; // SKU bulunamadığında null dön
    }
  }

  // Yeni ürün oluştur
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      // SKU kontrolü
      final existingProduct = await getProductBySku(product.sku);
      if (existingProduct != null) {
        throw Exception('Bu SKU koduna sahip bir ürün zaten var');
      }
      
      final data = await _supabaseService.create(_tableName, product.toJson());
      return ProductModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Ürün güncelle
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      if (product.id == null) {
        throw Exception('Ürün ID boş olamaz');
      }
      
      // SKU kontrolü (kendi SKU'su hariç)
      final currentProduct = await getProductById(product.id!);
      if (currentProduct.sku != product.sku) {
        final existingProduct = await getProductBySku(product.sku);
        if (existingProduct != null) {
          throw Exception('Bu SKU koduna sahip başka bir ürün zaten var');
        }
      }
      
      final data = await _supabaseService.update(_tableName, product.id!, product.toJson());
      return ProductModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Ürün sil
  Future<void> deleteProduct(String id) async {
    try {
      await _supabaseService.delete(_tableName, id);
    } catch (e) {
      rethrow;
    }
  }
  
  // Kategorileri getir (distinct)
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabaseService.client
          .from(_tableName)
          .select('category')
          .not('category', 'is', null);
      
      // Yinelenen kategorileri kaldır ve alfabetik sırala
      final categories = (response as List)
          .map((item) => item['category'] as String)
          .toSet()
          .toList();
      
      categories.sort();
      return categories;
    } catch (e) {
      return [];
    }
  }
}

@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return ProductRepository(supabaseService);
} 