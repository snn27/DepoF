import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

part 'product_provider.g.dart';

// Tüm ürünleri getiren provider
@riverpod
Future<List<ProductModel>> products(ProductsRef ref, {
  String? searchTerm,
  String? sortBy,
  bool ascending = true,
  String? category,
}) {
  final productRepository = ref.watch(productRepositoryProvider);
  return productRepository.getAllProducts(
    searchTerm: searchTerm,
    sortBy: sortBy,
    ascending: ascending,
    category: category,
  );
}

// ID'ye göre ürün getiren provider
@riverpod
Future<ProductModel> product(ProductRef ref, String id) {
  final productRepository = ref.watch(productRepositoryProvider);
  return productRepository.getProductById(id);
}

// Kategorileri getiren provider
@riverpod
Future<List<String>> productCategories(ProductCategoriesRef ref) {
  final productRepository = ref.watch(productRepositoryProvider);
  return productRepository.getCategories();
}

// Ürün işlemleri için notifier provider
@riverpod
class ProductNotifier extends _$ProductNotifier {
  @override
  FutureOr<void> build() {
    // Başlangıç durumu boş
    return;
  }
  
  // Ürün oluşturma
  Future<ProductModel> createProduct(ProductModel product) async {
    state = const AsyncLoading();
    
    try {
      final productRepository = ref.read(productRepositoryProvider);
      final result = await productRepository.createProduct(product);
      
      // Ürün listesini güncelle
      ref.invalidate(productsProvider);
      
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
  
  // Ürün güncelleme
  Future<ProductModel> updateProduct(ProductModel product) async {
    state = const AsyncLoading();
    
    try {
      final productRepository = ref.read(productRepositoryProvider);
      final result = await productRepository.updateProduct(product);
      
      // Ürün listesini ve spesifik ürünü güncelle
      ref.invalidate(productsProvider);
      if (product.id != null) {
        ref.invalidate(productProvider(product.id!));
      }
      
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
  
  // Ürün silme
  Future<void> deleteProduct(String id) async {
    state = const AsyncLoading();
    
    try {
      final productRepository = ref.read(productRepositoryProvider);
      await productRepository.deleteProduct(id);
      
      // Ürün listesini güncelle
      ref.invalidate(productsProvider);
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
} 