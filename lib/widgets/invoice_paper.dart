import 'package:flutter/material.dart';

// Helper para formatear números de forma segura
String _formatNumber(dynamic value) {
  if (value == null) return '0.00';
  if (value is num) return value.toStringAsFixed(2);
  final parsed = double.tryParse(value.toString());
  return parsed?.toStringAsFixed(2) ?? '0.00';
}

// Helper para parsear números de forma segura
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

class InvoicePaper extends StatelessWidget {
  final Map<String, dynamic> comp;
  final VoidCallback onDownload;
  final VoidCallback onClose;

  const InvoicePaper({
    super.key,
    required this.comp,
    required this.onDownload,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Extracción segura de datos
    final emisor = comp['emisor'] ?? {};
    final valores = comp['valores'] ?? {};
    final autorizacion = comp['autorizacion'] ?? {};
    final comprobante = comp['comprobante'] ?? {};
    final detalles = comp['detalles'] as List<dynamic>? ?? [];
    final infoAdicional = comp['infoAdicional'] as Map<String, dynamic>? ?? {};

    final nombreEmisor = emisor['nombreComercial']?.isNotEmpty == true
        ? emisor['nombreComercial']
        : (emisor['razonSocial'] ?? 'Emisor');

    // Asegurar que nombreEmisor no esté vacío para substring
    final primeraLetra = nombreEmisor.isNotEmpty ? nombreEmisor.substring(0, 1).toUpperCase() : 'E';

    final estado = autorizacion['estado'] ?? 'DESCONOCIDO';
    final esAutorizado = estado == 'AUTORIZADO';

    // Paleta de colores "Paper & Ink"
    final Color paperColor = const Color(0xFFFAFAFA); // Blanco hueso
    final Color inkColor = const Color(0xFF0D47A1);   // Azul oscuro institucional
    final Color labelColor = const Color(0xFF7F8C8D); // Gris piedra
    final Color dividerColor = const Color(0xFFBDC3C7);// Gris claro

    return Container(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 850),
      decoration: BoxDecoration(
        color: paperColor,
        borderRadius: BorderRadius.circular(2), // Bordes casi rectos (papel)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          // --- CUERPO DEL PAPEL (Scrollable) ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. CABECERA
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Simulación de Logo (Círculo con inicial)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border.all(color: inkColor, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            primeraLetra,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                              color: inkColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Datos Emisor
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreEmisor.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: inkColor,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "RUC: ${emisor['ruc']}",
                              style: TextStyle(color: labelColor, fontSize: 12),
                            ),
                            Text(
                              emisor['direccion'] ?? '',
                              style: TextStyle(color: labelColor, fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Divider(color: inkColor, thickness: 2),
                  const SizedBox(height: 30),

                  // 2. DATOS CLIENTE Y FACTURA
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Izquierda: Cliente
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LabelText("FACTURAR A:", labelColor),
                            const SizedBox(height: 5),
                            Text(
                              comprobante['razonSocialComprador'] ?? 'Consumidor Final',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: inkColor,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "ID: ${comprobante['identificacionComprador']}",
                              style: TextStyle(color: inkColor, fontSize: 13),
                            ),
                            if (comprobante['direccionComprador'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  comprobante['direccionComprador'],
                                  style: TextStyle(color: inkColor, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Derecha: Detalles Factura
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _LabelText("NÚMERO DE FACTURA", labelColor),
                            Text(
                              "${emisor['establecimiento']}-${emisor['puntoEmision']}-${emisor['secuencial']}",
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: inkColor,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _LabelText("FECHA DE EMISIÓN", labelColor),
                            Text(
                              comprobante['fechaEmision'] ?? '',
                              style: TextStyle(color: inkColor, fontSize: 13),
                            ),
                            const SizedBox(height: 15),
                            // Sello de Estado
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: esAutorizado ? Colors.green.shade800 : Colors.orange.shade800,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                estado,
                                style: TextStyle(
                                  color: esAutorizado ? Colors.green.shade800 : Colors.orange.shade800,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 3. TABLA DE ITEMS
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: inkColor, width: 2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: _LabelText("DESCRIPCIÓN", inkColor)),
                        Expanded(flex: 1, child: Center(child: _LabelText("CANT", inkColor))),
                        Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: _LabelText("P. UNIT", inkColor))),
                        Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: _LabelText("TOTAL", inkColor))),
                      ],
                    ),
                  ),
                  // Lista Items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detalles.length,
                    separatorBuilder: (c, i) => Divider(color: dividerColor.withOpacity(0.5), height: 1),
                    itemBuilder: (context, index) {
                      final item = detalles[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 4,
                                child: Text(
                                  item['descripcion'] ?? 'Item',
                                  style: TextStyle(color: inkColor, fontSize: 13),
                                )
                            ),
                            Expanded(
                                flex: 1,
                                child: Center(
                                    child: Text(
                                      "${item['cantidad'] ?? 0}",
                                      style: TextStyle(color: inkColor, fontSize: 13, fontFamily: 'monospace'),
                                    )
                                )
                            ),
                            Expanded(
                                flex: 2,
                                child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "\$${_formatNumber(item['precioUnitario'])}",
                                      style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: inkColor),
                                    )
                                )
                            ),
                            Expanded(
                                flex: 2,
                                child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "\$${_formatNumber(item['precioTotalSinImpuesto'])}",
                                      style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: inkColor),
                                    )
                                )
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  Divider(color: inkColor, thickness: 1),
                  const SizedBox(height: 20),

                  // 4. TOTALES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _RowTotal("Subtotal", _parseDouble(valores['totalSinImpuestos']), false),
                          if (_parseDouble(valores['totalDescuento']) > 0)
                            _RowTotal("Descuento", _parseDouble(valores['totalDescuento']), false, isNegative: true),
                          
                          // Cálculo aproximado de impuestos si no vienen desglosados
                          if (_parseDouble(valores['importeTotal']) - _parseDouble(valores['totalSinImpuestos']) > 0)
                            _RowTotal("Impuestos", _parseDouble(valores['importeTotal']) - _parseDouble(valores['totalSinImpuestos']), false),
                          
                          const SizedBox(height: 10),
                          Container(height: 1, width: 180, color: inkColor),
                          const SizedBox(height: 5),
                          
                          // Total Final
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("TOTAL", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: inkColor)),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 120,
                                child: Text(
                                  "\$${_formatNumber(valores['importeTotal'])}",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: inkColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Doble línea estilo contable
                          Container(height: 3, width: 180, color: inkColor),
                          const SizedBox(height: 2),
                          Container(height: 1, width: 180, color: inkColor),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // 5. FOOTER (Info Técnica)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      border: Border.all(color: dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LabelText("INFORMACIÓN ADICIONAL", inkColor),
                        const SizedBox(height: 8),
                        if (infoAdicional.isNotEmpty)
                          ...infoAdicional.entries.take(4).map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              "${e.key}: ${e.value}",
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ))
                        else
                          const Text("Sin información adicional", style: TextStyle(fontSize: 11)),
                        const SizedBox(height: 12),
                        _LabelText("CLAVE DE ACCESO", inkColor),
                        SelectableText(
                          comprobante['claveAcceso'] ?? '',
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BARRA DE ACCIONES (Fuera del papel) ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text("Cerrar"),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text("Descargar XML"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inkColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Widgets privados de ayuda para InvoicePaper
class _LabelText extends StatelessWidget {
  final String text;
  final Color color;
  const _LabelText(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _RowTotal extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBig;
  final bool isNegative;

  const _RowTotal(this.label, this.amount, this.isBig, {this.isNegative = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label:",
            style: TextStyle(
              fontSize: isBig ? 14 : 12,
              fontWeight: isBig ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 120,
            child: Text(
              "${isNegative ? '-' : ''}\$${amount.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: isBig ? 16 : 13,
                fontWeight: isBig ? FontWeight.bold : FontWeight.normal,
                color: isNegative ? Colors.red.shade700 : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}