import 'package:flutter/material.dart';
import 'package:sri_master/models/admin_models.dart';
import 'package:sri_master/services/admin_service.dart';
// Asegúrate de que tus importaciones de pantallas siguen existiendo
import 'package:sri_master/screens/admin/admin_users_panel.dart';
import 'package:sri_master/screens/admin/admin_subscription_panel.dart';
import 'package:sri_master/screens/admin/admin_credentials_panel.dart';
import 'package:sri_master/screens/admin/admin_folders_panel.dart';
import 'package:sri_master/screens/admin/admin_payment_panel.dart';
import 'package:sri_master/screens/admin/admin_proofs_panel.dart';
import 'package:sri_master/screens/admin/admin_users_management_panel.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedPanel = -1; // -1 = vista mosaico
  bool _isLoading = true;
  
  // Colores del Tema Offset
  final Color _deskColor = const Color(0xFF3B82F6); // Azul escritorio
  final Color _paperColor = const Color(0xFFFFFFFF);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  // Datos del dashboard
  List<AdminUser> _users = [];
  List<SubscriptionPlan> _plans = [];
  UserSubscription? _mySubscription;
  List<SriCredential> _myCredentials = [];
  List<ComprobanteFolder> _myFolders = [];
  
  // ignore: unused_field
  AdminUser? _selectedUser; 

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AdminService.getUsers(),
        AdminService.getPlans(),
        AdminService.getMySubscription(),
        AdminService.getMyCredentials(),
        AdminService.getMyFolders(),
      ]);

      if (mounted) {
        setState(() {
          _users = results[0] as List<AdminUser>;
          _plans = results[1] as List<SubscriptionPlan>;
          _mySubscription = results[2] as UserSubscription?;
          _myCredentials = results[3] as List<SriCredential>;
          _myFolders = results[4] as List<ComprobanteFolder>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deskColor, // Fondo azul "Escritorio"
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER PERSONALIZADO (Estilo barra de herramientas)
            _buildCustomHeader(),

            // 2. CONTENIDO PRINCIPAL
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(width: 2),
                          boxShadow: const [BoxShadow(offset: Offset(4,4), color: Colors.black)]
                        ),
                        child: const CircularProgressIndicator(color: Colors.black),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _selectedPanel == -1
                          ? _buildMosaicView()
                          : _buildPanelView(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE UI ---

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Colors.black, width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 4), blurRadius: 0)
        ],
      ),
      child: Row(
        children: [
          if (_selectedPanel >= 0) ...[
            // Botón Atras Cuadrado
            InkWell(
              onTap: () => setState(() {
                _selectedPanel = -1;
                _selectedUser = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow[300], // Acento amarillo
                  border: Border.all(width: 2),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Icono y Título
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            _getTitle().toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900, // Extra bold
              fontSize: 18,
              letterSpacing: 1,
              fontFamily: 'Courier', // Toque técnico
            ),
          ),
          const Spacer(),
          
          // Botón Refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 28),
            onPressed: _loadDashboardData,
            tooltip: 'Recargar Datos',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedPanel) {
      case 0: return 'Perfil de Usuario';
      case 1: return 'Plan & Suscripción';
      case 2: return 'Gestión de Credenciales';
      case 3: return 'Archivador de Carpetas';
      case 4: return 'Control de Pagos';
      case 5: return 'Validar Comprobantes';
      default: return 'Panel de Control';
    }
  }

  Widget _buildMosaicView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen rápido tipo "Stickers"
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatSticker(
                label: 'USUARIOS', 
                value: _users.length.toString(), 
                color: const Color(0xFFEF4444) // Rojo
              ),
              const SizedBox(width: 12),
              _buildStatSticker(
                label: 'CREDENCIALES', 
                value: _myCredentials.length.toString(), 
                color: const Color(0xFFF59E0B) // Ambar
              ),
              const SizedBox(width: 12),
              _buildStatSticker(
                label: 'CARPETAS', 
                value: _myFolders.length.toString(), 
                color: const Color(0xFF10B981) // Verde
              ),
              const SizedBox(width: 12),
              _buildStatSticker(
                label: 'DESCARGAS', 
                value: _mySubscription?.usedDownloads.toString() ?? '0', 
                color: const Color(0xFF8B5CF6) // Violeta
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          "ACCESOS DIRECTOS",
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.5,
            fontSize: 14,
            shadows: [Shadow(color: Colors.black, offset: Offset(2,2))]
          ),
        ),
        
        const SizedBox(height: 12),

        // Mosaico de Tarjetas
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Ajustar columnas según ancho
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildOffsetCard(
                    index: 0,
                    icon: Icons.person_outline,
                    title: 'MI PERFIL',
                    subtitle: 'Datos personales',
                    accentColor: const Color(0xFF3B82F6),
                    stats: 'ACTIVO',
                  ),
                  _buildOffsetCard(
                    index: 1,
                    icon: Icons.verified_user_outlined,
                    title: 'SUSCRIPCIÓN',
                    subtitle: _mySubscription?.planName ?? 'Sin plan',
                    accentColor: const Color(0xFF10B981),
                    stats: _mySubscription != null 
                        ? '${_mySubscription!.daysRemaining} DÍAS'
                        : 'INACTIVO',
                  ),
                  _buildOffsetCard(
                    index: 2,
                    icon: Icons.vpn_key_outlined,
                    title: 'CREDENCIALES',
                    subtitle: 'Accesos SRI',
                    accentColor: const Color(0xFFF59E0B),
                    stats: '${_myCredentials.length} CLAVES',
                  ),
                  _buildOffsetCard(
                    index: 3,
                    icon: Icons.folder_open_outlined,
                    title: 'CARPETAS',
                    subtitle: 'Archivos XML/PDF',
                    accentColor: const Color(0xFF8B5CF6),
                    stats: '${_myFolders.length} CARPETAS',
                  ),
                  _buildOffsetCard(
                    index: 4,
                    icon: Icons.receipt_long_outlined,
                    title: 'PAGOS',
                    subtitle: 'Historial',
                    accentColor: const Color(0xFFEF4444),
                    stats: 'VER TODO',
                  ),
                  _buildOffsetCard(
                    index: 5,
                    icon: Icons.verified_user,
                    title: 'COMPROBANTES',
                    subtitle: 'Validar pagos',
                    accentColor: const Color(0xFF06B6D4),
                    stats: 'REVISAR',
                  ),
                  _buildOffsetCard(
                    index: 6,
                    icon: Icons.people_alt,
                    title: 'GESTIÓN USUARIOS',
                    subtitle: 'Suscripciones',
                    accentColor: const Color(0xFF00BCD4),
                    stats: 'ADMINISTRAR',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget para las estadísticas superiores (Estilo Sticker/Etiqueta)
  Widget _buildStatSticker({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, 
            height: 10, 
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(width: 1))
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Courier',
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget para las tarjetas principales (Estilo Carpeta/Expediente)
  Widget _buildOffsetCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required String stats,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPanel = index),
      child: Container(
        decoration: BoxDecoration(
          color: _paperColor,
          border: Border.all(color: _borderColor, width: 3), // Borde grueso
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              offset: const Offset(8, 8), // Sombra offset marcada
              blurRadius: 0, // Sin difuminado (estilo cartoon)
            ),
          ],
        ),
        child: ClipRect(
          child: Stack(
            children: [
              // Barra lateral de color
              Positioned(
                left: 0, top: 0, bottom: 0,
                width: 6,
                child: Container(color: accentColor),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icono superior
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Icon(icon, color: Colors.black, size: 24),
                        ),
                        Icon(Icons.arrow_outward, color: Colors.grey[400]),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Textos
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Badge inferior tipo "Sello"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(0), // Recto
                      ),
                      child: Text(
                        stats,
                        style: TextStyle(
                          fontSize: 11,
                          color: accentColor, // Texto coloreado sobre negro
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelView() {
    // Envolvemos el panel en una "Hoja de Papel" grande para mantener consistencia
    return Container(
      decoration: BoxDecoration(
        color: _paperColor,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(10, 10),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRect( // Asegura que el contenido no se salga de los bordes
        child: _getPanelContent(),
      ),
    );
  }

  Widget _getPanelContent() {
    switch (_selectedPanel) {
      case 0:
        return AdminUsersPanel(
          isProfileView: true,
          onRefresh: _loadDashboardData,
        );
      case 1:
        return AdminSubscriptionPanel(
          subscription: _mySubscription,
          plans: _plans,
          onRefresh: _loadDashboardData,
        );
      case 2:
        return AdminCredentialsPanel(
          users: _users,
          credentials: _myCredentials,
          onRefresh: _loadDashboardData,
        );
      case 3:
        return AdminFoldersPanel(
          folders: _myFolders,
          credentials: _myCredentials,
          onRefresh: _loadDashboardData,
        );
      case 4:
        return AdminPaymentPanel(
          onRefresh: _loadDashboardData,
        );
      case 5:
        return AdminProofsPanel(
          onRefresh: _loadDashboardData,
        );
      case 6:
        return const AdminUsersManagementPanel();
      default:
        return const Center(child: Text('Panel no disponible'));
    }
  }
}