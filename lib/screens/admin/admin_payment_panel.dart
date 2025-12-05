import 'package:flutter/material.dart';
import 'package:sri_master/models/payment_models.dart';
import 'package:sri_master/services/payment_service.dart';

class AdminPaymentPanel extends StatefulWidget {
  final VoidCallback? onRefresh;

  const AdminPaymentPanel({super.key, this.onRefresh});

  @override
  State<AdminPaymentPanel> createState() => _AdminPaymentPanelState();
}

class _AdminPaymentPanelState extends State<AdminPaymentPanel> {
  // ESTILO GLOBALES
  final Color _paperColor = const Color(0xFFFFFFFF);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  bool _isLoading = false;
  int _tabIndex = 0; // 0: Métodos, 1: Comprobantes
  List<PaymentMethod> _methods = [];
  List<PaymentProof> _proofs = [];
  PaymentStats? _stats;
  bool _showCreateMethodForm = false;

  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountTypeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _accountHolderCiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountTypeController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    _accountHolderCiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final methods = await PaymentService.getAdminPaymentMethods();
      final proofs = await PaymentService.getAdminProofs();
      final stats = await PaymentService.getPaymentStats();

      if (mounted) {
        setState(() {
          _methods = methods;
          _proofs = proofs;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createMethod() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await PaymentService.createPaymentMethod(
      bankName: _bankNameController.text.trim(),
      accountType: _accountTypeController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      accountHolderName: _accountHolderNameController.text.trim(),
      accountHolderCi: _accountHolderCiController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        _showSnackBar('Método de pago creado', Colors.green);
        _clearForm();
        _loadData();
        widget.onRefresh?.call();
        setState(() => _showCreateMethodForm = false);
      } else {
        _showSnackBar(result['error'] ?? 'Error al crear', Colors.red);
      }
    }
  }

  Future<void> _verifyProof(PaymentProof proof, bool verified, {String? reason}) async {
    setState(() => _isLoading = true);
    final result = await PaymentService.verifyProof(
      proof.id,
      verified: verified,
      rejectionReason: reason,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        _showSnackBar(verified ? 'Verificado correctamente' : 'Rechazado correctamente', Colors.black);
        _loadData();
      } else {
        _showSnackBar(result['error'] ?? 'Error', Colors.red);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Courier')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: Border.all(color: Colors.black, width: 2),
      ),
    );
  }

  void _clearForm() {
    _bankNameController.clear();
    _accountTypeController.clear();
    _accountNumberController.clear();
    _accountHolderNameController.clear();
    _accountHolderCiController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _methods.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. ESTADISTICAS SUPERIORES (Estilo Stickers)
        if (_stats != null) _buildStatsRow(),
        
        const SizedBox(height: 20),

        // 2. PESTAÑAS PERSONALIZADAS (Tabs estilo carpeta)
        Row(
          children: [
            _buildTabButton("MÉTODOS BANCARIOS", 0),
            const SizedBox(width: 12),
            _buildTabButton("COMPROBANTES (${_stats?.pendingProofs ?? 0})", 1),
          ],
        ),

        const SizedBox(height: 20),

        // 3. CONTENIDO PRINCIPAL
        Expanded(
          child: _tabIndex == 0 ? _buildMethodsTab() : _buildProofsTab(),
        ),
      ],
    );
  }

  // --- WIDGETS DE UI ---

  Widget _buildStatsRow() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatSticker("TOTAL", "${_stats!.totalProofs}", Colors.blue),
          const SizedBox(width: 12),
          _buildStatSticker("VERIFICADOS", "${_stats!.verifiedProofs}", Colors.green),
          const SizedBox(width: 12),
          _buildStatSticker("PENDIENTES", "${_stats!.pendingProofs}", Colors.orange),
          const SizedBox(width: 12),
          _buildStatSticker("RECHAZADOS", "${_stats!.rejectedProofs}", Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatSticker(String label, String value, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color, fontFamily: 'Courier')),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 12
          ),
        ),
      ),
    );
  }

  // --- TAB: METODOS ---
  Widget _buildMethodsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón Nuevo Método
          if (!_showCreateMethodForm)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showCreateMethodForm = true),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text('NUEVA CUENTA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          
          if (_showCreateMethodForm) _buildMethodForm(),
          
          const SizedBox(height: 20),

          if (_methods.isEmpty && !_showCreateMethodForm)
            _buildEmptyState("No hay cuentas bancarias registradas"),

          ..._methods.map((method) => _buildMethodCard(method)),
        ],
      ),
    );
  }

  Widget _buildMethodForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4), // Amarillo pálido tipo "Nota Adhesiva"
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("REGISTRAR NUEVA CUENTA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const Divider(color: Colors.black, thickness: 2),
            const SizedBox(height: 16),
            
            _buildPaperInput(_bankNameController, "BANCO"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPaperInput(_accountTypeController, "TIPO (Ahorro/Corr.)")),
                const SizedBox(width: 12),
                Expanded(child: _buildPaperInput(_accountNumberController, "NÚMERO CUENTA")),
              ],
            ),
            const SizedBox(height: 12),
            _buildPaperInput(_accountHolderNameController, "TITULAR"),
            const SizedBox(height: 12),
            _buildPaperInput(_accountHolderCiController, "CÉDULA/RUC"),
            
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _clearForm();
                    setState(() => _showCreateMethodForm = false);
                  },
                  child: const Text("CANCELAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createMethod,
                  icon: const Icon(Icons.save_alt, color: Colors.white),
                  label: const Text("GUARDAR REGISTRO"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 10,
              color: method.isActive ? Colors.green : Colors.grey,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.bankName.toUpperCase(), 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text("CTA: ${method.maskedAccount}", 
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text("${method.accountHolderName} - ${method.accountHolderCi}", 
                              style: const TextStyle(fontSize: 12, fontFamily: 'Courier')),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB: COMPROBANTES ---
  Widget _buildProofsTab() {
    if (_proofs.isEmpty) return _buildEmptyState("No hay comprobantes pendientes");

    return ListView.builder(
      itemCount: _proofs.length,
      itemBuilder: (context, index) => _buildProofCardAdmin(_proofs[index]),
    );
  }

  Widget _buildProofCardAdmin(PaymentProof proof) {
    Color statusColor;
    IconData statusIcon;
    if (proof.isVerified) { statusColor = Colors.green; statusIcon = Icons.check_circle; }
    else if (proof.isRejected) { statusColor = Colors.red; statusIcon = Icons.cancel; }
    else { statusColor = Colors.orange; statusIcon = Icons.hourglass_top; }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0)],
      ),
      child: Column(
        children: [
          // Header del Ticket
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
              color: statusColor.withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(proof.statusDisplay.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Text(
                  "${proof.createdAt.day}/${proof.createdAt.month}/${proof.createdAt.year}",
                  style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Info Usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("USUARIO", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(proof.userName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("MÉTODO", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(proof.methodName, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                // Monto Grande
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "\$${proof.amount.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Courier', fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),

          if (proof.isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _verifyProof(proof, true),
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text("APROBAR", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green, width: 2),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(proof),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text("RECHAZAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 2),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  // Helper Input Estilo Offset
  Widget _buildPaperInput(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.5)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.5)),
            errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 1.5)),
            isDense: true,
          ),
          validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black12, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox, size: 40, color: Colors.grey),
          const SizedBox(height: 10),
          Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showRejectDialog(PaymentProof proof) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('RECHAZAR PAGO', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Indica el motivo del rechazo para notificar al usuario:"),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                hintText: 'Ej: Comprobante ilegible',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyProof(proof, false, reason: reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('CONFIRMAR RECHAZO', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}