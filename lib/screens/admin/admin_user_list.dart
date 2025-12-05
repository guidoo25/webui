import 'package:flutter/material.dart';
import 'package:sri_master/models/admin_models.dart';
import 'package:sri_master/services/admin_service.dart';

class AdminUserList extends StatefulWidget {
  final List<AdminUser>? initialUsers;

  const AdminUserList({
    super.key,
    this.initialUsers,
  });

  @override
  State<AdminUserList> createState() => _AdminUserListState();
}

class _AdminUserListState extends State<AdminUserList> {
  late Future<List<AdminUser>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    if (widget.initialUsers != null) {
      _futureUsers = Future.value(widget.initialUsers!);
    } else {
      _futureUsers = AdminService.getUsers();
    }
  }

  Future<void> _refresh() async {
    // Siempre refrescar desde el servicio
    setState(() {
      _futureUsers = AdminService.getUsers();
    });
    await _futureUsers;
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    final dt = d.toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminUser>>(
      future: _futureUsers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No hay usuarios')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : '?'),
                  ),
                  title: Text(u.displayName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.email),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(u.isAdmin ? Icons.shield : Icons.person, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(u.isAdmin ? 'Administrador' : 'Usuario', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                          const SizedBox(width: 12),
                          Icon(u.isActive ? Icons.check_circle : Icons.block, size: 14, color: u.isActive ? Colors.green : Colors.red),
                          const SizedBox(width: 6),
                          Text(u.isActive ? 'Activo' : 'Inactivo', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Creds: ${u.credentialsCount}'),
                      const SizedBox(height: 4),
                      Text(_formatDate(u.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  onTap: () {
                    // TODO: abrir detalle de usuario
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
