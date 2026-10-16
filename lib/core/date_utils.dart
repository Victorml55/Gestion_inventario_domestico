DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime hoy() => soloFecha(DateTime.now());