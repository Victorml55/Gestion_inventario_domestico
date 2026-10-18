import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/date_utils.dart';
import '../../core/errors.dart';
import '../../core/formato.dart';
import '../../data/models/models.dart';
import '../../data/repositories/compra_repository.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/tienda_repository.dart';
import '../widgets/nombre_dialog.dart';

/// Registra una compra: guarda el historial, actualiza la última tienda del
/// producto y crea el lote correspondiente (todo en una transacción).
/// Devuelve true si se registró.
class CompraFormScreen extends StatefulWidget {
  final int? productoId;
  final int cantidadInicial;
  const CompraFormScreen({super.key, this.productoId, this.cantidadInicial = 1});

  @override
  State<CompraFormScreen> createState() => _CompraFormScreenState();
}

class _CompraFormScreenState extends State<CompraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cantidad =
      TextEditingController(text: '${widget.cantidadInicial}');
  final _precio = TextEditingController();

  List<ProductoResumen> _productos = [];
  List<Tienda> _tiendas = [];
  bool _cargando = true;
  bool _guardando = false;

  int? _productoId;
  int? _tiendaId;
  DateTime _fechaCompra = hoy();
  bool _sinCaducidad = false;
  DateTime? _caducidad;
  bool _alarma = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _cantidad.dispose();
    _precio.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final productosRepo = context.read<ProductoRepository>();
    final tiendasRepo = context.read<TiendaRepository>();
    final p = await productosRepo.getTodos();
    final t = await tiendasRepo.getTodos();
    if (!mounted) return;
    setState(() {
      _productos = p;
      _tiendas = t;
      final inicial = p.where((r) => r.producto.id == widget.productoId);
      if (inicial.isNotEmpty) {
        _productoId = widget.productoId;
        final ultima = inicial.first.producto.ultimaTiendaId;
        if (t.any((x) => x.id == ultima)) _tiendaId = ultima;
      }
      _cargando = false;
    });
  }

  Future<void> _nuevaTienda() async {
    final repo = context.read<TiendaRepository>();
    final datos = await pedirDatosCatalogo(
      context,
      titulo: 'Nueva tienda',
      etiquetaExtra: 'Dirección (opcional)',
    );
    if (datos == null) return;
    try {
      final id =
          await repo.insertar(Tienda(nombre: datos.nombre, direccion: datos.extra));
      final t = await repo.getTodos();
      if (!mounted) return;
      setState(() {
        _tiendas = t;
        _tiendaId = id;
      });
    } on AppException catch (e) {
      _aviso(e.mensaje);
    } catch (e) {
      _aviso('Error: $e');
    }
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<DateTime?> _fecha(DateTime inicial, DateTime desde, DateTime hasta) {
    return showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: desde,
      lastDate: hasta,
      locale: const Locale('es', 'MX'),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_sinCaducidad && _caducidad == null) {
      _aviso('Elige la fecha de caducidad o marca "Sin caducidad"');
      return;
    }
    final repo = context.read<CompraRepository>();
    final navigator = Navigator.of(context);
    final cantidad = int.parse(_cantidad.text);
    final precioTxt = _precio.text.trim().replaceAll(',', '.');

    setState(() => _guardando = true);
    try {
      await repo.registrarCompraConLote(
        HistorialCompra(
          productoId: _productoId!,
          tiendaId: _tiendaId!,
          cantidad: cantidad,
          precio: precioTxt.isEmpty ? null : double.parse(precioTxt),
          fechaCompra: _fechaCompra,
        ),
        Lote(
          productoId: _productoId!,
          cantidad: cantidad,
          fechaCaducidad: _sinCaducidad ? null : _caducidad,
          alarmaActiva: _sinCaducidad ? false : _alarma,
          fechaIngreso: _fechaCompra,
        ),
      );
      navigator.pop(true);
    } on AppException catch (e) {
      _aviso(e.mensaje);
      if (mounted) setState(() => _guardando = false);
    } catch (e) {
      _aviso('Error: $e');
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar compra')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _productoId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Producto', border: OutlineInputBorder()),
                    items: [
                      for (final r in _productos)
                        DropdownMenuItem(
                            value: r.producto.id, child: Text(r.producto.nombre)),
                    ],
                    onChanged: (v) => setState(() => _productoId = v),
                    validator: (v) => v == null ? 'Elige un producto' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('tienda-${_tiendas.length}-$_tiendaId'),
                          initialValue: _tiendaId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Tienda', border: OutlineInputBorder()),
                          items: [
                            for (final t in _tiendas)
                              DropdownMenuItem(value: t.id, child: Text(t.nombre)),
                          ],
                          onChanged: (v) => setState(() => _tiendaId = v),
                          validator: (v) => v == null ? 'Elige una tienda' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Nueva tienda',
                        onPressed: _nuevaTienda,
                        icon: const Icon(Icons.add_business),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cantidad,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Cantidad',
                              border: OutlineInputBorder()),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null) return 'Número inválido';
                            if (n < 1) return 'Mínimo 1';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _precio,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Precio total',
                              prefixText: '\$ ',
                              border: OutlineInputBorder()),
                          validator: (v) {
                            final t = (v ?? '').trim().replaceAll(',', '.');
                            if (t.isEmpty) return null;
                            final n = double.tryParse(t);
                            if (n == null || n < 0) return 'Precio inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final f = await _fecha(
                          _fechaCompra,
                          hoy().subtract(const Duration(days: 3650)),
                          hoy());
                      if (f != null) setState(() => _fechaCompra = soloFecha(f));
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: Text('Fecha de compra: ${fmtFecha.format(_fechaCompra)}'),
                  ),
                  const SizedBox(height: 16),
                  Text('Lote que entra a la alacena',
                      style: Theme.of(context).textTheme.titleMedium),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sin caducidad'),
                    subtitle: const Text('Producto no perecedero'),
                    value: _sinCaducidad,
                    onChanged: (v) => setState(() => _sinCaducidad = v),
                  ),
                  if (!_sinCaducidad) ...[
                    OutlinedButton.icon(
                      onPressed: () async {
                        final f = await _fecha(
                            _caducidad ?? hoy(),
                            hoy().subtract(const Duration(days: 365)),
                            hoy().add(const Duration(days: 3650)));
                        if (f != null) setState(() => _caducidad = soloFecha(f));
                      },
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
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: const Icon(Icons.check),
                    label: const Text('Registrar compra'),
                  ),
                ],
              ),
            ),
    );
  }
}
