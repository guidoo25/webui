import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UserPaymentWhatsAppPanel extends StatefulWidget {
  const UserPaymentWhatsAppPanel({super.key});

  @override
  State<UserPaymentWhatsAppPanel> createState() => _UserPaymentWhatsAppPanelState();
}

class _UserPaymentWhatsAppPanelState extends State<UserPaymentWhatsAppPanel> {
  final String whatsappNumber = '+593962600802';
  final String whatsappMessage = '''Hola, quiero realizar un pago de suscripción en SRI Master.

Por favor proporciona la información de la cuenta bancaria para realizar la transferencia.

Gracias.''';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header estilo Ticket
          _buildHeader(),
          const SizedBox(height: 20),

          // Información principal
          _buildInfoSection(),
          const SizedBox(height: 20),

          // Instrucciones
          _buildInstructions(),
          const SizedBox(height: 20),

          // Botón WhatsApp principal
          _buildWhatsAppButton(),
          const SizedBox(height: 20),

          // Opciones alternativas
          _buildAlternativeOptions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366), // Color WhatsApp
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(Icons.whatshot, color: Color(0xFF25D366), size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTACTA PARA PAGAR',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Escribe a nuestro WhatsApp para realizar tu pago',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'INFORMACIÓN IMPORTANTE',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blue),
              ),
            ],
          ),
    
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conexión directa con el revisor',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber[700]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'PASOS A SEGUIR',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.amber[700]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(1, 'Abre el chat de WhatsApp'),
          _buildInstructionStep(2, 'Solicita los datos bancarios'),
          _buildInstructionStep(3, 'Realiza la transferencia'),
          _buildInstructionStep(4, 'Comparte el comprobante en WhatsApp'),
          _buildInstructionStep(5, 'Tu suscripción será activada'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.amber[700],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0)],
      ),
      child: Material(
        color: const Color(0xFF25D366),
        child: InkWell(
          onTap: _openWhatsApp,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.phone, color: Color(0xFF25D366), size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ABRIR WHATSAPP',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '+593 962 600 802',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.white70,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'OPCIONES ADICIONALES',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOptionButton(
                icon: Icons.copy,
                label: 'COPIAR NÚMERO',
                color: Colors.grey,
                onTap: _copyPhoneNumber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionButton(
                icon: Icons.mail,
                label: 'ENVIAR EMAIL',
                color: Colors.blue,
                onTap: _sendEmail,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final url = 'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(whatsappMessage)}';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir WhatsApp. Asegúrate de tenerlo instalado.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyPhoneNumber() {
    Clipboard.setData(const ClipboardData(text: '+593962600802'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Número copiado al portapapeles', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'soporte@factubot.org',
      queryParameters: {
        'subject': 'Solicitud de información de pago',
        'body': 'Hola, quiero realizar un pago de suscripción en SRI Master.',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
