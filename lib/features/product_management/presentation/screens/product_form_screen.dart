import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../data/models/product_model.dart';
import '../providers/product_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({Key? key, this.productId}) : super(key: key);

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _isEdit = false;
  ProductModel? _initialProduct;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.productId != null;
  }

  @override
  Widget build(BuildContext context) {
    // Düzenleme modunda, ilk önce ürün bilgilerini getir
    if (_isEdit && _initialProduct == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Ürün Düzenle' : 'Yeni Ürün'),
        ),
        body: ref.watch(productProvider(widget.productId!)).when(
              data: (product) {
                // Alınan ürün bilgilerini forma doldurmak için sakla
                _initialProduct = product;
                return _buildForm();
              },
              error: (error, stackTrace) => AppErrorWidget(
                error: error.toString(),
                onRetry: () => ref.refresh(productProvider(widget.productId!)),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
      );
    }

    // Ekleme modu veya düzenleme bilgileri alındıysa formu göster
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ürün Düzenle' : 'Yeni Ürün'),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    // Kategori listesini getir (düzenleme için)
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: FormBuilder(
        key: _formKey,
        initialValue: _isEdit
            ? {
                'sku': _initialProduct?.sku ?? '',
                'name': _initialProduct?.name ?? '',
                'category': _initialProduct?.category ?? '',
                'unit': _initialProduct?.unit ?? '',
                'minStockLevel': _initialProduct?.minStockLevel?.toString() ?? '',
              }
            : {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SKU
            FormBuilderTextField(
              name: 'sku',
              decoration: const InputDecoration(
                labelText: 'SKU/Barkod*',
                border: OutlineInputBorder(),
                helperText: 'Benzersiz ürün tanımlayıcı kod',
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'SKU alanı zorunludur'),
              ]),
              readOnly: _isEdit, // Düzenleme modunda SKU değiştirilemez
            ),
            const SizedBox(height: 16),
            
            // Ürün Adı
            FormBuilderTextField(
              name: 'name',
              decoration: const InputDecoration(
                labelText: 'Ürün Adı*',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Ürün adı zorunludur'),
              ]),
            ),
            const SizedBox(height: 16),
            
            // Kategori
            FormBuilderTextField(
              name: 'category',
              decoration: InputDecoration(
                labelText: 'Kategori',
                border: const OutlineInputBorder(),
                suffixIcon: categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) return null;
                    return IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: () => _showCategoryPicker(context, categories),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Birim
            FormBuilderTextField(
              name: 'unit',
              decoration: const InputDecoration(
                labelText: 'Birim*',
                border: OutlineInputBorder(),
                helperText: 'Ölçü birimi (kg, adet, ton, vb.)',
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Birim zorunludur'),
              ]),
            ),
            const SizedBox(height: 16),
            
            // Minimum Stok Seviyesi
            FormBuilderTextField(
              name: 'minStockLevel',
              decoration: const InputDecoration(
                labelText: 'Minimum Stok Seviyesi',
                border: OutlineInputBorder(),
                helperText: 'Uyarı gösterilecek minimum stok miktarı',
              ),
              keyboardType: TextInputType.number,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.numeric(errorText: 'Sayısal değer giriniz'),
                FormBuilderValidators.min(0, errorText: 'Negatif değer girilemez'),
              ]),
            ),
            const SizedBox(height: 24),
            
            // Form Butonları
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isEdit ? 'Güncelle' : 'Kaydet'),
              ),
            ),
            const SizedBox(height: 16),
            
            // İptal Butonu
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => context.go(AppConstants.routeProducts),
                child: const Text('İptal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, List<String> categories) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Seçin'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(categories[index]),
                onTap: () {
                  _formKey.currentState?.fields['category']?.didChange(categories[index]);
                  Navigator.pop(context);
                },
              );
            },
          ),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;
        
        // Form verilerinden ProductModel oluştur
        final product = ProductModel(
          id: _isEdit ? _initialProduct?.id : null,
          sku: formData['sku'],
          name: formData['name'],
          category: formData['category'],
          unit: formData['unit'],
          minStockLevel: formData['minStockLevel'] != null && formData['minStockLevel'].isNotEmpty
              ? double.tryParse(formData['minStockLevel'])
              : null,
        );
        
        // Kaydet veya güncelle
        if (_isEdit) {
          await ref.read(productNotifierProvider.notifier).updateProduct(product);
        } else {
          await ref.read(productNotifierProvider.notifier).createProduct(product);
        }
        
        if (!mounted) return;
        
        // Başarı mesajı göster ve listeye dön
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Ürün güncellendi' : 'Ürün oluşturuldu'),
          ),
        );
        
        context.go(AppConstants.routeProducts);
      } catch (e) {
        // Hata göster
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem başarısız: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 