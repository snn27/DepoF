import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

part 'customer_provider.g.dart';

// Provider to fetch all customers
@riverpod
Future<List<CustomerModel>> customers(CustomersRef ref, {
  String? searchTerm,
  String? sortBy,
  bool ascending = true,
}) {
  final customerRepository = ref.watch(customerRepositoryProvider);
  return customerRepository.getAllCustomers(
    searchTerm: searchTerm,
    sortBy: sortBy,
    ascending: ascending,
  );
}

// Provider to fetch a single customer by ID
@riverpod
Future<CustomerModel> customer(CustomerRef ref, String id) {
  final customerRepository = ref.watch(customerRepositoryProvider);
  return customerRepository.getCustomerById(id);
}

// Provider for performing customer operations (create, update, delete)
@riverpod
class CustomerNotifier extends _$CustomerNotifier {
  @override
  FutureOr<void> build() {
    // Initial state is empty/void
    return;
  }
  
  // Create a customer
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    state = const AsyncLoading();
    
    try {
      final customerRepository = ref.read(customerRepositoryProvider);
      final result = await customerRepository.createCustomer(customer);
      
      // Refresh the customers list
      ref.invalidate(customersProvider);
      
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
  
  // Update a customer
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    state = const AsyncLoading();
    
    try {
      final customerRepository = ref.read(customerRepositoryProvider);
      final result = await customerRepository.updateCustomer(customer);
      
      // Refresh the customers list and the specific customer
      ref.invalidate(customersProvider);
      if (customer.id != null) {
        ref.invalidate(customerProvider(customer.id!));
      }
      
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
  
  // Delete a customer
  Future<void> deleteCustomer(String id) async {
    state = const AsyncLoading();
    
    try {
      final customerRepository = ref.read(customerRepositoryProvider);
      await customerRepository.deleteCustomer(id);
      
      // Refresh the customers list
      ref.invalidate(customersProvider);
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
} 