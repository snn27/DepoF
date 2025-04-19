class AppConstants {
  // Supabase Credentials - Buraya gerçek Supabase bilgilerinizi ekleyin
  static const String supabaseUrl = 'https://uyrzvuhewxylelmhkwzc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV5cnp2dWhld3h5bGVsbWhrd3pjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4OTUwNjUsImV4cCI6MjA2MDQ3MTA2NX0.MSaoEatkW3qRdcCaS1MsVrNd6jIXonR0uPo2o5dDx8w';

  // App Info
  static const String appName = 'DepoF';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';

  // Role Constants
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'employee';
  
  // Routes
  static const String routeLogin = '/login';
  static const String routeAdminDashboard = '/admin';
  static const String routeEmployeeDashboard = '/employee';
  static const String routeCustomers = '/customers';
  static const String routeCustomerForm = '/customer/form';
  static const String routeCustomerDetail = '/customer/detail';
  static const String routeWarehouses = '/warehouses';
  static const String routeWarehouseForm = '/warehouse/form';
  static const String routeWarehouseDetail = '/warehouse/detail';
  static const String routeProducts = '/products';
  static const String routeProductForm = '/product/form';
  static const String routeProductDetail = '/product/detail';
  static const String routePendingEntries = '/pending-entries';
  static const String routeEntryForm = '/entry/form';
  static const String routeDispatchForm = '/dispatch/form';
  static const String routeStockView = '/stock';
  static const String routeReports = '/reports';
} 