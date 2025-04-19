import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Paneli'),
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
            'Yeni Giriş Talebi',
            Icons.add_box,
            Colors.green,
            () => context.go(AppConstants.routeEntryForm),
          ),
          _buildDashboardItem(
            context,
            'Giriş Taleplerim',
            Icons.list_alt,
            Colors.blue,
            () => context.go(AppConstants.routePendingEntries), // Will filter by user in the screen
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
            'Müşteri Listesi',
            Icons.people,
            Colors.purple,
            () => context.go(AppConstants.routeCustomers), // Read-only view for employees
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