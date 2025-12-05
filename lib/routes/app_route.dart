import 'package:go_router/go_router.dart';
import 'package:sri_master/screens/home.dart';
import 'package:sri_master/screens/login_screen.dart';
import 'package:sri_master/screens/admin/admin_dashboard_screen.dart';

final appRouter = GoRouter(initialLocation: '/login', routes: [
  GoRoute(
    path: '/',
    name: 'inicio',
    builder: (context, state) => HomeScreen(),
  ),
  GoRoute(
    path: '/login',
    name: 'login',
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: '/admin',
    name: 'admin',
    builder: (context, state) => const AdminDashboardScreen(),
  ),
]);
