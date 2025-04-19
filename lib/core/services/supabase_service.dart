import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

part 'supabase_service.g.dart';

class DatabaseException implements Exception {
  final String message;
  final dynamic error;
  
  DatabaseException(this.message, [this.error]);
  
  @override
  String toString() => error != null 
    ? '$message (Error: ${error.toString()})' 
    : message;
}

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  SupabaseClient get client => _supabase;
  
  // Generic functions for CRUD operations
  
  // Create a record in the specified table
  Future<Map<String, dynamic>> create(String table, Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from(table)
          .insert(data)
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error creating $table: ${e.toString()}');
      throw DatabaseException('Failed to create record in $table', e);
    }
  }
  
  // Read all records from the specified table
  Future<List<Map<String, dynamic>>> readAll(String table, {
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
    List<String>? columns,
  }) async {
    try {
      var query = _supabase.from(table).select(columns != null ? columns.join(',') : '*');
      
      if (orderBy != null) {
        query = ascending 
            ? query.order(orderBy, ascending: true)
            : query.order(orderBy, ascending: false);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error reading from $table: ${e.toString()}');
      throw DatabaseException('Failed to read records from $table', e);
    }
  }
  
  // Read a single record by ID
  Future<Map<String, dynamic>> readById(String table, String id, {List<String>? columns}) async {
    try {
      final response = await _supabase
          .from(table)
          .select(columns != null ? columns.join(',') : '*')
          .eq('id', id)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error reading $table by id: ${e.toString()}');
      throw DatabaseException('Failed to read record from $table with id: $id', e);
    }
  }
  
  // Update a record
  Future<Map<String, dynamic>> update(String table, String id, Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error updating $table: ${e.toString()}');
      throw DatabaseException('Failed to update record in $table', e);
    }
  }
  
  // Delete a record
  Future<void> delete(String table, String id) async {
    try {
      await _supabase
          .from(table)
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Error deleting from $table: ${e.toString()}');
      throw DatabaseException('Failed to delete record from $table', e);
    }
  }
  
  // Execute a custom RPC function
  Future<dynamic> rpc(String function, {Map<String, dynamic>? params}) async {
    try {
      final response = await _supabase.rpc(function, params: params);
      return response;
    } catch (e) {
      debugPrint('Error executing RPC $function: ${e.toString()}');
      throw DatabaseException('Failed to execute RPC function: $function', e);
    }
  }
  
  // Query with filters
  Future<List<Map<String, dynamic>>> query(String table, {
    required Map<String, dynamic> filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
    List<String>? columns,
  }) async {
    try {
      var query = _supabase.from(table).select(columns != null ? columns.join(',') : '*');
      
      // Apply all filters dynamically
      filters.forEach((field, value) {
        query = query.eq(field, value);
      });
      
      if (orderBy != null) {
        query = ascending 
            ? query.order(orderBy, ascending: true)
            : query.order(orderBy, ascending: false);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error querying $table: ${e.toString()}');
      throw DatabaseException('Failed to query records from $table', e);
    }
  }
  
  // Stream changes to a table using Supabase Realtime
  Stream<List<Map<String, dynamic>>> streamTable(String table, {String? foreignKey, String? foreignKeyValue}) {
    // Need to filter to improve performance if foreignKey is provided
    final filter = foreignKey != null && foreignKeyValue != null
        ? 'eq(${foreignKey},${foreignKeyValue})'
        : '*';
    
    return _supabase
        .from(table)
        .stream(primaryKey: ['id'])
        .map((event) => List<Map<String, dynamic>>.from(event));
  }
}

@riverpod
SupabaseService supabaseService(SupabaseServiceRef ref) {
  return SupabaseService();
} 