import 'package:flutter/material.dart';
import 'package:sri_master/models/payment_models.dart';
import 'package:sri_master/models/admin_models.dart';
import 'package:sri_master/services/payment_service.dart';
import 'package:sri_master/services/admin_service.dart';

class AdminProofsPanel extends StatefulWidget {
  final VoidCallback? onRefresh;

  const AdminProofsPanel({super.key, this.onRefresh});

  @override
  State<AdminProofsPanel> createState() => _AdminProofsPanelState();
}

class _AdminProofsPanelState extends State<AdminProofsPanel> {
  // ESTILOS GLOBALES
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  bool _isLoading = false;
  List<PaymentProof> _proofs = [];
  String _filterStatus = 'pending'; // pending, verified, rejected, all
  
  final TextEditingController _rejectionReasonController = TextEditingController();
  
  // Expanded proof details
  int? _expandedProofId;
  AdminUser? _expandedUserData;
  UserSubscription? _expandedUserSubscription;
  bool _loadingExpandedData = false;

  @override
  void initState() {
    super.initState();
    _loadProofs();
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadProofs() async {
    setState(() => _isLoading = true);
    final proofs = await PaymentService.getAdminProofs();
    
    if (mounted) {
      setState(() {
        _proofs = proofs;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserDetails(int userId) async {
    setState(() => _loadingExpandedData = true);
    
    final userFuture = AdminService.getUserById(userId);
    final subscriptionFuture = AdminService.getUserSubscription(userId);
    
    final results = await Future.wait([userFuture, subscriptionFuture]);
    
    if (mounted) {
      setState(() {
        _expandedUserData = results[0] as AdminUser?;
        _expandedUserSubscription = results[1] as UserSubscription?;
        _loadingExpandedData = false;
      });
    }
  }

  void _toggleExpandProof(PaymentProof proof) {
    if (_expandedProofId == proof.id) {
      // Si ya está expandido, colapsarlo
      setState(() {
        _expandedProofId = null;
        _expandedUserData = null;
        _expandedUserSubscription = null;
      });
    } else {
      // Expandir el nuevo
      setState(() => _expandedProofId = proof.id);
      _loadUserDetails(proof.userId);
    }
  }

  List<PaymentProof> _getFilteredProofs() {
    if (_filterStatus == 'all') {
      return _proofs;
    }
    return _proofs.where((p) => p.status == _filterStatus).toList();
  }

  Future<void> _approveProof(int proofId) async {
    setState(() => _isLoading = true);
    
    final result = await PaymentService.verifyProof(
      proofId,
      verified: true,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('COMPROBANTE APROBADO ✓', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadProofs();
        widget.onRefresh?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Error al aprobar', style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectProof(int proofId) async {
    final reason = _rejectionReasonController.text.trim();
    
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('INGRESA UN MOTIVO DE RECHAZO', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await PaymentService.verifyProof(
      proofId,
      verified: false,
      rejectionReason: reason,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('COMPROBANTE RECHAZADO ✗', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _rejectionReasonController.clear();
        _loadProofs();
        widget.onRefresh?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Error al rechazar', style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _proofs.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    final filteredProofs = _getFilteredProofs();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header estilo Ticket
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. Filtros
          _buildFilters(),
          const SizedBox(height: 20),

          // 3. Estadísticas rápidas
          _buildStatistics(),
          const SizedBox(height: 20),

          // 4. Lista de comprobantes
          const Text(
            "COMPROBANTES DE PAGO",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _buildProofsList(filteredProofs),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
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
            child: const Icon(Icons.verified_user, color: Colors.black, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GESTIÓN DE COMPROBANTES',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                SizedBox(height: 4),
                Text(
                  'Revisa y aprueba/rechaza comprobantes de pago de usuarios',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton('pending', 'PENDIENTE', Colors.orange),
                const SizedBox(width: 8),
                _buildFilterButton('verified', 'APROBADO', Colors.green),
                const SizedBox(width: 8),
                _buildFilterButton('rejected', 'RECHAZADO', Colors.red),
                const SizedBox(width: 8),
                _buildFilterButton('all', 'TODOS', Colors.blue),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _loadProofs,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: _borderColor, width: 2),
            ),
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String status, String label, Color color) {
    final isActive = _filterStatus == status;
    return InkWell(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.grey[100],
          border: Border.all(color: _borderColor, width: 2),
          boxShadow: isActive ? [BoxShadow(color: _shadowColor, offset: const Offset(3, 3), blurRadius: 0)] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final pending = _proofs.where((p) => p.status == 'pending').length;
    final verified = _proofs.where((p) => p.status == 'verified').length;
    final rejected = _proofs.where((p) => p.status == 'rejected').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('PENDIENTE', pending.toString(), Colors.orange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('APROBADO', verified.toString(), Colors.green),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('RECHAZADO', rejected.toString(), Colors.red),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildProofsList(List<PaymentProof> proofs) {
    if (proofs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[400]!, width: 2),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox, color: Colors.grey, size: 40),
            SizedBox(height: 10),
            Text('NO HAY COMPROBANTES EN ESTE ESTADO', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: proofs.length,
      itemBuilder: (context, index) => _buildProofCard(proofs[index]),
    );
  }

  Widget _buildProofCard(PaymentProof proof) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (proof.isVerified) {
      statusColor = Colors.green;
      statusText = "APROBADO";
      statusIcon = Icons.check_circle;
    } else if (proof.isRejected) {
      statusColor = Colors.red;
      statusText = "RECHAZADO";
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.orange;
      statusText = "PENDIENTE";
      statusIcon = Icons.hourglass_top;
    }

    final isExpanded = _expandedProofId == proof.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        children: [
          // Header del Card - Clickeable
          InkWell(
            onTap: () => _toggleExpandProof(proof),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: statusColor.withOpacity(0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, size: 18, color: statusColor),
                      const SizedBox(width: 8),
                      Text(statusText, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: statusColor)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "${proof.createdAt.day}/${proof.createdAt.month}/${proof.createdAt.year}",
                        style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.black, thickness: 1.5),

          // Contenido del Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Información del usuario
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("USUARIO", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text(proof.userName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("MONTO", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            "\$${proof.amount.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Método de pago
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("MÉTODO", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(proof.methodName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),

                // SECCIÓN EXPANDIBLE - Detalles del usuario
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue, width: 1.5),
                    ),
                    child: _loadingExpandedData
                        ? const Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
                            ),
                          )
                        : (_expandedUserData == null || _expandedUserSubscription == null)
                            ? const Center(
                                child: Text(
                                  'Error al cargar datos del usuario',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'INFORMACIÓN DEL USUARIO',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildUserInfoRow('Email', _expandedUserData!.email),
                                  _buildUserInfoRow('Nombre', _expandedUserData!.nombre ?? 'N/A'),
                                  _buildUserInfoRow('Estado', _expandedUserData!.isActive ? 'ACTIVO' : 'INACTIVO'),
                                  const SizedBox(height: 12),
                                  const Divider(color: Colors.blue, thickness: 1),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'INFORMACIÓN DEL PLAN',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildUserInfoRow('Plan Actual', _expandedUserSubscription!.planName),
                                  _buildUserInfoRow('Código', _expandedUserSubscription!.planCode),
                                  _buildUserInfoRow('Estado', _expandedUserSubscription!.isActive ? 'ACTIVO' : 'VENCIDO'),
                                  _buildUserInfoRow('Credenciales Máx', '${_expandedUserSubscription!.maxCredentials}'),
                                  _buildUserInfoRow('Credenciales Usadas', '${_expandedUserSubscription!.usedCredentials}'),
                                  _buildUserInfoRow('Descargas Máx/Mes', '${_expandedUserSubscription!.maxDownloads}'),
                                  _buildUserInfoRow('Descargas Usadas', '${_expandedUserSubscription!.usedDownloads}'),
                                  if (_expandedUserSubscription!.expiresAt != null) ...[
                                    _buildUserInfoRow(
                                      'Vence el',
                                      '${_expandedUserSubscription!.expiresAt!.day}/${_expandedUserSubscription!.expiresAt!.month}/${_expandedUserSubscription!.expiresAt!.year}',
                                    ),
                                  ],
                                ],
                              ),
                  ),
                  // Sección de datos bancarios
                  if (_loadingExpandedData == false && _expandedUserData != null) ...[
                    const SizedBox(height: 16),
                    FutureBuilder<List<PaymentMethod>>(
                      future: PaymentService.getUserPaymentMethods(proof.userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              border: Border.all(color: Colors.purple, width: 1.5),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(color: Colors.purple, strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final paymentMethod = snapshot.data!.first;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              border: Border.all(color: Colors.purple, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DATOS BANCARIOS DEL USUARIO',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: Colors.purple),
                                ),
                                const SizedBox(height: 12),
                                _buildUserInfoRow('Banco', paymentMethod.bankName),
                                _buildUserInfoRow('Tipo de Cuenta', paymentMethod.accountType.toUpperCase()),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.purple, width: 2),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('NÚMERO DE CUENTA', style: TextStyle(fontSize: 9, color: Colors.purple, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(
                                        paymentMethod.accountNumber,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'Courier',
                                          color: Colors.black,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildUserInfoRow('Titular', paymentMethod.accountHolderName),
                                _buildUserInfoRow('Cédula/ID', paymentMethod.accountHolderCi),
                              ],
                            ),
                          );
                        }
                        
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            border: Border.all(color: Colors.orange, width: 1.5),
                          ),
                          child: const Text(
                            'No hay datos bancarios registrados',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ],
                ],

                // Motivo de rechazo si existe
                if (proof.isRejected && proof.rejectionReason != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("MOTIVO DEL RECHAZO", style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                        Text(proof.rejectionReason!, style: TextStyle(color: Colors.red[900], fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],

                // Botones de acción (solo si está pendiente)
                if (proof.isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => _showRejectDialog(proof),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("RECHAZAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _approveProof(proof.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("APROBAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
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

  void _showRejectDialog(PaymentProof proof) {
    _rejectionReasonController.clear();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "MOTIVO DEL RECHAZO",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rejectionReasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Ingresa el motivo...",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 2),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("CANCELAR", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pop(context);
                        _rejectProof(proof.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("RECHAZAR", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
