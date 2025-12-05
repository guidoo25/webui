import 'package:flutter/material.dart';
import 'package:sri_master/services/queue_service.dart';

/// Widget para mostrar el resultado de iniciar una descarga
class DownloadResultDialog extends StatelessWidget {
  final StartDownloadResponse response;

  const DownloadResultDialog({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final isSuccess = response.success;
    final isProcessing = response.status == 'processing';
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isSuccess 
                    ? Colors.green.withOpacity(0.1)
                    : isProcessing 
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess 
                    ? Icons.check_circle_outline
                    : isProcessing 
                        ? Icons.hourglass_top
                        : Icons.error_outline,
                size: 40,
                color: isSuccess 
                    ? Colors.green 
                    : isProcessing 
                        ? Colors.orange 
                        : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            
            // Título
            Text(
              isSuccess 
                  ? '¡Tarea Agregada!' 
                  : isProcessing 
                      ? 'Tarea en Proceso'
                      : 'Error',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Mensaje
            Text(
              response.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            
            // Detalles de la tarea
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('ID Tarea', response.taskId),
                  const Divider(height: 16),
                  _buildDetailRow('Usuario', response.username),
                  const Divider(height: 16),
                  _buildDetailRow('Período', '${response.month} ${response.year}'),
                  const Divider(height: 16),
                  _buildDetailRow('Posición', response.positionText),
                  const Divider(height: 16),
                  _buildDetailRow('Estado', _getStatusText(response.status)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Botón cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'queued':
        return '🟡 En cola';
      case 'processing':
        return '🔵 Procesando';
      case 'completed':
        return '🟢 Completado';
      case 'failed':
        return '🔴 Error';
      case 'cancelled':
        return '⚪ Cancelado';
      default:
        return status;
    }
  }
}

/// Widget para mostrar una tarjeta de tarea en cola
class QueueTaskCard extends StatelessWidget {
  final QueueTask task;
  final VoidCallback? onCancel;
  final VoidCallback? onRefresh;

  const QueueTaskCard({
    super.key,
    required this.task,
    this.onCancel,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildStatusBadge(),
                const Spacer(),
                if (task.position != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${task.position}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Info
            Text(
              '${task.month} ${task.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Usuario: ${task.username}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            
            // Progress bar si está procesando
            if (task.status == 'processing' && task.progress != null) ...[
              const SizedBox(height: 12),
              _buildProgressSection(),
            ],
            
            // Acciones
            if (task.status == 'queued') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancelar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    IconData icon;
    
    switch (task.status) {
      case 'queued':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'processing':
        color = Colors.blue;
        icon = Icons.sync;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'cancelled':
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            task.statusText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = task.progress!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.downloaded} / ${progress.total} archivos',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '${progress.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

/// Widget panel para mostrar la cola de tareas
class QueuePanel extends StatefulWidget {
  final String? filterUsername;
  final String? username; // Para compatibilidad con descargas_screen

  const QueuePanel({super.key, this.filterUsername, this.username});

  @override
  State<QueuePanel> createState() => QueuePanelState();
}

class QueuePanelState extends State<QueuePanel> {
  List<QueueTask> _tasks = [];
  bool _isLoading = false;
  
  String? get _effectiveUsername => widget.filterUsername ?? widget.username;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() => _isLoading = true);
    
    try {
      if (_effectiveUsername != null && _effectiveUsername!.isNotEmpty) {
        _tasks = await QueueService.getUserQueue(_effectiveUsername!);
      } else {
        _tasks = await QueueService.listQueue();
      }
    } catch (e) {
      // Error handling
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelTask(String taskId) async {
    final success = await QueueService.cancelTask(taskId);
    if (success) {
      loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea cancelada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cola de Descargas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: loadTasks,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de tareas
        if (_isLoading && _tasks.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (_tasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No hay tareas en cola',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_tasks.map((task) => QueueTaskCard(
            task: task,
            onCancel: task.status == 'queued' 
                ? () => _cancelTask(task.taskId) 
                : null,
            onRefresh: loadTasks,
          ))),
      ],
    );
  }
}
