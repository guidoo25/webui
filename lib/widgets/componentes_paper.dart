import 'package:flutter/material.dart';

const Color kPaperColor = Color(0xFFFFFFFF); // Blanco puro
const Color kInkColor = Color(0xFF0D47A1);   // Azul institucional para textos
const Color kBorderColor = Colors.black;     // Negro para bordes estilo cómic/técnico
const Color kShadowColor = Colors.black;     // Sombra negra sólida (SIN transparencia)

// Helper para formatear números
String _formatNumber(dynamic value) {
  if (value == null) return '0.00';
  if (value is num) return value.toStringAsFixed(2);
  final parsed = double.tryParse(value.toString());
  return parsed?.toStringAsFixed(2) ?? '0.00';
}

// 1. BASE DE TARJETA TIPO OFFSET PAPER (La clave del diseño)
class PaperCardBase extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double width;
  final Color backgroundColor;
  final Color borderColor;

  const PaperCardBase({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16), // Más padding interno
    this.width = double.infinity,
    this.backgroundColor = kPaperColor,
    this.borderColor = kBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        // Borde GRUESO y NEGRO
        border: Border.all(color: borderColor, width: 2),
        // Sin bordes redondeados (Estilo brutalista) o muy sutiles
        borderRadius: BorderRadius.zero, 
        // Sombra SÓLIDA (Offset puro)
        boxShadow: const [
          BoxShadow(
            color: kShadowColor,
            offset: Offset(6, 6), // Desplazamiento marcado
            blurRadius: 0,        // CERO BLUR = Efecto solido
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: kInkColor.withOpacity(0.1),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

// 2. DROPDOWN PERSONALIZADO
class PaperDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hint;
  final IconData? icon;

  const PaperDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Seleccionar',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Decoración manual para que parezca un input de papel
      decoration: BoxDecoration(
        color: kPaperColor,
        border: Border.all(color: kBorderColor, width: 2),
        boxShadow: const [
           BoxShadow(color: kShadowColor, offset: Offset(4, 4), blurRadius: 0)
        ]
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 28),
          hint: Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: Colors.black), const SizedBox(width: 8)],
              Text(hint, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'Courier', // Fuente monoespaciada
          ),
          dropdownColor: kPaperColor,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// 2.1 DROPDOWN CON BÚSQUEDA (Refactorizado al estilo Offset)
class SearchableEmisorDropdown extends StatefulWidget {
  final String? selectedRuc;
  final List<dynamic> emisores;
  final ValueChanged<String?> onChanged;
  final String hint;

  const SearchableEmisorDropdown({
    super.key,
    this.selectedRuc,
    required this.emisores,
    required this.onChanged,
    this.hint = 'FILTRAR POR EMISOR',
  });

  @override
  State<SearchableEmisorDropdown> createState() => _SearchableEmisorDropdownState();
}

class _SearchableEmisorDropdownState extends State<SearchableEmisorDropdown> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isExpanded = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_isExpanded) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, size.height + 5), // Un poco separado
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: kPaperColor,
                border: Border.all(color: kBorderColor, width: 2),
                boxShadow: const [
                   BoxShadow(color: kShadowColor, offset: Offset(6, 6), blurRadius: 0)
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo de búsqueda inverso (Negro con letras blancas)
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                      decoration: const InputDecoration(
                        hintText: 'BUSCAR EMISOR...',
                        hintStyle: TextStyle(color: Colors.white70, fontSize: 12),
                        prefixIcon: Icon(Icons.search, size: 18, color: Colors.white),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value.toLowerCase());
                        _overlayEntry?.markNeedsBuild();
                      },
                    ),
                  ),
                  
                  // Lista de opciones
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        _buildOption(null, 'TODOS LOS EMISORES', null),
                        ..._filteredEmisores.map((emisor) {
                          final nombre = emisor['nombreComercial']?.isNotEmpty == true
                              ? emisor['nombreComercial']
                              : emisor['razonSocial'];
                          final ruc = emisor['ruc']?.toString() ?? '';
                          final cantidad = emisor['cantidad'] ?? 0;
                          return _buildOption(ruc, '$nombre ($cantidad)', ruc);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  List<dynamic> get _filteredEmisores {
    if (_searchQuery.isEmpty) return widget.emisores;
    return widget.emisores.where((emisor) {
      final nombre = (emisor['nombreComercial'] ?? '').toString().toLowerCase();
      final razon = (emisor['razonSocial'] ?? '').toString().toLowerCase();
      final ruc = (emisor['ruc'] ?? '').toString().toLowerCase();
      return nombre.contains(_searchQuery) || 
             razon.contains(_searchQuery) || 
             ruc.contains(_searchQuery);
    }).toList();
  }

  Widget _buildOption(String? ruc, String label, String? subtitle) {
    final isSelected = widget.selectedRuc == ruc;
    return InkWell(
      onTap: () {
        widget.onChanged(ruc);
        _searchController.clear();
        _searchQuery = '';
        _toggleDropdown();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // Si seleccionado: Fondo amarillo suave (marcador)
        color: isSelected ? const Color(0xFFFFF9C4) : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                      color: Colors.black,
                      decoration: isSelected ? TextDecoration.underline : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      'RUC: $subtitle',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700], fontFamily: 'Courier'),
                    ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, size: 18, color: Colors.black),
          ],
        ),
      ),
    );
  }

  String get _displayText {
    if (widget.selectedRuc == null) return widget.hint;
    final selected = widget.emisores.firstWhere(
      (e) => e['ruc'] == widget.selectedRuc,
      orElse: () => null,
    );
    if (selected == null) return widget.hint;
    final nombre = selected['nombreComercial']?.isNotEmpty == true
        ? selected['nombreComercial']
        : selected['razonSocial'];
    return nombre ?? widget.hint;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kPaperColor,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
            ]
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_outlined, size: 20, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _displayText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w800,
                    color: widget.selectedRuc == null ? Colors.grey[600] : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. ITEM DE LISTA (RECIBO) - Estilo Ticket Perforado
class InvoiceListTile extends StatelessWidget {
  final Map<String, dynamic> comp;
  final VoidCallback? onTap;

  const InvoiceListTile({
    super.key,
    required this.comp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emisor = comp['emisor'] as Map<String, dynamic>? ?? {};
    final valores = comp['valores'] as Map<String, dynamic>? ?? {};
    final autorizacion = comp['autorizacion'] as Map<String, dynamic>? ?? {};
    final comprobante = comp['comprobante'] as Map<String, dynamic>? ?? {};

    final estado = autorizacion['estado']?.toString() ?? 'DESCONOCIDO';
    final esAutorizado = estado == 'AUTORIZADO';
    final nombreEmisor = emisor['nombreComercial']?.toString().isNotEmpty == true
        ? emisor['nombreComercial'].toString()
        : (emisor['razonSocial']?.toString() ?? 'Emisor desconocido');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 8), 
      child: PaperCardBase(
        onTap: onTap,
        padding: const EdgeInsets.all(0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra lateral de estado (Negra o rallada)
              Container(
                width: 10,
                color: esAutorizado ? Colors.black : Colors.red, // Negro = OK, Rojo = Error
                child: esAutorizado 
                   ? null 
                   : const Icon(Icons.warning, color: Colors.white, size: 8),
              ),
              
              // Contenido del Ticket
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado: Nombre y Monto
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              nombreEmisor.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: Colors.black,
                                fontFamily: 'Courier',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge de precio estilo "Estampa"
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "\$${_formatNumber(valores['importeTotal'])}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'Courier',
                                color: Colors.white, // Invertido para resaltar
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      // RUC
                      Text(
                        "RUC: ${emisor['ruc'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 11, color: Colors.grey[700], fontFamily: 'Courier'),
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: Colors.black, thickness: 1, height: 1), // Línea sólida
                      const SizedBox(height: 12),

                      // Detalles en Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem("FECHA", comprobante['fechaEmision'] ?? 'N/A'),
                          _buildDetailItem("SECUENCIAL", "${emisor['establecimiento']}-${emisor['puntoEmision']}-${emisor['secuencial']}"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
        ),
      ],
    );
  }
}