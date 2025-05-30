import 'package:flutter/material.dart';
import '../widgets/bottom_bar.dart';


// Import semua halaman yang digunakan
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/billing/billing_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notifications/notifcations_screen.dart';
import '../screens/dashboard/admin_dashboard_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/dashboard': (context) => const DashboardScreen(),
    '/history': (context) => const HistoryScreen(),
    '/billing': (context) => const BillingScreen(),
    '/settings': (context) => const SettingsScreen(),
    '/home': (context) => const CustomBottomNav(),
    '/notifications': (context) => const NotificationScreen(),
    '/adminDashboard': (context) => const AdminDashboardScreen(),
  };
}
