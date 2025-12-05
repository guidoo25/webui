import 'package:flutter/material.dart';
import 'package:sri_master/conts/enviroments.dart';
import 'package:sri_master/services/server_config_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _isPinging = false;
  bool? _serverResponding;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    setState(() => _isLoading = true);
    
    await ServerConfigService.fetchServerConfig();
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      // Verificar que el servidor responda
      if (ServerConfigService.status == ServerStatus.online) {
        _pingApiServer();
      }
    }
  }

  Future<void> _pingApiServer() async {
    setState(() {
      _isPinging = true;
      _serverResponding = null;
    });
    
    final isAlive = await ServerConfigService.pingServer();
    
    if (mounted) {
      setState(() {
        _isPinging = false;
        _serverResponding = isAlive;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D47A1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.settings, size: 32, color: Color(0xFF0D47A1)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuración',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Estado del servidor',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 2),
                  const SizedBox(height: 24),

                  // Estado del servidor de configuración
                  _buildConfigServerStatus(),
                  
                  const SizedBox(height: 20),

                  // Estado del servidor API
                  if (ServerConfigService.status == ServerStatus.online)
                    _buildApiServerStatus(),

                  const SizedBox(height: 24),

                  // Información del servidor
                  if (ServerConfigService.currentConfig != null)
                    _buildServerInfo(),

                  const SizedBox(height: 24),

                  // Botón de reconexión
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _checkServer,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_isLoading ? 'Verificando...' : 'Reconectar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigServerStatus() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (ServerConfigService.status) {
      case ServerStatus.loading:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        statusText = 'Conectando...';
        statusDescription = 'Obteniendo configuración del servidor';
        break;
      case ServerStatus.online:
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done;
        statusText = 'Configuración Obtenida';
        statusDescription = 'Servidor de configuración respondió correctamente';
        break;
      case ServerStatus.offline:
        statusColor = Colors.orange;
        statusIcon = Icons.cloud_off;
        statusText = 'Sin Conexión';
        statusDescription = ServerConfigService.errorMessage ?? 'No se pudo conectar';
        break;
      case ServerStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusText = 'Error';
        statusDescription = ServerConfigService.errorMessage ?? 'Error desconocido';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Desconocido';
        statusDescription = 'Estado no verificado';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                if (ServerConfigService.lastCheck != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Última verificación: ${_formatTime(ServerConfigService.lastCheck!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiServerStatus() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (_isPinging) {
      statusColor = Colors.blue;
      statusIcon = Icons.sync;
      statusText = 'Verificando API...';
    } else if (_serverResponding == true) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'API Respondiendo';
    } else if (_serverResponding == false) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
      statusText = 'API No Responde';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
      statusText = 'API Sin Verificar';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          if (!_isPinging)
            TextButton.icon(
              onPressed: _pingApiServer,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Ping'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0D47A1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServerInfo() {
    final config = ServerConfigService.currentConfig!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF0D47A1)),
              SizedBox(width: 8),
              Text(
                'Información del Servidor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Nombre', config.name),
          _buildInfoRow('Host', config.host),
          _buildInfoRow('Puerto', config.port.toString()),
          _buildInfoRow('URL Base', Enviroments.apiurl),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
