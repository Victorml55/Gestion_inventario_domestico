import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as ruta;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/date_utils.dart';
import '../../core/formato.dart';
import '../../data/models/models.dart';
import '../../data/repositories/categoria_repository.dart';
import '../../data/repositories/lote_repository.dart';
import '../../data/repositories/producto_repository.dart';

/// Crea un producto (con su primer lote) o edita uno existente.
class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;
  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  static const _unidadesBase = ['pza', 'kg', 'g', 'L', 'ml', 'paq'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _stockMin;
  final _cantidad = TextEditingController(text: '1');

  late final Future<List<Categoria>> _categorias;
  late final List<String> _unidades;
  int? _categoriaId;
  late String _unidad;
  String? _imagenPath;
  DateTime? _caducidad;
  bool _sinCaducidad = false;
  bool _alarma = true;
  bool _guardando = false;

  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _stockMin = TextEditingController(text: '${p?.stockMinimo ?? 1}');
    _categoriaId = p?.categoriaId;
    _unidad = p?.unidad ?? 'pza';
    _imagenPath = p?.imagenPath;
    _unidades = [
      ..._unidadesBase,
      if (!_unidadesBase.contains(_unidad)) _unidad,
    ];
    _categorias = context.read<CategoriaRepository>().getTodos();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _stockMin.dispose();
    _cantidad.dispose();
    super.dispose();
  }

  Future<void> _elegirImagen(ImageSource fuente) async {
    final x = await ImagePicker()
        .pickImage(source: fuente, maxWidth: 1024, imageQuality: 80);
    if (x == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final destino = ruta.join(dir.path,
        '${DateTime.now().millisecondsSinceEpoch}${ruta.extension(x.path)}');
    await File(x.path).copy(destino);
    if (mounted) setState(() => _imagenPath = destino);
  }

  void _menuImagen() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Tomar foto'),
            onTap: () {
              Navigator.pop(context);
              _elegirImagen(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Elegir de la galería'),
            onTap: () {
              Navigator.pop(context);
              _elegirImagen(ImageSource.gallery);
            },
          ),
          if (_imagenPath != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Quitar imagen'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _imagenPath = null);
              },
            ),
        ]),
      ),
    );
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
    final cantidad = _editando ? 0 : int.parse(_cantidad.text);
    if (!_editando && cantidad > 0 && !_sinCaducidad && _caducidad == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Elige la fecha de caducidad o marca "Sin caducidad"')));
      return;
    }

    final productos = context.read<ProductoRepository>();
    final lotes = context.read<LoteRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _guardando = true);
    try {
      if (_editando) {
        final p = widget.producto!;
        await productos.actualizar(Producto(
          id: p.id,
          nombre: _nombre.text.trim(),
          categoriaId: _categoriaId!,
          imagenPath: _imagenPath,
          unidad: _unidad,
          stockMinimo: int.parse(_stockMin.text),
          ultimaTiendaId: p.ultimaTiendaId,
        ));
      } else {
        final id = await productos.insertar(Producto(
          nombre: _nombre.text.trim(),
          categoriaId: _categoriaId!,
          imagenPath: _imagenPath,
          unidad: _unidad,
          stockMinimo: int.parse(_stockMin.text),
        ));
        if (cantidad > 0) {
          await lotes.insertar(Lote(
            productoId: id,
            cantidad: cantidad,
            fechaCaducidad: _sinCaducidad ? null : _caducidad,
            alarmaActiva: _sinCaducidad ? false : _alarma,
            fechaIngreso: hoy(),
          ));
        }
      }
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _guardando = false);
    }
  }

  String? _entero(String? v, {int min = 0}) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Número inválido';
    if (n < min) return 'Mínimo $min';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final existeImagen = _imagenPath != null && File(_imagenPath!).existsSync();
    return Scaffold(
      appBar: AppBar(
          title: Text(_editando ? 'Editar producto' : 'Nuevo producto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _menuImagen,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey.shade200,
                    child: existeImagen
                        ? Image.file(File(_imagenPath!), fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 32),
                              SizedBox(height: 4),
                              Text('Imagen'),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Nombre', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Categoria>>(
              future: _categorias,
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                final cats = snap.data!;
                return DropdownButtonFormField<int>(
                  initialValue: cats.any((c) => c.id == _categoriaId)
                      ? _categoriaId
                      : null,
                  decoration: const InputDecoration(
                      labelText: 'Categoría', border: OutlineInputBorder()),
                  items: [
                    for (final c in cats)
                      DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                  ],
                  onChanged: (v) => setState(() => _categoriaId = v),
                  validator: (v) => v == null ? 'Elige una categoría' : null,
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unidad,
                    decoration: const InputDecoration(
                        labelText: 'Unidad', border: OutlineInputBorder()),
                    items: [
                      for (final u in _unidades)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) => setState(() => _unidad = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockMin,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Stock mínimo',
                        border: OutlineInputBorder()),
                    validator: (v) => _entero(v),
                  ),
                ),
              ],
            ),
            if (!_editando) ...[
              const SizedBox(height: 24),
              Text('Primer lote',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Pon cantidad 0 si aún no tienes unidades.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cantidad,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Cantidad', border: OutlineInputBorder()),
                validator: (v) => _entero(v),
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
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
