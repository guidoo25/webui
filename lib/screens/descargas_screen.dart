import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sri_master/conts/enviroments.dart';
import 'package:sri_master/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sri_master/widgets/componentes_paper.dart';
import 'package:sri_master/widgets/invoice_paper.dart';
import 'package:sri_master/widgets/invoice_table.dart';
import 'package:sri_master/widgets/queue_widgets.dart';

class DescargasScreen extends StatefulWidget {
  const DescargasScreen({super.key});

  @override
  State<DescargasScreen> createState() => _DescargasScreenState();
}

class _DescargasScreenState extends State<DescargasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estado
  bool _isLoading = false;
  String? _error;

  // Datos
  List<dynamic> _carpetas = [];
  List<dynamic> _comprobantes = [];
  List<dynamic> _tareasActivas = [];
  Map<String, dynamic>? _estadisticas;

  // Paginación
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalComprobantes = 0;
  int _perPage = 20;
  String _sortBy = 'fechaEmision';
  String _sortOrder = 'desc';

  // Filtro por emisor
  List<dynamic> _emisoresFrecuentes = [];
  String? _filtroRucEmisor;

  // Resumen
  Map<String, dynamic>? _resumen;

  // Filtros
  String? _selectedUser;
  String? _selectedYear;
  String? _selectedMonth;

  // Búsqueda
  final _searchController = TextEditingController();
  
  // Búsqueda local en tabla
  final _tableSearchController = TextEditingController();
  String _tableSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarCarpetas();
    _cargarTareasActivas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _tableSearchController.dispose();
    super.dispose();
  }

  // ============ API CALLS ============
  Future<void> _cargarCarpetas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse("${Enviroments.apiurl}/api/comprobantes");
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _carpetas = data['folders'] ?? [];
          });
        }
      } else {
        setState(() => _error = "Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _error = "Conexión: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarComprobantes(String user, String year, String month,
      {int page = 1, String? rucEmisor}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedUser = user;
      _selectedYear = year;
      _selectedMonth = month;
      _currentPage = page;
      if (rucEmisor != null) _filtroRucEmisor = rucEmisor;
    });

    try {
      final token = await AuthService.getToken();
      String url =
          "${Enviroments.apiurl}/api/comprobantes/$user/$year/$month/detail?page=$page&per_page=$_perPage&sort_by=$_sortBy&sort_order=$_sortOrder";
      if (_filtroRucEmisor != null && _filtroRucEmisor!.isNotEmpty) {
        url += "&ruc_emisor=$_filtroRucEmisor";
      }
      final uri = Uri.parse(url);
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _comprobantes = data['comprobantes'] ?? [];
            _emisoresFrecuentes = data['emisores_frecuentes'] ?? [];
            _resumen = data['resumen'];
            final pagination = data['pagination'];
            if (pagination != null) {
              _currentPage = pagination['page'] ?? 1;
              _totalPages = pagination['total_pages'] ?? 1;
              _totalComprobantes = pagination['total_items'] ?? 0;
              _perPage = pagination['per_page'] ?? 20;
            }
          });
        }
      }
    } catch (e) {
      setState(() => _error = "Conexión: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarTareasActivas() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse("${Enviroments.apiurl}/api/tasks/active");
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() => _tareasActivas = data['tasks'] ?? []);
        }
      }
    } catch (e) {}
  }

  Future<void> _cargarEstadisticas(String username) async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse("${Enviroments.apiurl}/api/stats/$username");
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() => _estadisticas = data['stats']);
        }
      }
    } catch (e) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buscarComprobantes(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse("${Enviroments.apiurl}/api/search?q=$query");
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() => _comprobantes = data['results'] ?? []);
        }
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _descargarXML(String claveAcceso) async {
    if (claveAcceso.isEmpty) return;
    try {
      final token = await AuthService.getToken();
      final uri =
          Uri.parse("${Enviroments.apiurl}/api/comprobante/$claveAcceso/xml");
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http.get(uri, headers: headers);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.statusCode == 200
                ? "XML descargado"
                : "Error al descargar"),
            backgroundColor:
                response.statusCode == 200 ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {}
  }

  // Exportar comprobantes del mes actual
  Future<void> _exportarMes({bool soloEmisorActual = false}) async {
    if (_selectedUser == null || _selectedYear == null || _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona una carpeta primero"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String url = "${Enviroments.apiurl}/api/comprobantes/$_selectedUser/$_selectedYear/$_selectedMonth/export";
    
    if (soloEmisorActual && _filtroRucEmisor != null && _filtroRucEmisor!.isNotEmpty) {
      url += "?ruc_emisor=$_filtroRucEmisor";
    }

    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse(url);
      
      // Agregar token al query si es necesario
      final exportUri = token != null 
        ? Uri.parse("$url${soloEmisorActual && _filtroRucEmisor != null ? '&' : '?'}token=$token")
        : uri;
      
      if (await canLaunchUrl(exportUri)) {
        await launchUrl(exportUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: intentar abrir directamente
        await launchUrl(exportUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al exportar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mostrar menú de acciones
  void _mostrarMenuAcciones() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Acciones",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Exportar todo el mes
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.download_rounded, color: Color(0xFF0D47A1)),
              ),
              title: const Text("Exportar mes completo"),
              subtitle: Text(
                "Descargar todos los comprobantes de $_selectedMonth $_selectedYear",
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportarMes(soloEmisorActual: false);
              },
            ),
            const Divider(),
            // Exportar solo emisor filtrado
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.filter_alt, color: Colors.green),
              ),
              title: const Text("Exportar emisor actual"),
              subtitle: Text(
                _filtroRucEmisor != null && _filtroRucEmisor!.isNotEmpty
                    ? "Descargar solo del RUC: $_filtroRucEmisor"
                    : "Selecciona un emisor primero",
                style: const TextStyle(fontSize: 12),
              ),
              enabled: _filtroRucEmisor != null && _filtroRucEmisor!.isNotEmpty,
              onTap: _filtroRucEmisor != null && _filtroRucEmisor!.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      _exportarMes(soloEmisorActual: true);
                    }
                  : null,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ============ UI BUILDERS ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Descargas y Comprobantes",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.folder_copy_outlined), text: "Carpetas"),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: "Comprobantes"),
            Tab(icon: Icon(Icons.search), text: "Buscar"),
            Tab(icon: Icon(Icons.bar_chart), text: "Stats"),
          ],
        ),
        actions: [
          if (_tareasActivas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Badge(
                label: Text("${_tareasActivas.length}"),
                child: IconButton(
                  icon: const Icon(Icons.downloading),
                  onPressed: _mostrarTareasActivas,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarCarpetas();
              _cargarTareasActivas();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCarpetasTab(),
                    _buildComprobantesTab(),
                    _buildBusquedaTab(),
                    _buildEstadisticasTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarColaDescargas,
        backgroundColor: const Color(0xFF0D47A1),
        icon: const Icon(Icons.queue, color: Colors.white),
        label: const Text("Cola", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1)),
            onPressed: _cargarCarpetas,
            child: const Text("Reintentar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: Carpetas ---
  // Getter para comprobantes filtrados localmente
  List<dynamic> get _comprobantesFiltrados {
    if (_tableSearchQuery.isEmpty) return _comprobantes;
    final query = _tableSearchQuery.toLowerCase();
    return _comprobantes.where((comp) {
      final emisor = comp['emisor'] as Map<String, dynamic>? ?? {};
      final ruc = emisor['ruc']?.toString().toLowerCase() ?? '';
      final razonSocial = emisor['razonSocial']?.toString().toLowerCase() ?? '';
      final nombreComercial = emisor['nombreComercial']?.toString().toLowerCase() ?? '';
      final establecimiento = emisor['establecimiento']?.toString() ?? '';
      final puntoEmision = emisor['puntoEmision']?.toString() ?? '';
      final secuencial = emisor['secuencial']?.toString() ?? '';
      final numComprobante = '$establecimiento-$puntoEmision-$secuencial'.toLowerCase();
      
      return ruc.contains(query) || 
             razonSocial.contains(query) || 
             nombreComercial.contains(query) ||
             numComprobante.contains(query);
    }).toList();
  }

  Widget _buildCarpetasTab() {
    if (_carpetas.isEmpty) {
      return const Center(child: Text("No hay carpetas"));
    }

    final Map<String, List<dynamic>> porUsuario = {};
    for (var carpeta in _carpetas) {
      final username = carpeta['username'] ?? 'Desconocido';
      porUsuario.putIfAbsent(username, () => []);
      porUsuario[username]!.add(carpeta);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: porUsuario.length,
      itemBuilder: (context, index) {
        final username = porUsuario.keys.elementAt(index);
        final carpetasUsuario = porUsuario[username]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PaperCardBase(
            padding: const EdgeInsets.all(0),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0D47A1),
                  child: Text(username[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(username,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                subtitle: Text("${carpetasUsuario.length} carpetas disponibles",
                    style: const TextStyle(fontSize: 12)),
                children: carpetasUsuario.map<Widget>((carpeta) {
                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.folder, color: Color(0xFFE67E22)),
                      title: Text("${carpeta['month']} ${carpeta['year']}",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${carpeta['total_files']} archivos",
                          style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey),
                      onTap: () {
                        _cargarComprobantes(
                          carpeta['username'],
                          carpeta['year'].toString(),
                          carpeta['month'],
                        );
                        _tabController.animateTo(1);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComprobantesTab() {
    if (_comprobantes.isEmpty && _selectedUser == null) {
      return const Center(child: Text("Selecciona una carpeta primero"));
    }
    
    final comprobantesMostrar = _comprobantesFiltrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedUser != null) ...[
          _buildHeaderResumenPaper(),
          _buildFiltrosComprobantesPaper(),
          // Campo de búsqueda local en tabla
          _buildTableSearchField(),
        ],

        Expanded(
          child: comprobantesMostrar.isEmpty
              ? Center(
                  child: Text(
                    _tableSearchQuery.isNotEmpty 
                      ? "No se encontraron resultados para '$_tableSearchQuery'"
                      : "No hay comprobantes",
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InvoiceTable(
                    comprobantes: comprobantesMostrar,
                    onTap: (comp) => _mostrarDetalleFactura(comp),
                  ),
                ),
        ),

        if (_totalPages > 1) _buildPaginationPaper(),
      ],
    );
  }

  Widget _buildHeaderResumenPaper() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$_selectedMonth $_selectedYear".toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
              ),
              // Botón de acciones
              Material(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _mostrarMenuAcciones,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Exportar",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResumenStat(
                  "CANTIDAD", "${_resumen?['cantidad'] ?? 0}"),
              Container(width: 1, height: 20, color: Colors.white24),
              _buildResumenStat("TOTAL",
                  "\$${(_resumen?['total'] ?? 0).toStringAsFixed(2)}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildFiltrosComprobantesPaper() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.transparent,
      child: Column(
        children: [
          // Dropdown de emisores con búsqueda
          if (_emisoresFrecuentes.isNotEmpty)
            SearchableEmisorDropdown(
              selectedRuc: _filtroRucEmisor,
              emisores: _emisoresFrecuentes,
              hint: "Filtrar por Emisor",
              onChanged: (value) {
                setState(() => _filtroRucEmisor = value);
                _cargarComprobantes(_selectedUser!, _selectedYear!, _selectedMonth!,
                    page: 1, rucEmisor: value);
              },
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: PaperDropdown<String>(
                  value: _sortBy,
                  icon: Icons.sort,
                  items: const [
                    DropdownMenuItem(value: 'fechaEmision', child: Text('Por Fecha')),
                    DropdownMenuItem(value: 'total', child: Text('Por Total')),
                    DropdownMenuItem(value: 'emisor', child: Text('Por Emisor')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                      _cargarComprobantes(_selectedUser!, _selectedYear!,
                          _selectedMonth!,
                          page: 1);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: PaperCardBase(
                  onTap: () {
                    setState(
                        () => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc');
                    _cargarComprobantes(_selectedUser!, _selectedYear!,
                        _selectedMonth!,
                        page: 1);
                  },
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Icon(
                        _sortOrder == 'asc'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 20,
                        color: const Color(0xFF0D47A1)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Mostrando $_totalComprobantes registros",
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          )
        ],
      ),
    );
  }

  // Campo de búsqueda local para filtrar en la tabla
  Widget _buildTableSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: PaperCardBase(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          controller: _tableSearchController,
          decoration: InputDecoration(
            hintText: "Buscar en tabla: RUC, Razón Social, Nº Comprobante...",
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1), size: 20),
            suffixIcon: _tableSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _tableSearchController.clear();
                      setState(() => _tableSearchQuery = '');
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (value) {
            setState(() => _tableSearchQuery = value);
          },
        ),
      ),
    );
  }

  Widget _buildPaginationPaper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
              Icons.chevron_left,
              _currentPage > 1
                  ? () => _cargarComprobantes(_selectedUser!, _selectedYear!,
                      _selectedMonth!,
                      page: _currentPage - 1)
                  : null),
          const SizedBox(width: 16),
          PaperCardBase(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
                child: Text("Pág $_currentPage / $_totalPages",
                    style: const TextStyle(fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          _buildPageButton(
              Icons.chevron_right,
              _currentPage < _totalPages
                  ? () => _cargarComprobantes(_selectedUser!, _selectedYear!,
                      _selectedMonth!,
                      page: _currentPage + 1)
                  : null),
        ],
      ),
    );
  }

  Widget _buildPageButton(IconData icon, VoidCallback? onTap) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: PaperCardBase(
        width: 40,
        padding: const EdgeInsets.all(0),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF0D47A1)),
        ),
      ),
    );
  }

  // --- TAB 3: Búsqueda ---
  Widget _buildBusquedaTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: PaperCardBase(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por RUC, Nombre...",
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Color(0xFF0D47A1)),
                  onPressed: () => _buscarComprobantes(_searchController.text),
                ),
              ),
              onSubmitted: _buscarComprobantes,
            ),
          ),
        ),
        Expanded(
          child: _comprobantes.isEmpty
              ? const Center(child: Text("Ingrese término de búsqueda"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _comprobantes.length,
                  itemBuilder: (context, index) {
                    final comp = _comprobantes[index];
                    return InvoiceListTile(
                      comp: comp,
                      onTap: () => _mostrarDetalleFactura(comp),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 4: Stats ---
  Widget _buildEstadisticasTab() {
    final usuarios = _carpetas
        .map((c) => c['username'] as String?)
        .where((u) => u != null)
        .toSet()
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: PaperDropdown<String>(
            value: _selectedUser,
            hint: "Seleccionar Usuario para Stats",
            icon: Icons.person,
            items: usuarios.map<DropdownMenuItem<String>>((username) {
              return DropdownMenuItem(value: username, child: Text(username ?? ''));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedUser = value);
                _cargarEstadisticas(value);
              }
            },
          ),
        ),
        Expanded(
          child: _estadisticas == null
              ? const Center(child: Text("Seleccione usuario"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatCardPaper("Total Comprobantes",
                          "${_estadisticas!['total_comprobantes'] ?? 0}"),
                      const SizedBox(height: 12),
                      _buildStatCardPaper("Monto Total",
                          "\$${(_estadisticas!['total_monto'] ?? 0).toStringAsFixed(2)}"),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatCardPaper(String title, String value) {
    return PaperCardBase(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1))),
        ],
      ),
    );
  }

  // DIALOGS
  void _mostrarTareasActivas() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: PaperCardBase(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("TAREAS ACTIVAS",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const Divider(height: 1),
              if (_tareasActivas.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Text("No hay tareas"))
              else
                ..._tareasActivas.map((t) => ListTile(
                      title: Text(t['task_id'] ?? ''),
                      subtitle: Text("Estado: ${t['status']}"),
                    )),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CERRAR"))
            ],
          ),
        ),
      ),
    );
  }

  // Mostrar panel de cola de descargas
  void _mostrarColaDescargas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle para arrastrar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Encabezado
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.queue, color: Color(0xFF0D47A1)),
                    const SizedBox(width: 12),
                    const Text(
                      "Cola de Descargas",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Panel de cola
              Expanded(
                child: QueuePanel(
                  username: _selectedUser ?? _carpetas.firstOrNull?['username'] ?? '',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ MODIFICACIÓN PRINCIPAL AQUÍ ============
  void _mostrarDetalleFactura(Map<String, dynamic> comp) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        // Obtenemos el tamaño de la pantalla
        final size = MediaQuery.of(context).size;
        // Calculamos el ancho deseado (95% del ancho pero máximo 900)
        final targetWidth = (size.width * 0.95).clamp(300.0, 900.0);
        
        return Dialog(
          backgroundColor: Colors.transparent,
          // Reducimos el padding externo a 8px (casi pantalla completa)
          insetPadding: const EdgeInsets.all(8), 
          child: ConstrainedBox(
            // Constraints normalizados
            constraints: BoxConstraints(
              maxWidth: targetWidth,
              minHeight: size.height * 0.5,
              maxHeight: size.height * 0.95,
            ),
            child: InvoicePaper(
              comp: comp,
              onDownload: () {
                final comprobante = comp['comprobante'] as Map<String, dynamic>?;
                final claveAcceso = comprobante?['claveAcceso']?.toString() ?? '';
                _descargarXML(claveAcceso);
              },
              onClose: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }
}