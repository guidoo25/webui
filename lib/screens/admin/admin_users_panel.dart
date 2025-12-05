import 'package:flutter/material.dart';
import 'package:sri_master/models/admin_models.dart';
import 'package:sri_master/services/admin_service.dart';
import 'package:sri_master/utils/user_json_parser.dart';

class AdminUsersPanel extends StatefulWidget {
  final bool isProfileView;
  final VoidCallback? onRefresh;
  final List<AdminUser>? initialUsers;

  const AdminUsersPanel({
    super.key,
    this.isProfileView = false,
    this.onRefresh,
    this.initialUsers,
  });

  @override
  State<AdminUsersPanel> createState() => _AdminUsersPanelState();
}

class _AdminUsersPanelState extends State<AdminUsersPanel> {
  bool _isLoading = false;
  List<AdminUser> _users = [];
  AdminUser? _selectedUser;
  UserSubscription? _userSubscription;
  List<SriCredential> _userCredentials = [];

  // Formulario para crear usuario
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  bool _isAdmin = false;
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUsers != null) {
      _users = widget.initialUsers!;
      _isLoading = false;
    } else {
      // Si no hay usuarios iniciales, intentar cargar del JSON de ejemplo para testing
      // En producción, esto será reemplazado por _loadUsers()
      _users = UserJsonParser.getExampleUsers();
      if (_users.isNotEmpty) {
        _isLoading = false;
      } else {
        _loadUsers();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    final users = await AdminService.getUsers();
    
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserDetails(AdminUser user) async {
    setState(() => _isLoading = true);
    
    final subscription = await AdminService.getUserSubscription(user.id);
    final credentials = await AdminService.getUserCredentials(user.id);
    
    if (mounted) {
      setState(() {
        _selectedUser = user;
        _userSubscription = subscription;
        _userCredentials = credentials;
        _isLoading = false;
      });
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AdminService.createUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nombre: _nombreController.text.trim(),
      isAdmin: _isAdmin,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _emailController.clear();
        _passwordController.clear();
        _nombreController.clear();
        setState(() {
          _isAdmin = false;
          _showCreateForm = false;
        });
        _loadUsers();
        widget.onRefresh?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Error al crear usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(AdminUser user) async {
    final result = await AdminService.updateUser(
      user.id,
      isActive: !user.isActive,
    );

    if (result['success'] == true) {
      _loadUsers();
      widget.onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        // Lista de usuarios
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _showCreateForm ? _buildCreateForm() : _buildUserList(),
                ),
              ],
            ),
          ),
        ),
        
        // Detalles del usuario seleccionado
        if (_selectedUser != null)
          Expanded(
            flex: 3,
            child: _buildUserDetails(),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            'Usuarios (${_users.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          if (_showCreateForm)
            TextButton.icon(
              onPressed: () => setState(() => _showCreateForm = false),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
            )
          else
            ElevatedButton.icon(
              onPressed: () => setState(() => _showCreateForm = true),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear Nuevo Usuario',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el email';
                }
                if (!value.contains('@')) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre (opcional)',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese la contraseña';
                }
                if (value.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            CheckboxListTile(
              value: _isAdmin,
              onChanged: (value) => setState(() => _isAdmin = value ?? false),
              title: const Text('Es administrador'),
              subtitle: const Text('Tendrá acceso completo al sistema'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createUser,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Creando...' : 'Crear Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay usuarios',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isSelected = _selectedUser?.id == user.id;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D47A1).withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: const Color(0xFF0D47A1), width: 2)
                : null,
          ),
          child: ListTile(
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
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user.isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              user.email,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: user.isActive ? Colors.green : Colors.red,
              ),
            ),
            onTap: () => _loadUserDetails(user),
          ),
        );
      },
    );
  }

  Widget _buildUserDetails() {
    final user = _selectedUser!;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del usuario
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: user.isAdmin
                      ? const Color(0xFFE65100)
                      : const Color(0xFF0D47A1),
                  child: Text(
                    user.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 32),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge(
                            label: user.isActive ? 'Activo' : 'Inactivo',
                            color: user.isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          if (user.isAdmin)
                            _buildBadge(
                              label: 'Administrador',
                              color: const Color(0xFFE65100),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'toggle_status':
                        _toggleUserStatus(user);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            user.isActive ? Icons.block : Icons.check_circle,
                            color: user.isActive ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(user.isActive ? 'Desactivar' : 'Activar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Suscripción
            _buildSection(
              title: 'Suscripción',
              icon: Icons.card_membership,
              child: _userSubscription != null
                  ? _buildSubscriptionCard(_userSubscription!)
                  : _buildEmptyCard('Sin suscripción activa'),
            ),
            
            const SizedBox(height: 24),
            
            // Credenciales SRI
            _buildSection(
              title: 'Credenciales SRI (${_userCredentials.length})',
              icon: Icons.key,
              child: _userCredentials.isNotEmpty
                  ? Column(
                      children: _userCredentials
                          .map((c) => _buildCredentialCard(c))
                          .toList(),
                    )
                  : _buildEmptyCard('Sin credenciales registradas'),
            ),
            
            const SizedBox(height: 24),
            
            // Información adicional
            _buildSection(
              title: 'Información',
              icon: Icons.info_outline,
              child: _buildInfoCard(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildSubscriptionCard(UserSubscription sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(0xFF00897B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.planName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      sub.hasExpired ? 'Expirado' : '${sub.daysRemaining} días restantes',
                      style: TextStyle(
                        color: sub.hasExpired ? Colors.red : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUsageIndicator(
                  label: 'Credenciales',
                  used: sub.usedCredentials,
                  max: sub.maxCredentials,
                  color: const Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUsageIndicator(
                  label: 'Descargas',
                  used: sub.usedDownloads,
                  max: sub.maxDownloads,
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageIndicator({
    required String label,
    required int used,
    required int max,
    required Color color,
  }) {
    final percent = max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$used / $max',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialCard(SriCredential cred) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.business, color: Color(0xFF0D47A1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cred.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  cred.ruc,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cred.isActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AdminUser user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoRow('ID', '#${user.id}'),
          _buildInfoRow('Creado', _formatDate(user.createdAt)),
          _buildInfoRow('Credenciales', '${user.credentialsCount}'),
          _buildInfoRow('Descargas este mes', '${user.downloadsThisMonth}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
