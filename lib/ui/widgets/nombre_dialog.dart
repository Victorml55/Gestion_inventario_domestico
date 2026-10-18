import 'package:flutter/material.dart';

class DatosCatalogo {
  final String nombre;
  final String? extra;
  const DatosCatalogo(this.nombre, this.extra);
}

/// Diálogo para crear o editar un elemento de catálogo (categoría, tienda).
/// [etiquetaExtra] agrega un segundo campo opcional (p. ej. "Dirección").
Future<DatosCatalogo?> pedirDatosCatalogo(
  BuildContext context, {
  required String titulo,
  String? nombreInicial,
  String? etiquetaExtra,
  String? extraInicial,
}) {
  return showDialog<DatosCatalogo>(
    context: context,
    builder: (_) => _CatalogoDialog(
      titulo: titulo,
      nombreInicial: nombreInicial,
      etiquetaExtra: etiquetaExtra,
      extraInicial: extraInicial,
    ),
  );
}

class _CatalogoDialog extends StatefulWidget {
  final String titulo;
  final String? nombreInicial;
  final String? etiquetaExtra;
  final String? extraInicial;

  const _CatalogoDialog({
    required this.titulo,
    this.nombreInicial,
    this.etiquetaExtra,
    this.extraInicial,
  });

  @override
  State<_CatalogoDialog> createState() => _CatalogoDialogState();
}

class _CatalogoDialogState extends State<_CatalogoDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre =
      TextEditingController(text: widget.nombreInicial);
  late final TextEditingController _extra =
      TextEditingController(text: widget.extraInicial);

  @override
  void dispose() {
    _nombre.dispose();
    _extra.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final extra = _extra.text.trim();
    Navigator.pop(
      context,
      DatosCatalogo(_nombre.text.trim(), extra.isEmpty ? null : extra),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombre,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Nombre', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
              onFieldSubmitted: (_) => _guardar(),
            ),
            if (widget.etiquetaExtra != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _extra,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                    labelText: widget.etiquetaExtra,
                    border: const OutlineInputBorder()),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
