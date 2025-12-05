import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sri_master/services/auth_service.dart';
// import 'package:sri_master/screens/file_Screen.dart';
import 'package:sri_master/screens/tabs_sri/index.dart';
import 'package:sri_master/screens/settings_screen.dart';
import 'package:sri_master/screens/descargas_screen.dart';
import 'package:sri_master/screens/admin/admin_dashboard_screen.dart';
import 'package:sri_master/screens/user/user_subscription_panel.dart';
import 'package:sri_master/screens/user/user_payment_whatsapp_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Movido dentro del State para que setState funcione bien
  
  // Opciones de pantallas
  final List<Widget> _screenOptions = [
    Sri_tabs(), 
    DescargasScreen(), 
    UserSubscriptionPanel(),
    UserPaymentWhatsAppPanel(),
    const AdminDashboardScreen(),
    SettingsScreen()
  ];

  // COLORES DEL TEMA (Mismos del Login)
  final Color _bgColor = const Color(0xFF3B82F6); // Azul vibrante
  final Color _paperColor = const Color(0xFFFFFFFF);
  final Color _borderColor = const Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await AuthService.getToken();
      if (token == null) {
        if (mounted) context.goNamed('login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor, // Fondo azul escritorio
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Margen externo
        child: Row(
          children: [
            // 1. SIDEBAR PERSONALIZADO (Estilo Offset)
            SizedBox(
              width: 260, // Ancho fijo del menú
              child: Column(
                children: [
                  _buildLogoArea(),
                  const SizedBox(height: 30),
                  _buildNavItem(icon: Icons.dashboard_customize, label: "Tablero", index: 0),
                  const SizedBox(height: 16),
                  _buildNavItem(icon: Icons.folder_zip, label: "Descargas", index: 1),
                  const SizedBox(height: 16),
                  _buildNavItem(icon: Icons.card_membership, label: "Suscripción", index: 2),
                  const SizedBox(height: 16),
                  _buildNavItem(icon: Icons.payment, label: "Pagos", index: 3),
                  const SizedBox(height: 16),
                  _buildNavItem(icon: Icons.admin_panel_settings, label: "Admin", index: 4),
                  const SizedBox(height: 16),
                  _buildNavItem(icon: Icons.settings_applications, label: "Ajustes", index: 5),
                  
                  const Spacer(),
                  // Botón de salir decorativo
                  _buildLogoutButton(),
                ],
              ),
            ),

            const SizedBox(width: 20), // Espacio entre menú y contenido

            // 2. ÁREA DE CONTENIDO PRINCIPAL (La "Hoja" de trabajo)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _paperColor,
                  border: Border.all(color: _borderColor, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black, // Sombra dura
                      offset: Offset(8, 8),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRect(
                  child: _screenOptions[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE ESTILO ---

  Widget _buildLogoArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black, // Caja negra sólida
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(4, 4), blurRadius: 0)
        ]
      ),
      child: Row(
        children: const [
          Icon(Icons.pie_chart, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            "SRI MASTER",
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w900, 
              fontSize: 18,
              letterSpacing: 1
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            // Si está seleccionado: Fondo Blanco, Borde Negro. 
            // Si NO está seleccionado: Fondo Azul Oscuro (transparente), Texto Blanco.
            color: isSelected ? _paperColor : Colors.black.withOpacity(0.1),
            border: Border.all(
              color: isSelected ? _borderColor : Colors.transparent, 
              width: 2
            ),
            boxShadow: isSelected 
              ? [const BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)]
              : [], // Sin sombra si no está seleccionado
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                color: isSelected ? Colors.black : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () {
        AuthService.logout(); // Asumiendo que tienes un método logout
        context.goNamed('login');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
             BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("SALIR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}