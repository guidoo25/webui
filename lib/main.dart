import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sri_master/conts/theme.dart';
import 'package:sri_master/routes/app_route.dart';
import 'package:sri_master/services/server_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar configuración del servidor al inicio y preparar refresh periódico
  await ServerConfigService.ensureLoaded();
  // refrescar cada 5 minutos
  ServerConfigService.startPeriodicRefresh(const Duration(minutes: 5));
  
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
    );
  }
}
