import 'package:flutter/material.dart';
import 'package:sri_master/models/admin_models.dart';
import 'package:sri_master/services/admin_service.dart';

class UserSubscriptionPanel extends StatefulWidget {
  final VoidCallback? onRefresh;

  const UserSubscriptionPanel({super.key, this.onRefresh});

  @override
  State<UserSubscriptionPanel> createState() => _UserSubscriptionPanelState();
}

class _UserSubscriptionPanelState extends State<UserSubscriptionPanel> {
  // ESTILOS VISUALES
  final Color _paperColor = const Color(0xFFFFFFFF);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  bool _isLoading = false;
  UserSubscription? _currentSubscription;
  List<SubscriptionPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final subscription = await AdminService.getMySubscription();
    final plans = await AdminService.getPlans();

    if (mounted) {
      setState(() {
        _currentSubscription = subscription;
        _plans = plans;
        _isLoading = false;
      });
    }
  }

  // Lógica de diálogos mantenida, solo UI actualizada
  Future<void> _subscribeToPlan(SubscriptionPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: Colors.white,
        title: const Text('CONTRATAR PLAN', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vas a contratar: ${plan.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDialogRow('PRECIO:', '\$${plan.price.toStringAsFixed(2)}/mes'),
            _buildDialogRow('CREDENCIALES:', '${plan.maxSriCredentials}'),
            _buildDialogRow('DESCARGAS:', '${plan.maxDownloadsMonth}'),
            const SizedBox(height: 16),
            Text(plan.description ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('CONFIRMAR CONTRATO'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);
    final result = await AdminService.subscribeToPlan(plan.id);
    _handleResult(result, '¡Plan contratado exitosamente!');
  }

  Future<void> _changePlan(SubscriptionPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: Colors.white,
        title: const Text('CAMBIAR PLAN', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cambiar a: ${plan.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Tu suscripción se actualizará al próximo período de facturación.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('CONFIRMAR CAMBIO'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);
    final result = await AdminService.updateSubscription(_currentSubscription!.id, plan.id);
    _handleResult(result, 'Plan actualizado exitosamente');
  }

  void _handleResult(Map<String, dynamic> result, String successMsg) {
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg, style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: Border.all(color: Colors.black, width: 2),
          ),
        );
        _loadData();
        widget.onRefresh?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Error', style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: Border.all(color: Colors.black, width: 2),
          ),
        );
      }
    }
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _plans.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          
          if (_currentSubscription != null) ...[
            _buildCurrentSubscription(),
            const SizedBox(height: 30),
          ],
          
          const Text(
            "PLANES DISPONIBLES", 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)
          ),
          const SizedBox(height: 16),
          _buildAvailablePlans(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA), // Cyan muy claro
        border: Border.all(color: _borderColor, width: 2),
        boxShadow: [BoxShadow(color: _shadowColor, offset: const Offset(4, 4), blurRadius: 0)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _borderColor, width: 2),
            ),
            child: const Icon(Icons.star, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MI SUSCRIPCIÓN',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                SizedBox(height: 4),
                Text(
                  'Gestiona tu nivel de acceso y límites.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscription() {
    final sub = _currentSubscription!;
    final daysRemaining = sub.daysRemaining;
    final isActive = daysRemaining > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _paperColor,
        border: Border.all(color: _borderColor, width: 2),
        boxShadow: [BoxShadow(color: _shadowColor, offset: const Offset(6, 6), blurRadius: 0)],
      ),
      child: Column(
        children: [
          // Banner Superior Estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isActive ? Colors.green : Colors.red,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isActive ? "ESTADO: ACTIVO" : "ESTADO: VENCIDO",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                if (isActive) 
                  const Icon(Icons.check_circle, color: Colors.white, size: 18)
                else 
                  const Icon(Icons.warning, color: Colors.white, size: 18),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("PLAN ACTUAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(
                          sub.planName.toUpperCase(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Text(
                        isActive ? "${daysRemaining} DÍAS" : "0 DÍAS",
                        style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Divider(color: Colors.black, thickness: 2),
                const SizedBox(height: 20),

                // Stats Grid
                Row(
                  children: [
                    Expanded(child: _buildStatBox("CREDENCIALES", "${sub.usedCredentials}/${sub.maxCredentials}")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatBox("DESCARGAS", "${sub.usedDownloads}/${sub.maxDownloads}")),
                  ],
                ),
                
                const SizedBox(height: 16),
                if (sub.expiresAt != null)
                  Text(
                    "RENOVACIÓN: ${sub.expiresAt!.day}/${sub.expiresAt!.month}/${sub.expiresAt!.year}",
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontFamily: 'Courier', fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildAvailablePlans() {
    if (_plans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: const Center(child: Text('NO HAY PLANES DISPONIBLES', style: TextStyle(fontWeight: FontWeight.bold))),
      );
    }

    // Grid responsive manual
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _plans.map((plan) {
            final width = (constraints.maxWidth - 16) / 2; // 2 columnas por defecto
            return SizedBox(
              width: constraints.maxWidth < 600 ? constraints.maxWidth : width,
              child: _buildPlanCard(plan),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isCurrentPlan = _currentSubscription?.planId == plan.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: isCurrentPlan ? Colors.black : Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Plan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isCurrentPlan ? Colors.yellow[300] : Colors.black,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.name.toUpperCase(),
                  style: TextStyle(
                    color: isCurrentPlan ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (isCurrentPlan)
                  const Icon(Icons.star, size: 16, color: Colors.black),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$${plan.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Courier'),
                    ),
                    Text(
                      '.${(plan.price % 1).toStringAsFixed(2).split('.')[1]}', // Decimales pequeños
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                    ),
                    const Text('/mes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPlanFeature(Icons.vpn_key, '${plan.maxSriCredentials} Credenciales'),
                const SizedBox(height: 8),
                _buildPlanFeature(Icons.download, '${plan.maxDownloadsMonth} Descargas'),
                
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading 
                      ? null 
                      : isCurrentPlan 
                        ? null 
                        : () => _currentSubscription == null 
                          ? _subscribeToPlan(plan) 
                          : _changePlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan ? Colors.grey[300] : Colors.black,
                      foregroundColor: isCurrentPlan ? Colors.grey[600] : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      elevation: 0,
                    ),
                    child: Text(
                      isCurrentPlan 
                        ? 'PLAN ACTUAL' 
                        : _currentSubscription == null 
                          ? 'CONTRATAR AHORA' 
                          : 'CAMBIAR PLAN',
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}