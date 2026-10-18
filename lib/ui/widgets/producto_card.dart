import 'package:flutter/material.dart';
import '../../core/formato.dart';
import '../../data/models/models.dart';
import 'estado_style.dart';
import 'producto_imagen.dart';

class ProductoCard extends StatelessWidget {
  final ProductoResumen item;
  final VoidCallback onAgregarCarrito;
  final VoidCallback? onTap;

  const ProductoCard({
    super.key,
    required this.item,
    required this.onAgregarCarrito,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.producto;
    final e = item.estado;
    final fecha = item.proximaCaducidad;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: e.color), // franja de estatus
              Padding(
                padding: const EdgeInsets.all(10),
                child: ProductoImagen(productoId: p.id, path: p.imagenPath),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nombre,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Chip(
                        avatar: Icon(e.icono, size: 16, color: Colors.white),
                        label: Text(e.etiqueta,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                        backgroundColor: e.color,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      Text(
                        'Stock: ${item.stockTotal} ${p.unidad}'
                        '${fecha != null ? '  •  Cad: ${fmtFecha.format(fecha)}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Agregar al carrito',
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: onAgregarCarrito,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
