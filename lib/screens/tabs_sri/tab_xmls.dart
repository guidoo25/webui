import 'package:flutter/material.dart';
import 'package:sri_master/services/queue_service.dart';
import 'package:sri_master/widgets/queue_widgets.dart';
import 'package:sri_master/widgets/sri_credential_form.dart';

class xmls_screen extends StatefulWidget {
  const xmls_screen({super.key});

  @override
  State<xmls_screen> createState() => _xmls_screenState();
}

class _xmls_screenState extends State<xmls_screen> {
  final GlobalKey<QueuePanelState> _queuePanelKey = GlobalKey();
  final GlobalKey<SriCredentialFormState> _formKey = GlobalKey();

  Future<void> _handleFormSubmit(String ruc, String password, String? ciAdicional, String year, String month) async {
    final response = await QueueService.startDownload(
      username: ruc,
      password: password,
      year: year,
      month: month,
      ciadicional: ciAdicional ?? '',
    );
    
    if (mounted) {
      // Mostrar diálogo con resultado
      showDialog(
        context: context,
        builder: (context) => DownloadResultDialog(response: response),
      );
      
      // Refrescar la cola
      _queuePanelKey.currentState?.loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Formulario con selector de credenciales
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SriCredentialForm(
                key: _formKey,
                onSubmit: _handleFormSubmit,
                showSaveCredential: true,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Panel de cola
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: QueuePanel(
                key: _queuePanelKey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
