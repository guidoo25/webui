import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sri_master/services/server_config_service.dart';
import 'package:sri_master/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  // COLORES: Azul "Blueprint" (Plano técnico)
  final Color _bgColor = const Color(0xFF3B82F6); // Azul vibrante moderno
  final Color _paperColor = const Color(0xFFEFF6FF); // Blanco azulado

  late AnimationController _animController;
  bool _loading = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Animación para que el fondo se mueva suavemente (respiración)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _prepare();
  }

  Future<void> _prepare() async {
    await ServerConfigService.ensureLoaded();
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _submit() async {
    if (!_ready) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ok = await AuthService.login(
        username: _userController.text.trim(), password: _passController.text);
    
    setState(() => _loading = false);
    if (ok) {
      if (mounted) context.goNamed('inicio');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. FONDO DE PAPELES Y CARPETAS (Generado con código, no descarga nada)
          ..._buildFloatingBackgroundIcons(context),

          // 2. CAPA SEMITRANSPARENTE (Para que el texto se lea bien)
          Positioned.fill(
            child: Container(color: _bgColor.withOpacity(0.85)),
          ),

          // 3. FORMULARIO CENTRADO
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO SIMPLE (imagen local)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.white24, offset: Offset(4, 4))
                        ]
                      ),
                      child: Image.asset(
                        'lib/assets/logo.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // TARJETA ESTILO "OFFSET" (Neobrutalismo)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 3), // Borde grueso
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black, // Sombra dura
                            offset: Offset(8, 8),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                      child: !_ready
                          ? const Center(child: CircularProgressIndicator(color: Colors.black))
                          : Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "INICIAR SESIÓN",
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Courier', // Fuente tipo máquina de escribir si está disponible
                                      letterSpacing: -0.5,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Ingresa tus credenciales para administrar tus documentos.",
                                    style: TextStyle(color: Colors.grey[600], height: 1.4),
                                  ),
                                  const SizedBox(height: 30),

                                  // INPUT USUARIO
                                  _buildPaperInput(_userController, "Usuario", Icons.person),
                                  const SizedBox(height: 20),
                                  // INPUT PASSWORD
                                  _buildPaperInput(_passController, "Contraseña", Icons.key, isPass: true),
                                  
                                  const SizedBox(height: 30),

                                  // BOTÓN NEGRO SOLIDO
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero, // Cuadrado
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 0),
                                      ),
                                      child: _loading 
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text(
                                            "ACCEDER AL SISTEMA",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  // Genera iconos dispersos que flotan suavemente
  List<Widget> _buildFloatingBackgroundIcons(BuildContext context) {
    // Lista de iconos "administrativos"
    final icons = [
      Icons.receipt_long,
      Icons.folder_copy,
      Icons.analytics,
      Icons.pie_chart,
      Icons.description,
      Icons.calculate,
      Icons.table_chart,
      Icons.verified,
    ];

    final random = math.Random(42); // Seed fijo para que no cambien al repintar
    final size = MediaQuery.of(context).size;

    return List.generate(15, (index) {
      final icon = icons[index % icons.length];
      final top = random.nextDouble() * size.height;
      final left = random.nextDouble() * size.width;
      final angle = random.nextDouble() * 0.5 - 0.25; // Rotación leve
      final iconSize = random.nextDouble() * 60 + 40; // Tamaño entre 40 y 100

      return Positioned(
        top: top,
        left: left,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            // Movimiento suave arriba/abajo
            final offset = math.sin(_animController.value * 2 * math.pi + index) * 15;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Transform.rotate(
                angle: angle,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: Colors.white.withOpacity(0.15), // Transparencia sutil
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildPaperInput(TextEditingController c, String label, IconData icon, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6), // Gris papel
            border: Border.all(color: Colors.black, width: 2), // Borde estilo cómic/papel
          ),
          child: TextFormField(
            controller: c,
            obscureText: isPass,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.black),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}