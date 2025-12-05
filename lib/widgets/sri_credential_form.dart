import 'package:flutter/material.dart';
import 'package:sri_master/models/admin_models.dart';
import 'package:sri_master/services/admin_service.dart';

/// Widget de formulario para credenciales SRI con selector de credenciales guardadas
class SriCredentialForm extends StatefulWidget {
  final Function(String ruc, String password, String? ciAdicional, String year, String month)? onSubmit;
  final bool showSaveCredential;

  const SriCredentialForm({
    super.key,
    this.onSubmit,
    this.showSaveCredential = true,
  });

  @override
  State<SriCredentialForm> createState() => SriCredentialFormState();
}

class SriCredentialFormState extends State<SriCredentialForm> {
  final _formKey = GlobalKey<FormState>();
  final _rucController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ciAdicionalController = TextEditingController();
  final _yearController = TextEditingController();
  
  String _selectedMonth = '';
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _saveCredential = false;
  bool _canAddCredential = true;
  bool _showPassword = false;
  
  List<SriCredential> _credentials = [];
  SriCredential? _selectedCredential;
  UserSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _yearController.text = DateTime.now().year.toString();
    _loadCredentials();
  }

  @override
  void dispose() {
    _rucController.dispose();
    _passwordController.dispose();
    _ciAdicionalController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    setState(() => _isLoading = true);
    
    try {
      final credentials = await AdminService.getMyCredentials();
      final subscription = await AdminService.getMySubscription();
      
      if (mounted) {
        setState(() {
          _credentials = credentials;
          _subscription = subscription;
          _canAddCredential = subscription == null || 
              credentials.length < subscription.maxCredentials;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCredentialSelected(SriCredential? credential) {
    setState(() {
      _selectedCredential = credential;
      if (credential != null) {
        _rucController.text = credential.ruc;
        _passwordController.text = credential.passwordSri ?? '';
        _ciAdicionalController.text = credential.ciAdicional ?? '';
      } else {
        _rucController.clear();
        _passwordController.clear();
        _ciAdicionalController.clear();
      }
    });
  }

  void clearForm() {
    _rucController.clear();
    _passwordController.clear();
    _ciAdicionalController.clear();
    setState(() {
      _selectedCredential = null;
      _selectedMonth = '';
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedMonth.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un mes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Guardar credencial si se marcó la opción
    if (_saveCredential && _selectedCredential == null && _canAddCredential) {
      await AdminService.addCredential(
        ruc: _rucController.text.trim(),
        passwordSri: _passwordController.text,
        ciAdicional: _ciAdicionalController.text.trim(),
        descripcion: _rucController.text.trim(),
      );
      _loadCredentials(); // Recargar lista
    }

    // Llamar callback
    widget.onSubmit?.call(
      _rucController.text.trim(),
      _passwordController.text,
      _ciAdicionalController.text.trim().isEmpty ? null : _ciAdicionalController.text.trim(),
      _yearController.text.trim(),
      _selectedMonth,
    );

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Selector de credenciales guardadas
          if (_credentials.isNotEmpty) ...[
            _buildCredentialSelector(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'O ingresa los datos manualmente:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Campos del formulario
          _buildRucField(),
          const SizedBox(height: 16),
          
          _buildCiAdicionalField(),
          const SizedBox(height: 16),
          
          _buildPasswordField(),
          const SizedBox(height: 16),
          
          _buildPeriodSelector(),
          
          // Checkbox para guardar credencial
          if (widget.showSaveCredential && _selectedCredential == null) ...[
            const SizedBox(height: 16),
            _buildSaveCredentialCheckbox(),
          ],
          
          const SizedBox(height: 24),
          
          // Botón de envío
          _buildSubmitButton(),

          // Info de suscripción
          if (_subscription != null) ...[
            const SizedBox(height: 16),
            _buildSubscriptionInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.cloud_download,
            color: Color(0xFF0D47A1),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Descargar XMLs del SRI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              Text(
                'Ingresa las credenciales del contribuyente',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildCredentialSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Credenciales Guardadas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SriCredential>(
            value: _selectedCredential,
            decoration: InputDecoration(
              hintText: 'Seleccionar credencial guardada',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<SriCredential>(
                value: null,
                child: Text('-- Ingresar manualmente --'),
              ),
              ..._credentials.map((c) => DropdownMenuItem(
                value: c,
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (c.descripcion != null && c.descripcion != c.ruc)
                            Text(
                              c.ruc,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],
            onChanged: _onCredentialSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildRucField() {
    return TextFormField(
      controller: _rucController,
      enabled: _selectedCredential == null,
      decoration: InputDecoration(
        labelText: 'RUC / Cédula',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _selectedCredential != null ? Colors.grey[100] : Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el RUC o Cédula';
        }
        if (value.length < 10) {
          return 'El RUC/Cédula debe tener al menos 10 dígitos';
        }
        return null;
      },
    );
  }

  Widget _buildCiAdicionalField() {
    return TextFormField(
      controller: _ciAdicionalController,
      enabled: _selectedCredential == null,
      decoration: InputDecoration(
        labelText: 'CI Adicional (opcional)',
        prefixIcon: const Icon(Icons.badge),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _selectedCredential != null ? Colors.grey[100] : Colors.grey[50],
        helperText: 'Solo si el contribuyente tiene CI adicional registrada',
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      enabled: _selectedCredential == null,
      obscureText: !_showPassword,
      decoration: InputDecoration(
        labelText: 'Contraseña SRI',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _selectedCredential != null ? Colors.grey[100] : Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese la contraseña';
        }
        return null;
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _selectedMonth.isEmpty ? null : _selectedMonth,
            decoration: InputDecoration(
              labelText: 'Mes',
              prefixIcon: const Icon(Icons.calendar_month),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: const [
              DropdownMenuItem(value: 'Enero', child: Text('Enero')),
              DropdownMenuItem(value: 'Febrero', child: Text('Febrero')),
              DropdownMenuItem(value: 'Marzo', child: Text('Marzo')),
              DropdownMenuItem(value: 'Abril', child: Text('Abril')),
              DropdownMenuItem(value: 'Mayo', child: Text('Mayo')),
              DropdownMenuItem(value: 'Junio', child: Text('Junio')),
              DropdownMenuItem(value: 'Julio', child: Text('Julio')),
              DropdownMenuItem(value: 'Agosto', child: Text('Agosto')),
              DropdownMenuItem(value: 'Septiembre', child: Text('Septiembre')),
              DropdownMenuItem(value: 'Octubre', child: Text('Octubre')),
              DropdownMenuItem(value: 'Noviembre', child: Text('Noviembre')),
              DropdownMenuItem(value: 'Diciembre', child: Text('Diciembre')),
            ],
            onChanged: (value) => setState(() => _selectedMonth = value ?? ''),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _yearController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Año',
              prefixIcon: const Icon(Icons.date_range),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Año';
              }
              final year = int.tryParse(value);
              if (year == null || year < 2000 || year > DateTime.now().year) {
                return 'Año inválido';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveCredentialCheckbox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _canAddCredential ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _canAddCredential ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _saveCredential && _canAddCredential,
            onChanged: _canAddCredential 
                ? (value) => setState(() => _saveCredential = value ?? false)
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guardar esta credencial para uso futuro',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _canAddCredential ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                if (!_canAddCredential)
                  Text(
                    'Has alcanzado el límite de credenciales de tu plan',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final bool canSubmit = !_isSubmitting && 
        (_selectedCredential != null || 
         (_rucController.text.isNotEmpty && _passwordController.text.isNotEmpty));

    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: canSubmit ? _handleSubmit : null,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send),
        label: Text(
          _isSubmitting ? 'Procesando...' : 'Iniciar Descarga',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF0D47A1).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfo() {
    final sub = _subscription!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Plan ${sub.planName}: ${_credentials.length}/${sub.maxCredentials} credenciales · ${sub.usedDownloads}/${sub.maxDownloads} descargas',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
