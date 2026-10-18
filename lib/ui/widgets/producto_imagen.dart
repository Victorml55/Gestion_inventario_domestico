import 'dart:io';
import 'package:flutter/material.dart';

/// Imagen del producto (o un icono si no tiene). Con [productoId] se anima
/// con un Hero entre la lista y el detalle.
class ProductoImagen extends StatelessWidget {
  final int? productoId;
  final String? path;
  final double size;
  final double radius;

  const ProductoImagen({
    super.key,
    required this.productoId,
    required this.path,
    this.size = 64,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final existe = path != null && File(path!).existsSync();
    final imagen = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: existe
            ? Image.file(File(path!), fit: BoxFit.cover)
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(Icons.inventory_2,
                    size: size * 0.45, color: Colors.grey),
              ),
      ),
    );
    if (productoId == null) return imagen;
    return Hero(tag: 'producto-$productoId', child: imagen);
  }
}
