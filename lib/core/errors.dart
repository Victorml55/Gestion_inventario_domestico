class AppException implements Exception {
  final String mensaje;
  AppException(this.mensaje);
  @override
  String toString() => mensaje;
}