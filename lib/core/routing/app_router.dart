import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/data/models/profile_model.dart';
import '../../features/customer_management/presentation/screens/customer_list_screen.dart';
import '../../features/customer_management/presentation/screens/customer_form_screen.dart';
import '../../features/product_management/presentation/screens/product_list_screen.dart';
import '../../features/product_management/presentation/screens/product_form_screen.dart';
import '../../features/warehouse_management/presentation/screens/warehouse_list_screen.dart';
import '../../features/warehouse_management/presentation/screens/warehouse_form_screen.dart';
import '../../features/warehouse_management/presentation/screens/floors_screen.dart';
import '../../features/inventory/presentation/screens/admin_dashboard_screen.dart';
import '../../features/inventory/presentation/screens/employee_dashboard_screen.dart';
import '../../features/inventory/presentation/screens/pending_entry_list_screen.dart';
import '../../features/inventory/presentation/screens/entry_form_screen.dart';
import '../../features/inventory/presentation/screens/dispatch_form_screen.dart';
import '../../features/inventory/presentation/screens/stock_view_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  final authService = ref.watch(authServiceProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Handle auth redirects
      final isLoggedIn = authService.isAuthenticated;
      final isLoginRoute = state.fullPath == AppConstants.routeLogin;
      final isSplashRoute = state.fullPath == '/';
      
      // If we're at the splash screen, let it handle auth checking
      if (isSplashRoute) return null;
      
      // If not logged in, redirect to login unless already at login
      if (!isLoggedIn && !isLoginRoute) return AppConstants.routeLogin;
      
      // If logged in but at login route, redirect to appropriate dashboard
      if (isLoggedIn && isLoginRoute) {
        final userRole = await authService.getCurrentUserRole();
        return userRole == AppConstants.roleAdmin
            ? AppConstants.routeAdminDashboard
            : AppConstants.routeEmployeeDashboard;
      }
      
      // Check role-based access for admin routes
      if (isLoggedIn && !isLoginRoute) {
        final userRole = await authService.getCurrentUserRole();
        final isAdminRoute = state.fullPath!.startsWith(AppConstants.routeAdminDashboard) ||
            state.fullPath == AppConstants.routeCustomers ||
            state.fullPath == AppConstants.routeCustomerForm ||
            state.fullPath == AppConstants.routeWarehouses ||
            state.fullPath == AppConstants.routeWarehouseForm ||
            state.fullPath == AppConstants.routeProducts ||
            state.fullPath == AppConstants.routeProductForm ||
            state.fullPath == AppConstants.routePendingEntries ||
            state.fullPath == AppConstants.routeDispatchForm ||
            state.fullPath == AppConstants.routeReports;
            
        // Redirect employee trying to access admin routes
        if (userRole != AppConstants.roleAdmin && isAdminRoute) {
          return AppConstants.routeEmployeeDashboard;
        }
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeEmployeeDashboard,
        builder: (context, state) => const EmployeeDashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeCustomers,
        builder: (context, state) => const CustomerListScreen(),
      ),
      GoRoute(
        path: AppConstants.routeCustomerForm,
        builder: (context, state) {
          final customerId = state.queryParameters['id'];
          return CustomerFormScreen(customerId: customerId);
        },
      ),
      GoRoute(
        path: AppConstants.routeWarehouses,
        builder: (context, state) => const WarehouseListScreen(),
      ),
      GoRoute(
        path: AppConstants.routeWarehouseForm,
        builder: (context, state) {
          final warehouseId = state.queryParameters['id'];
          return WarehouseFormScreen(warehouseId: warehouseId);
        },
      ),
      GoRoute(
        path: '/warehouse/:warehouseId/floors',
        builder: (context, state) {
          final warehouseId = state.pathParameters['warehouseId']!;
          return FloorsScreen(warehouseId: warehouseId);
        },
      ),
      GoRoute(
        path: AppConstants.routeProducts,
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProductForm,
        builder: (context, state) {
          final productId = state.queryParameters['id'];
          return ProductFormScreen(productId: productId);
        },
      ),
      GoRoute(
        path: AppConstants.routePendingEntries,
        builder: (context, state) => const PendingEntryListScreen(),
      ),
      GoRoute(
        path: AppConstants.routeEntryForm,
        builder: (context, state) => const EntryFormScreen(),
      ),
      GoRoute(
        path: AppConstants.routeDispatchForm,
        builder: (context, state) => const DispatchFormScreen(),
      ),
      GoRoute(
        path: AppConstants.routeStockView,
        builder: (context, state) => const StockViewScreen(),
      ),
      GoRoute(
        path: AppConstants.routeReports,
        builder: (context, state) => const ReportsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
} 