import 'package:flutter/material.dart';
import 'package:sri_master/models/admin_models.dart';
import 'package:sri_master/services/admin_service.dart';

class AdminCredentialsPanel extends StatefulWidget {
  final List<AdminUser> users;
  final List<SriCredential> credentials;
  final VoidCallback? onRefresh;

  const AdminCredentialsPanel({
    super.key,
    required this.users,
    required this.credentials,
    this.onRefresh,
  });

  @override
  State<AdminCredentialsPanel> createState() => _AdminCredentialsPanelState();
}

class _AdminCredentialsPanelState extends State<AdminCredentialsPanel> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _showAddCredentialForm = false;
  
  // Form para agregar credencial
  final _formKey = GlobalKey<FormState>();
  final _rucController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ciAdicionalController = TextEditingController();
  final _descripcionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rucController.dispose();
    _passwordController.dispose();
    _ciAdicionalController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _addCredential() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AdminService.addCredential(
      ruc: _rucController.text.trim(),
      passwordSri: _passwordController.text,
      ciAdicional: _ciAdicionalController.text.trim(),
      descripcion: _descripcionController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Credencial agregada'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
        setState(() => _showAddCredentialForm = false);
        widget.onRefresh?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Error al agregar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCredential(SriCredential credential) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar la credencial "${credential.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await AdminService.deleteCredential(credential.id);
      if (result['success'] == true) {
        widget.onRefresh?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credencial eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _clearForm() {
    _rucController.clear();
    _passwordController.clear();
    _ciAdicionalController.clear();
    _descripcionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0D47A1),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF0D47A1),
            tabs: [
              Tab(
                icon: const Icon(Icons.people),
                text: 'Usuarios (${widget.users.length})',
              ),
              Tab(
                icon: const Icon(Icons.key),
                text: 'Mis Credenciales (${widget.credentials.length})',
              ),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersTab(),
              _buildCredentialsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    if (widget.users.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        message: 'No hay usuarios registrados',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.users.length,
      itemBuilder: (context, index) {
        final user = widget.users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(AdminUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: user.isAdmin
              ? const Color(0xFFE65100)
              : const Color(0xFF0D47A1),
          child: Text(
            user.displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (user.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildMiniStat(Icons.key, '${user.credentialsCount}'),
                const SizedBox(width: 12),
                _buildMiniStat(Icons.download, '${user.downloadsThisMonth}'),
                const SizedBox(width: 12),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: user.isActive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  user.isActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Email', user.email),
                _buildDetailRow('Plan', user.planName ?? 'Sin plan'),
                _buildDetailRow('Credenciales', '${user.credentialsCount}'),
                _buildDetailRow('Descargas este mes', '${user.downloadsThisMonth}'),
                if (user.createdAt != null)
                  _buildDetailRow(
                    'Registrado',
                    '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCredentialsTab() {
    return Column(
      children: [
        // Header con botón agregar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Row(
            children: [
              const Icon(Icons.key, color: Color(0xFF0D47A1)),
              const SizedBox(width: 8),
              const Text(
                'Mis Credenciales SRI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_showAddCredentialForm)
                TextButton(
                  onPressed: () => setState(() => _showAddCredentialForm = false),
                  child: const Text('Cancelar'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showAddCredentialForm = true),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        
        // Formulario o lista
        Expanded(
          child: _showAddCredentialForm
              ? _buildAddCredentialForm()
              : _buildCredentialsList(),
        ),
      ],
    );
  }

  Widget _buildAddCredentialForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar Nueva Credencial',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa los datos de acceso al portal del SRI',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _rucController,
              decoration: InputDecoration(
                labelText: 'RUC o Cédula',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: '13 dígitos para RUC, 10 para cédula',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el RUC o cédula';
                }
                if (value.length < 10) {
                  return 'Mínimo 10 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _ciAdicionalController,
              decoration: InputDecoration(
                labelText: 'CI Adicional (opcional)',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'Solo si el contribuyente tiene CI adicional',
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña del SRI',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese la contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'Ej: Empresa ABC, Cliente XYZ',
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addCredential,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Guardando...' : 'Guardar Credencial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsList() {
    if (widget.credentials.isEmpty) {
      return _buildEmptyState(
        icon: Icons.key_off,
        message: 'No tienes credenciales guardadas',
        action: ElevatedButton.icon(
          onPressed: () => setState(() => _showAddCredentialForm = true),
          icon: const Icon(Icons.add),
          label: const Text('Agregar primera credencial'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.credentials.length,
      itemBuilder: (context, index) {
        final credential = widget.credentials[index];
        return _buildCredentialCard(credential);
      },
    );
  }

  Widget _buildCredentialCard(SriCredential credential) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.business,
            color: Color(0xFF0D47A1),
          ),
        ),
        title: Text(
          credential.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('RUC: ${credential.ruc}'),
            if (credential.ciAdicional != null && credential.ciAdicional!.isNotEmpty)
              Text('CI Adicional: ${credential.ciAdicional}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: credential.isActive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  credential.isActive ? 'Activa' : 'Inactiva',
                  style: TextStyle(
                    fontSize: 12,
                    color: credential.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'delete':
                _deleteCredential(credential);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            action,
          ],
        ],
      ),
    );
  }
}
