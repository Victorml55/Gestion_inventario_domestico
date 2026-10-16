import 'package:flutter/material.dart';
import '../../data/models/models.dart';

extension EstadoStyle on EstadoProducto {
  Color get color => switch (this) {
        EstadoProducto.sinExistencia => Colors.blueGrey.shade700,
        EstadoProducto.caducado => Colors.red,
        EstadoProducto.porCaducar => Colors.orange,
        EstadoProducto.porAgotarse => Colors.amber.shade700,
        EstadoProducto.normal => Colors.green,
      };

  IconData get icono => switch (this) {
        EstadoProducto.sinExistencia => Icons.remove_shopping_cart,
        EstadoProducto.caducado => Icons.dangerous,
        EstadoProducto.porCaducar => Icons.hourglass_bottom,
        EstadoProducto.porAgotarse => Icons.warning_amber,
        EstadoProducto.normal => Icons.check_circle,
      };

  String get etiqueta => switch (this) {
        EstadoProducto.sinExistencia => 'Agotado',
        EstadoProducto.caducado => 'Caducado',
        EstadoProducto.porCaducar => 'Por caducar',
        EstadoProducto.porAgotarse => 'Por agotarse',
        EstadoProducto.normal => 'Normal',
      };
}