import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../../features/auth/data/models/profile_model.dart';

part 'auth_service.g.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;
  
  // Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Login with email and password
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw AuthException('Failed to sign in');
      }
      
      return response.user!;
    } catch (e) {
      throw AuthException('Authentication failed: ${e.toString()}');
    }
  }
  
  // Register a new user
  Future<User> signUpWithEmailAndPassword(String email, String password, String fullName) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );
      
      if (response.user == null) {
        throw AuthException('Failed to sign up');
      }
      
      // Note: The profile creation will be handled by the database trigger
      
      return response.user!;
    } catch (e) {
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }
  
  // Get user profile with role
  Future<ProfileModel> getUserProfile() async {
    try {
      final userId = currentUser?.id;
      
      if (userId == null) {
        throw AuthException('User not authenticated');
      }
      
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();
      
      return ProfileModel.fromJson(response);
    } catch (e) {
      throw AuthException('Failed to get user profile: ${e.toString()}');
    }
  }
  
  // Get current user role (admin or employee)
  Future<String> getCurrentUserRole() async {
    try {
      final profile = await getUserProfile();
      return profile.role;
    } catch (e) {
      debugPrint('Error getting user role: ${e.toString()}');
      return AppConstants.roleEmployee; // Default to employee on error
    }
  }
  
  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role == AppConstants.roleAdmin;
  }
}

@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
} 