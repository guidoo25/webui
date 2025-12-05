import 'package:flutter/material.dart';
import 'package:sri_master/models/admin_models.dart';
import 'package:sri_master/services/admin_service.dart';

class AdminFoldersPanel extends StatefulWidget {
  final List<ComprobanteFolder> folders;
  final List<SriCredential> credentials;
  final VoidCallback? onRefresh;

  const AdminFoldersPanel({
    super.key,
    required this.folders,
    required this.credentials,
    this.onRefresh,
  });

  @override
  State<AdminFoldersPanel> createState() => _AdminFoldersPanelState();
}

class _AdminFoldersPanelState extends State<AdminFoldersPanel> {
  String _selectedRuc = '';
  String _selectedYear = '';
  String _searchQuery = '';
  bool _isLoading = false;
  
  List<ComprobanteFolder> get _filteredFolders {
    return widget.folders.where((folder) {
      if (_selectedRuc.isNotEmpty && folder.ruc != _selectedRuc) return false;
      if (_selectedYear.isNotEmpty && folder.year != _selectedYear) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return folder.ruc.toLowerCase().contains(query) ||
               (folder.descripcion?.toLowerCase().contains(query) ?? false) ||
               folder.month.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  List<String> get _availableRucs {
    return widget.folders.map((f) => f.ruc).toSet().toList();
  }

  List<String> get _availableYears {
    return widget.folders.map((f) => f.year).toSet().toList()..sort((a, b) => b.compareTo(a));
  }

  int get _totalFiles {
    return _filteredFolders.fold(0, (sum, folder) => sum + folder.totalFiles);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con estadísticas
        _buildHeader(),
        
        // Filtros
        _buildFilters(),
        
        // Lista de carpetas
        Expanded(
          child: _filteredFolders.isEmpty
              ? _buildEmptyState()
              : _buildFoldersList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6A1B9A),
            const Color(0xFF8E24AA),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carpetas de Comprobantes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Comprobantes electrónicos descargados del SRI',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: widget.onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.folder_open,
                value: '${_filteredFolders.length}',
                label: 'Carpetas',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.description,
                value: '$_totalFiles',
                label: 'Archivos XML',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.business,
                value: '${_availableRucs.length}',
                label: 'RUCs',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Icons.calendar_today,
                value: '${_availableYears.length}',
                label: 'Años',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Búsqueda
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por RUC, descripción o mes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 16),
          
          // Filtro por RUC
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedRuc.isEmpty ? null : _selectedRuc,
              decoration: InputDecoration(
                hintText: 'Todos los RUCs',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Todos los RUCs'),
                ),
                ..._availableRucs.map((ruc) => DropdownMenuItem(
                  value: ruc,
                  child: Text(
                    ruc,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
              onChanged: (value) => setState(() => _selectedRuc = value ?? ''),
            ),
          ),
          const SizedBox(width: 16),
          
          // Filtro por año
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              value: _selectedYear.isEmpty ? null : _selectedYear,
              decoration: InputDecoration(
                hintText: 'Año',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Todos'),
                ),
                ..._availableYears.map((year) => DropdownMenuItem(
                  value: year,
                  child: Text(year),
                )),
              ],
              onChanged: (value) => setState(() => _selectedYear = value ?? ''),
            ),
          ),
          const SizedBox(width: 16),
          
          // Limpiar filtros
          if (_selectedRuc.isNotEmpty || _selectedYear.isNotEmpty || _searchQuery.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() {
                _selectedRuc = '';
                _selectedYear = '';
                _searchQuery = '';
              }),
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar'),
            ),
        ],
      ),
    );
  }

  Widget _buildFoldersList() {
    // Agrupar por RUC
    final groupedFolders = <String, List<ComprobanteFolder>>{};
    for (final folder in _filteredFolders) {
      groupedFolders.putIfAbsent(folder.ruc, () => []).add(folder);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedFolders.length,
      itemBuilder: (context, index) {
        final ruc = groupedFolders.keys.elementAt(index);
        final folders = groupedFolders[ruc]!;
        return _buildRucGroup(ruc, folders);
      },
    );
  }

  Widget _buildRucGroup(String ruc, List<ComprobanteFolder> folders) {
    // Ordenar por año y mes
    folders.sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) return yearCompare;
      return _getMonthNumber(b.month).compareTo(_getMonthNumber(a.month));
    });

    final totalFiles = folders.fold<int>(0, (sum, f) => sum + f.totalFiles);
    final credential = widget.credentials.where((c) => c.ruc == ruc).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: folders.length <= 3,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.business,
              color: Color(0xFF6A1B9A),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credential?.displayName ?? ruc,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (credential != null && credential.descripcion != ruc)
                      Text(
                        ruc,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                _buildMiniTag(
                  icon: Icons.folder,
                  text: '${folders.length} períodos',
                  color: const Color(0xFF6A1B9A),
                ),
                const SizedBox(width: 12),
                _buildMiniTag(
                  icon: Icons.description,
                  text: '$totalFiles archivos',
                  color: const Color(0xFF0D47A1),
                ),
              ],
            ),
          ),
          children: [
            Container(
              color: Colors.grey[50],
              child: Column(
                children: folders.map((folder) => _buildFolderItem(folder)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(ComprobanteFolder folder) {
    return InkWell(
      onTap: () => _showFolderDetails(folder),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Icon(
                Icons.folder_open,
                color: _getMonthColor(folder.month),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${folder.month} ${folder.year}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    folder.folder,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description,
                    size: 14,
                    color: Color(0xFF00897B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${folder.totalFiles}',
                    style: const TextStyle(
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showFolderDetails(ComprobanteFolder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder_open, color: _getMonthColor(folder.month)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${folder.month} ${folder.year}'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('RUC', folder.ruc),
            if (folder.descripcion != null)
              _buildDetailRow('Descripción', folder.descripcion!),
            _buildDetailRow('Período', '${folder.month} ${folder.year}'),
            _buildDetailRow('Total de archivos', '${folder.totalFiles} XMLs'),
            _buildDetailRow('Carpeta', folder.folder),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Aquí podrías navegar a la pantalla de archivos
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Ver archivos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedRuc.isNotEmpty || _selectedYear.isNotEmpty
                ? 'No se encontraron carpetas con los filtros aplicados'
                : 'No hay carpetas de comprobantes',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty && _selectedRuc.isEmpty && _selectedYear.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Descarga comprobantes del SRI para verlos aquí',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getMonthNumber(String month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months.indexOf(month) + 1;
  }

  Color _getMonthColor(String month) {
    final monthNum = _getMonthNumber(month);
    if (monthNum <= 3) return Colors.green;
    if (monthNum <= 6) return Colors.orange;
    if (monthNum <= 9) return Colors.blue;
    return Colors.purple;
  }
}
