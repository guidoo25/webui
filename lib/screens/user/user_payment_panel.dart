import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sri_master/models/payment_models.dart';
import 'package:sri_master/services/payment_service.dart';

class UserPaymentPanel extends StatefulWidget {
  final VoidCallback? onRefresh;

  const UserPaymentPanel({super.key, this.onRefresh});

  @override
  State<UserPaymentPanel> createState() => _UserPaymentPanelState();
}

class _UserPaymentPanelState extends State<UserPaymentPanel> {
  // ESTILOS GLOBALES
  final Color _paperColor = const Color(0xFFFFFFFF);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  bool _isLoading = false;
  PaymentMethodsResponse? _paymentMethodsResponse;
  List<PaymentProof> _proofs = [];
  PaymentMethod? _selectedMethod;
  bool _showUploadForm = false;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  XFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final methodsResponse = await PaymentService.getPaymentMethods();
    final proofs = await PaymentService.getMyProofs();

    if (mounted) {
      setState(() {
        _paymentMethodsResponse = methodsResponse;
        _proofs = proofs;
        _isLoading = false;
      });
      
      // Mostrar la respuesta completa del API
      if (methodsResponse != null) {
        print('Payment Methods Response:');
        print('Success: ${methodsResponse.success}');
        print('Count: ${methodsResponse.count}');
        print('Methods: ${methodsResponse.methods.length}');
        for (var method in methodsResponse.methods) {
          print('- Bank: ${method.bankName}, Account: ${method.accountNumber}, Holder: ${method.accountHolderName}');
        }
      }
    }
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _uploadProof() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null || _selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('COMPLETA TODOS LOS CAMPOS', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: Border.all(color: Colors.white, width: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await PaymentService.uploadPaymentProof(
      filePath: _selectedFile!.path,
      paymentMethodId: _selectedMethod!.id,
      amount: double.tryParse(_amountController.text) ?? 0,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ENVIADO CORRECTAMENTE', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: Border.all(color: Colors.black, width: 2),
          ),
        );
        _amountController.clear();
        _selectedFile = null;
        _selectedMethod = null;
        setState(() => _showUploadForm = false);
        _loadData();
        widget.onRefresh?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'ERROR AL SUBIR', style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: Border.all(color: Colors.black, width: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _paymentMethodsResponse == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header estilo Ticket
          _buildHeader(),
          const SizedBox(height: 24),
          
          // 2. Sección Métodos de Pago
          const Text(
            "CUENTAS DISPONIBLES",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _buildMethods(),
          
          const SizedBox(height: 30),
          
          // 3. Formulario de Subida (Expandible)
          _buildUploadSection(),
          
          const SizedBox(height: 30),
          
          // 4. Historial de Pagos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "HISTORIAL DE PAGOS",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${_proofs.length}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMyProofs(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4), // Amarillo pálido
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
            child: const Icon(Icons.attach_money, color: Colors.black, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REPORTAR PAGO',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                SizedBox(height: 4),
                Text(
                  'Realiza tu transferencia y sube el comprobante aquí para activar tu plan.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethods() {
    if (_paymentMethodsResponse == null || !_paymentMethodsResponse!.success || _paymentMethodsResponse!.methods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: const Center(child: Text('NO HAY CUENTAS BANCARIAS CONFIGURADAS', style: TextStyle(fontWeight: FontWeight.bold))),
      );
    }

    return Column(
      children: _paymentMethodsResponse!.methods.map((method) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    method.bankName.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const Icon(Icons.account_balance, size: 20),
                ],
              ),
              const Divider(color: Colors.black, thickness: 1.5, height: 20),
              _buildDetailRow("TITULAR", method.accountHolderName),
              const SizedBox(height: 6),
              _buildDetailRow("RUC/CI", method.accountHolderCi),
              const SizedBox(height: 6),
              _buildDetailRow("CUENTA", method.accountNumber),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Container(
      decoration: BoxDecoration(
        color: _paperColor,
        border: Border.all(color: _borderColor, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0)],
      ),
      child: Column(
        children: [
          // Botón toggle
          InkWell(
            onTap: () => setState(() => _showUploadForm = !_showUploadForm),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: _showUploadForm ? Colors.grey[100] : Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Colors.black),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'SUBIR COMPROBANTE',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  Icon(
                    _showUploadForm ? Icons.remove : Icons.add,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
          
          if (_showUploadForm)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black, width: 2)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown Estilo Offset
                    const Text("SELECCIONA EL BANCO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          isExpanded: true,
                          value: _selectedMethod,
                          hint: const Text("Seleccionar...", style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                          items: (_paymentMethodsResponse?.methods ?? []).map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.displayName, style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedMethod = value),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Input Monto
                    _buildPaperInput(_amountController, "MONTO TRANSFERIDO (\$)"),
                    
                    const SizedBox(height: 16),
                    
                    // Selector de Archivo
                    InkWell(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _selectedFile != null ? Colors.green[50] : Colors.grey[50],
                          border: Border.all(
                            color: _selectedFile != null ? Colors.green : Colors.grey,
                            width: 2,
                            style: BorderStyle.solid
                          ), // Estilo punteado simulado con sólido por ahora
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedFile != null ? Icons.check_circle : Icons.image_search,
                              color: _selectedFile != null ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _selectedFile?.name ?? 'TOCA PARA ELEGIR FOTO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedFile != null ? Colors.green[800] : Colors.grey[600],
                                  fontSize: 12
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botones de Acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _amountController.clear();
                              setState(() {
                                _selectedFile = null;
                                _selectedMethod = null;
                                _showUploadForm = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black, width: 2),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("CANCELAR", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _uploadProof,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("ENVIAR AHORA", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaperInput(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 16),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2.5)),
            isDense: true,
            prefixText: "\$ ",
            prefixStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMyProofs() {
    if (_proofs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[400]!, width: 2, style: BorderStyle.solid), // Dashed border simulated
        ),
        child: const Column(
          children: [
            Icon(Icons.history, color: Colors.grey, size: 40),
            SizedBox(height: 10),
            Text('AÚN NO TIENES COMPROBANTES', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _proofs.length,
      itemBuilder: (context, index) => _buildProofCard(_proofs[index]),
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
      statusText = "EN REVISIÓN";
      statusIcon = Icons.hourglass_top;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        children: [
          // Header del Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: statusColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(statusText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
                Text(
                  "${proof.createdAt.day}/${proof.createdAt.month}/${proof.createdAt.year}",
                  style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black, thickness: 2),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("MÉTODO", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(proof.methodName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (proof.isRejected && proof.rejectionReason != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.red[50], border: Border.all(color: Colors.red)),
                          child: Text(
                            "MOTIVO: ${proof.rejectionReason}",
                            style: TextStyle(color: Colors.red[900], fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "\$${proof.amount.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}