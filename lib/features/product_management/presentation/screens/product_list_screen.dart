import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/models/product_model.dart';
import '../providers/product_provider.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String _sortBy = 'name';
  bool _ascending = true;
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String value) {
    setState(() {
      _searchTerm = value;
    });
  }

  void _changeSorting(String? field) {
    if (field == null) return;
    
    setState(() {
      if (_sortBy == field) {
        // Sıralama yönünü değiştir
        _ascending = !_ascending;
      } else {
        // Yeni sıralama alanı, varsayılan olarak artan sıralı
        _sortBy = field;
        _ascending = true;
      }
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(
      searchTerm: _searchTerm,
      sortBy: _sortBy,
      ascending: _ascending,
      category: _selectedCategory,
    ));
    
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final isAdmin = ref.watch(authServiceProvider).currentUser != null; // Basit kontrol için

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showSortingOptions(context),
          ),
          if (_selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => _selectCategory(null),
              tooltip: 'Kategori filtresini kaldır',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Ürün Ara (İsim veya SKU)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _performSearch,
            ),
          ),
          
          // Kategori filtreleri
          SizedBox(
            height: 50,
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) return const SizedBox.shrink();
                
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Tümü'),
                        selected: _selectedCategory == null,
                        onSelected: (_) => _selectCategory(null),
                      ),
                    ),
                    ...categories.map((category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) => _selectCategory(category),
                      ),
                    )),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          
          Expanded(
            child: productsAsync.when(
              data: (products) => _buildProductList(products, isAdmin),
              error: (error, stackTrace) => AppErrorWidget(
                error: error.toString(),
                onRetry: () => ref.refresh(productsProvider(
                  searchTerm: _searchTerm,
                  sortBy: _sortBy,
                  ascending: _ascending,
                  category: _selectedCategory,
                )),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.go(AppConstants.routeProductForm),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProductList(List<ProductModel> products, bool isAdmin) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Ürün bulunamadı',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        
        return ListTile(
          title: Text(product.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SKU: ${product.sku}'),
              if (product.category != null)
                Text('Kategori: ${product.category}'),
            ],
          ),
          trailing: isAdmin
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.go(
                        AppConstants.routeProductForm,
                        queryParameters: {'id': product.id},
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(context, product),
                    ),
                  ],
                )
              : Text('Birim: ${product.unit}'),
          onTap: () => context.go(
            AppConstants.routeProductForm,
            queryParameters: {'id': product.id},
          ),
        );
      },
    );
  }

  void _showSortingOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sıralama Seçenekleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('İsme Göre'),
              value: 'name',
              groupValue: _sortBy,
              onChanged: (value) {
                _changeSorting(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('SKU\'ya Göre'),
              value: 'sku',
              groupValue: _sortBy,
              onChanged: (value) {
                _changeSorting(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Kategoriye Göre'),
              value: 'category',
              groupValue: _sortBy,
              onChanged: (value) {
                _changeSorting(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Eklenme Tarihine Göre'),
              value: 'created_at',
              groupValue: _sortBy,
              onChanged: (value) {
                _changeSorting(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürün Sil'),
        content: Text(
          'Ürün "${product.name}" silinecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                if (product.id != null) {
                  await ref.read(productNotifierProvider.notifier).deleteProduct(product.id!);
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ürün başarıyla silindi')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Silme işlemi başarısız: ${e.toString()}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
} 