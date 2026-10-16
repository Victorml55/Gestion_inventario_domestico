import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/models.dart';
import 'estado_style.dart';

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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: p.imagenPath != null
                        ? Image.file(File(p.imagenPath!), fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.inventory_2, color: Colors.grey),
                          ),
                  ),
                ),
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
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: e.color,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      Text('Stock: ${item.stockTotal} ${p.unidad}'
                          '${fecha != null ? '  •  Cad: ${DateFormat('dd/MM/yyyy').format(fecha)}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall),
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