import 'package:flutter/material.dart';
import 'package:sri_master/models/admin_models.dart';
import 'package:sri_master/services/admin_service.dart';

class AdminUsersManagementPanel extends StatefulWidget {
  const AdminUsersManagementPanel({super.key});

  @override
  State<AdminUsersManagementPanel> createState() => _AdminUsersManagementPanelState();
}

class _AdminUsersManagementPanelState extends State<AdminUsersManagementPanel> {
  bool _isLoading = false;
  List<AdminUser> _users = [];
  List<AdminUser> _filteredUsers = [];
  String _searchQuery = '';
  AdminUser? _selectedUser;
  UserSubscription? _selectedUserSubscription;
  List<SubscriptionPlan>? _plans;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _monthsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadPlans();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await AdminService.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _filterUsers();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlans() async {
    final plans = await AdminService.getPlans();
    if (mounted) {
      setState(() => _plans = plans);
    }
  }

  void _filterUsers() {
    _searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users
          .where((user) =>
              user.email.toLowerCase().contains(_searchQuery) ||
              (user.nombre?.toLowerCase().contains(_searchQuery) ?? false))
          .toList();
    });
  }

  Future<void> _selectUser(AdminUser user) async {
    setState(() => _selectedUser = user);
    final subscription = await AdminService.getAdminUserSubscription(user.id);
    if (mounted) {
      setState(() => _selectedUserSubscription = subscription);
    }
  }

  Future<void> _addTime() async {
    final months = int.tryParse(_monthsController.text);
    if (months == null || months <= 0 || _selectedUser == null) {
      _showMessage('Ingresa un número válido de meses', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AdminService.addSubscriptionTime(_selectedUser!.id, months);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        _showMessage('${months} mes(es) agregado(s)', Colors.green);
        _monthsController.clear();
        _selectUser(_selectedUser!);
      } else {
        _showMessage(result['error'] ?? 'Error al agregar tiempo', Colors.red);
      }
    }
  }

  Future<void> _removeTime() async {
    final months = int.tryParse(_monthsController.text);
    if (months == null || months <= 0 || _selectedUser == null) {
      _showMessage('Ingresa un número válido de meses', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AdminService.removeSubscriptionTime(_selectedUser!.id, months);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        _showMessage('${months} mes(es) removido(s)', Colors.green);
        _monthsController.clear();
        _selectUser(_selectedUser!);
      } else {
        _showMessage(result['error'] ?? 'Error al remover tiempo', Colors.red);
      }
    }
  }

  Future<void> _changePlan(int planId) async {
    if (_selectedUser == null) return;

    setState(() => _isLoading = true);
    final result = await AdminService.adminChangePlan(_selectedUser!.id, planId);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        _showMessage('Plan cambiado correctamente', Colors.green);
        _selectUser(_selectedUser!);
      } else {
        _showMessage(result['error'] ?? 'Error al cambiar plan', Colors.red);
      }
    }
  }

  Future<void> _renewSubscription() async {
    final months = int.tryParse(_monthsController.text);
    if (months == null || months <= 0 || _selectedUser == null) {
      _showMessage('Ingresa un número válido de meses', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AdminService.renewSubscription(_selectedUser!.id, months);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        _showMessage('Suscripción renovada por ${months} mes(es)', Colors.green);
        _monthsController.clear();
        _selectUser(_selectedUser!);
      } else {
        _showMessage(result['error'] ?? 'Error al renovar', Colors.red);
      }
    }
  }

  Future<void> _cancelSubscription() async {
    if (_selectedUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Suscripción'),
        content: const Text('¿Estás seguro de que deseas cancelar la suscripción?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final result = await AdminService.adminCancelSubscription(_selectedUser!.id);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        _showMessage('Suscripción cancelada', Colors.green);
        setState(() => _selectedUser = null);
        _selectUser(_selectedUser!);
      } else {
        _showMessage(result['error'] ?? 'Error al cancelar', Colors.red);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Buscador
          _buildSearchBar(),
          const SizedBox(height: 20),

          // Contenido principal
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lista de usuarios
                SizedBox(
                  width: 280,
                  child: _buildUsersList(),
                ),
                const SizedBox(width: 20),

                // Detalles del usuario seleccionado
                Expanded(
                  child: _selectedUser == null ? _buildEmptySelection() : _buildUserDetails(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00BCD4),
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
            child: const Icon(Icons.people, color: Color(0xFF00BCD4), size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GESTIÓN DE USUARIOS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Administra suscripciones y planes de usuarios',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por email o nombre...',
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2)),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2)),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              )
            : null,
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF00BCD4),
            child: Text(
              'USUARIOS (${_filteredUsers.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.black, thickness: 2),
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      _users.isEmpty ? 'No hay usuarios' : 'No se encontraron resultados',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isSelected = _selectedUser?.id == user.id;
                      return InkWell(
                        onTap: () => _selectUser(user),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00BCD4).withOpacity(0.2) : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.email,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              if (user.nombre != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user.nombre!,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySelection() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'SELECCIONA UN USUARIO',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Haz clic en un usuario de la lista para ver sus detalles',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información del usuario
            _buildSection(
              'INFORMACIÓN DEL USUARIO',
              [
                _buildInfoRow('Email', _selectedUser!.email),
                _buildInfoRow('Nombre', _selectedUser!.nombre ?? 'N/A'),
                _buildInfoRow('Estado', _selectedUser!.isActive ? 'ACTIVO' : 'INACTIVO'),
                _buildInfoRow('Rol', _selectedUser!.isAdmin ? 'ADMINISTRADOR' : 'USUARIO'),
              ],
            ),
            const SizedBox(height: 20),

            // Información de suscripción
            if (_selectedUserSubscription != null)
              _buildSection(
                'SUSCRIPCIÓN ACTUAL',
                [
                  _buildInfoRow('Plan', _selectedUserSubscription!.planName),
                  _buildInfoRow('Código', _selectedUserSubscription!.planCode),
                  _buildInfoRow('Estado', _selectedUserSubscription!.isActive ? 'ACTIVA' : 'VENCIDA'),
                  _buildInfoRow('Credenciales', '${_selectedUserSubscription!.usedCredentials}/${_selectedUserSubscription!.maxCredentials}'),
                  _buildInfoRow('Descargas', '${_selectedUserSubscription!.usedDownloads}/${_selectedUserSubscription!.maxDownloads}'),
                  if (_selectedUserSubscription!.expiresAt != null)
                    _buildInfoRow(
                      'Vence el',
                      '${_selectedUserSubscription!.expiresAt!.day}/${_selectedUserSubscription!.expiresAt!.month}/${_selectedUserSubscription!.expiresAt!.year}',
                    ),
                ],
              )
            else
              _buildSection(
                'SUSCRIPCIÓN ACTUAL',
                [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 30),
                          const SizedBox(height: 10),
                          const Text(
                            'No hay suscripción activa',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Acciones
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blue, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input de meses
        _buildActionCard(
          title: 'CANTIDAD DE MESES',
          child: TextField(
            controller: _monthsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Número de meses',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 1)),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 1)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Botones de tiempo
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'AGREGAR TIEMPO',
                color: Colors.green,
                onTap: _addTime,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                label: 'REMOVER TIEMPO',
                color: Colors.orange,
                onTap: _removeTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Plan cambio
        if (_plans != null && _plans!.isNotEmpty)
          _buildActionCard(
            title: 'CAMBIAR PLAN',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._plans!.map((plan) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _changePlan(plan.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          '${plan.name} - \$${plan.price}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Renovar
        _buildActionButton(
          label: 'RENOVAR SUSCRIPCIÓN',
          color: Colors.green,
          onTap: _renewSubscription,
        ),
        const SizedBox(height: 12),

        // Cancelar
        _buildActionButton(
          label: 'CANCELAR SUSCRIPCIÓN',
          color: Colors.red,
          onTap: _cancelSubscription,
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        border: Border.all(color: Colors.purple, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.purple, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: _isLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
      ),
    );
  }
}
