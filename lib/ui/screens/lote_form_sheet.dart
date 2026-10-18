import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/date_utils.dart';
import '../../core/errors.dart';
import '../../core/formato.dart';
import '../../data/models/models.dart';
import '../../data/repositories/lote_repository.dart';

/// Hoja deslizable (DraggableScrollableSheet) para agregar o editar un lote.
/// Devuelve true si se guardó.
Future<bool?> mostrarLoteSheet(
  BuildContext context, {
  required Producto producto,
  Lote? lote,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _LoteSheet(producto: producto, lote: lote),
  );
}

class _LoteSheet extends StatefulWidget {
  final Producto producto;
  final Lote? lote;
  const _LoteSheet({required this.producto, this.lote});

  @override
  State<_LoteSheet> createState() => _LoteSheetState();
}

class _LoteSheetState extends State<_LoteSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cantidad = TextEditingController(
      text: widget.lote == null ? '1' : '${widget.lote!.cantidad}');
  late bool _sinCaducidad = widget.lote != null && widget.lote!.fechaCaducidad == null;
  late DateTime? _caducidad = widget.lote?.fechaCaducidad;
  late bool _alarma = widget.lote?.alarmaActiva ?? true;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _caducidad ?? hoy(),
      firstDate: hoy().subtract(const Duration(days: 365)),
      lastDate: hoy().add(const Duration(days: 3650)),
      locale: const Locale('es', 'MX'),
    );
    if (f != null) setState(() => _caducidad = soloFecha(f));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_sinCaducidad && _caducidad == null) {
      setState(() => _error = 'Elige la fecha de caducidad o marca "Sin caducidad"');
      return;
    }
    final repo = context.read<LoteRepository>();
    final navigator = Navigator.of(context);
    final nuevo = Lote(
      id: widget.lote?.id,
      productoId: widget.producto.id!,
      cantidad: int.parse(_cantidad.text),
      fechaCaducidad: _sinCaducidad ? null : _caducidad,
      alarmaActiva: _sinCaducidad ? false : _alarma,
      fechaIngreso: widget.lote?.fechaIngreso ?? hoy(),
    );

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      if (widget.lote == null) {
        await repo.insertar(nuevo);
      } else {
        await repo.actualizar(nuevo);
      }
      navigator.pop(true);
    } on AppException catch (e) {
      if (mounted) setState(() { _error = e.mensaje; _guardando = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _guardando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.lote != null;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        final teclado = MediaQuery.of(context).viewInsets.bottom;
        return Form(
          key: _formKey,
          child: ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + teclado),
            children: [
              Text(editando ? 'Editar lote' : 'Nuevo lote',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(widget.producto.nombre,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cantidad,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad (${widget.producto.unidad})',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null) return 'Número inválido';
                  if (n < (editando ? 0 : 1)) {
                    return editando ? 'No puede ser negativa' : 'Mínimo 1';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sin caducidad'),
                subtitle: const Text('Producto no perecedero'),
                value: _sinCaducidad,
                onChanged: (v) => setState(() => _sinCaducidad = v),
              ),
              if (!_sinCaducidad) ...[
                OutlinedButton.icon(
                  onPressed: _elegirFecha,
                  icon: const Icon(Icons.event),
                  label: Text(_caducidad == null
                      ? 'Fecha de caducidad'
                      : fmtFecha.format(_caducidad!)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alarma de caducidad'),
                  subtitle: const Text('Avisar el día que caduca'),
                  value: _alarma,
                  onChanged: (v) => setState(() => _alarma = v),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save),
                label: const Text('Guardar lote'),
              ),
            ],
          ),
        );
      },
    );
  }
}
