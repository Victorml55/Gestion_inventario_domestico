import 'package:intl/intl.dart';

final DateFormat fmtFecha = DateFormat('dd/MM/yyyy');

String fmtDinero(double v) => '\$${v.toStringAsFixed(2)}';
