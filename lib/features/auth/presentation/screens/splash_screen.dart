import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2)); // Minimal splash display

    final authService = ref.read(authServiceProvider);
    
    if (!authService.isAuthenticated) {
      // Not logged in, redirect to login
      if (mounted) {
        context.go(AppConstants.routeLogin);
      }
      return;
    }

    // Check user role and redirect to appropriate dashboard
    try {
      final userRole = await authService.getCurrentUserRole();
      
      if (mounted) {
        if (userRole == AppConstants.roleAdmin) {
          context.go(AppConstants.routeAdminDashboard);
        } else {
          context.go(AppConstants.routeEmployeeDashboard);
        }
      }
    } catch (e) {
      // On error, redirect to login
      if (mounted) {
        context.go(AppConstants.routeLogin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'DepoF',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Depo Yönetim Sistemi',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 