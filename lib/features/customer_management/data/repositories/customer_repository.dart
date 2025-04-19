import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/customer_model.dart';

part 'customer_repository.g.dart';

class CustomerRepository {
  final SupabaseService _supabaseService;
  static const String _tableName = 'customers';

  CustomerRepository(this._supabaseService);

  // Get all customers
  Future<List<CustomerModel>> getAllCustomers({
    String? searchTerm,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
      final query = _supabaseService.client.from(_tableName).select();
      
      // Add search if provided
      if (searchTerm != null && searchTerm.isNotEmpty) {
        query.or('first_name.ilike.%${searchTerm}%,last_name.ilike.%${searchTerm}%,phone.ilike.%${searchTerm}%');
      }
      
      // Add sorting if provided
      if (sortBy != null) {
        query.order(sortBy, ascending: ascending);
      } else {
        query.order('first_name', ascending: true);
      }
      
      final data = await query;
      
      // Map the response to CustomerModel objects
      return data.map((customer) => CustomerModel.fromJson(customer)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get customer by ID
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final data = await _supabaseService.readById(_tableName, id);
      return CustomerModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Create a new customer
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    try {
      final data = await _supabaseService.create(_tableName, customer.toJson());
      return CustomerModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Update an existing customer
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      if (customer.id == null) {
        throw Exception('Customer ID cannot be null');
      }
      
      final data = await _supabaseService.update(_tableName, customer.id!, customer.toJson());
      return CustomerModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a customer
  Future<void> deleteCustomer(String id) async {
    try {
      await _supabaseService.delete(_tableName, id);
    } catch (e) {
      rethrow;
    }
  }
  
  // Search customers by name or other fields
  Future<List<CustomerModel>> searchCustomers(String searchTerm) async {
    try {
      final data = await _supabaseService.client
          .from(_tableName)
          .select()
          .or('first_name.ilike.%${searchTerm}%,last_name.ilike.%${searchTerm}%')
          .order('first_name', ascending: true);
      
      return data.map((customer) => CustomerModel.fromJson(customer)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
CustomerRepository customerRepository(CustomerRepositoryRef ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return CustomerRepository(supabaseService);
} 