import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        childAspectRatio: 1.2,
        children: [
          _buildDashboardItem(
            context,
            'Müşteriler',
            Icons.people,
            Colors.blue,
            () => context.go(AppConstants.routeCustomers),
          ),
          _buildDashboardItem(
            context,
            'Ürünler',
            Icons.inventory_2,
            Colors.green,
            () => context.go(AppConstants.routeProducts),
          ),
          _buildDashboardItem(
            context,
            'Depolar',
            Icons.warehouse,
            Colors.orange,
            () => context.go(AppConstants.routeWarehouses),
          ),
          _buildDashboardItem(
            context,
            'Giriş Onayları',
            Icons.approval,
            Colors.purple,
            () => context.go(AppConstants.routePendingEntries),
          ),
          _buildDashboardItem(
            context,
            'Stok Durumu',
            Icons.bar_chart,
            Colors.teal,
            () => context.go(AppConstants.routeStockView),
          ),
          _buildDashboardItem(
            context,
            'Ürün Çıkışı',
            Icons.exit_to_app,
            Colors.red,
            () => context.go(AppConstants.routeDispatchForm),
          ),
          _buildDashboardItem(
            context,
            'Raporlar',
            Icons.analytics,
            Colors.indigo,
            () => context.go(AppConstants.routeReports),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) {
        context.go(AppConstants.routeLogin);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılamadı: ${e.toString()}')),
        );
      }
    }
  }
} 