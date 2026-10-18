DateTime hoy() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime normalizarFecha(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String dateToSql(DateTime date) {
  return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

DateTime sqlToDate(String dateStr) {
  return DateTime.parse(dateStr);
}

// Alias para que la UI de tu compañero siga funcionando
DateTime soloFecha(DateTime date) => normalizarFecha(date);