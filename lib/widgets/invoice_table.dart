import 'package:flutter/material.dart';

class InvoiceTable extends StatelessWidget {
  final List<dynamic> comprobantes;
  final Function(Map<String, dynamic>) onTap;

  const InvoiceTable({
    super.key,
    required this.comprobantes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colores extraídos de la imagen
    const Color headerColor = Color(0xFF0D47A1); // Azul oscuro institucional
    const Color rowColor1 = Colors.white;
    const Color rowColor2 = Color(0xFFF5F7F9); // Gris muy suave
    const Color borderColor = Color(0xFFE0E0E0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculamos el ancho mínimo basado en el contenedor padre
        final minTableWidth = constraints.maxWidth > 1200 
            ? constraints.maxWidth 
            : 1200.0; // Mínimo 1200px para que se vean bien las columnas
            
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minTableWidth),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(headerColor),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                    return null;
                  }),
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 60,
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  dataTextStyle: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                  border: TableBorder.all(color: borderColor, width: 0.5),
            
            // --- COLUMNAS (Iguales a la imagen) ---
            columns: const [
              DataColumn(label: Text('Nro')),
              DataColumn(label: Text('RUC y Razón social\nemisor')),
              DataColumn(label: Text('Tipo y N.\ncomprobante')),
              DataColumn(label: Text('Fecha de\nEmisión')),
              DataColumn(label: Text('Fecha de\nAutorización')),
              DataColumn(label: Text('Valor Sin\nImpuestos', textAlign: TextAlign.right)),
              DataColumn(label: Text('IVA', textAlign: TextAlign.right)),
              DataColumn(label: Text('Importe total', textAlign: TextAlign.right)),
              DataColumn(label: Text('Estado')),
            ],
            
            // --- FILAS ---
            rows: List<DataRow>.generate(comprobantes.length, (index) {
              final comp = comprobantes[index];
              final emisor = comp['emisor'] ?? {};
              final valores = comp['valores'] ?? {};
              final autorizacion = comp['autorizacion'] ?? {};
              final comprobante = comp['comprobante'] ?? {};

              final esPar = index % 2 == 0;
              final colorFila = esPar ? rowColor1 : rowColor2;

              // Preparar datos
              final serie = "${emisor['establecimiento']}-${emisor['puntoEmision']}-${emisor['secuencial']}";
              final estado = autorizacion['estado'] ?? 'DESCONOCIDO';
              final esAutorizado = estado == 'AUTORIZADO';

              return DataRow(
                color: WidgetStateProperty.all(colorFila),
                onSelectChanged: (_) => onTap(comp),
                cells: [
                  // 1. Nro
                  DataCell(Text("${index + 1}")),
                  
                  // 2. RUC y Razón Social
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        "${emisor['ruc'] ?? ''}\n${emisor['razonSocial'] ?? ''}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),

                  // 3. Tipo y N. Comprobante
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Text(
                        "FACTURA\n$serie",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),

                  // 4. Fecha Emisión
                  DataCell(SizedBox(
                    width: 100,
                    child: Text(comprobante['fechaEmision'] ?? ''),
                  )),

                  // 5. Fecha Autorización
                  DataCell(SizedBox(
                    width: 160,
                    child: Text(
                      (autorizacion['fechaAutorizacion'] ?? '').toString().split('.').first,
                      style: const TextStyle(fontSize: 11),
                    ),
                  )),

                  // 6. Valor Sin Impuestos
                  DataCell(SizedBox(
                    width: 100,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text("\$${(valores['totalSinImpuestos'] ?? 0).toStringAsFixed(2)}"),
                    ),
                  )),

                  // 7. IVA
                  DataCell(SizedBox(
                    width: 80,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text("\$${((valores['importeTotal'] ?? 0) - (valores['totalSinImpuestos'] ?? 0)).toStringAsFixed(2)}"),
                    ),
                  )),

                  // 8. Importe Total
                  DataCell(SizedBox(
                    width: 100,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "\$${(valores['importeTotal'] ?? 0).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )),

                  // 9. Estado (Badge)
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: esAutorizado ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: esAutorizado ? Colors.green : Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: esAutorizado ? Colors.green : Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            esAutorizado ? "Autorizado" : estado,
                            style: TextStyle(
                              color: esAutorizado ? Colors.green.shade800 : Colors.orange.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}