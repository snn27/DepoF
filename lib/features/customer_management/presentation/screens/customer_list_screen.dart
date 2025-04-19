import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../data/models/customer_model.dart';
import '../providers/customer_provider.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String _sortBy = 'first_name';
  bool _ascending = true;

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
        // Toggle sort direction
        _ascending = !_ascending;
      } else {
        // New sort field, default to ascending
        _sortBy = field;
        _ascending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider(
      searchTerm: _searchTerm,
      sortBy: _sortBy,
      ascending: _ascending,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showSortingOptions(context),
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
                labelText: 'Müşteri Ara',
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
          Expanded(
            child: customersAsync.when(
              data: (customers) => _buildCustomerList(customers),
              error: (error, stackTrace) => AppErrorWidget(
                error: error.toString(),
                onRetry: () => ref.refresh(customersProvider(
                  searchTerm: _searchTerm,
                  sortBy: _sortBy,
                  ascending: _ascending,
                )),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppConstants.routeCustomerForm),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCustomerList(List<CustomerModel> customers) {
    if (customers.isEmpty) {
      return const Center(
        child: Text(
          'Müşteri bulunamadı',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        
        return ListTile(
          title: Text('${customer.firstName} ${customer.lastName}'),
          subtitle: customer.phone != null
              ? Text(customer.phone!)
              : const Text('Telefon bilgisi yok'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go(
                  AppConstants.routeCustomerForm,
                  queryParameters: {'id': customer.id},
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context, customer),
              ),
            ],
          ),
          onTap: () => context.go(
            AppConstants.routeCustomerForm,
            queryParameters: {'id': customer.id},
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
              value: 'first_name',
              groupValue: _sortBy,
              onChanged: (value) {
                _changeSorting(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Soyada Göre'),
              value: 'last_name',
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

  void _showDeleteConfirmation(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteri Sil'),
        content: Text(
          'Müşteri "${customer.firstName} ${customer.lastName}" silinecek. Emin misiniz?',
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
                if (customer.id != null) {
                  await ref.read(customerNotifierProvider.notifier).deleteCustomer(customer.id!);
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Müşteri başarıyla silindi')),
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