import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../core/errors.dart';
import '../../core/formato.dart';
import '../../data/models/models.dart';
import '../../data/repositories/carrito_repository.dart';
import '../../data/repositories/compra_repository.dart';
import '../../data/repositories/lote_repository.dart';
import '../../data/repositories/producto_repository.dart';
import '../widgets/estado_style.dart';
import '../widgets/producto_imagen.dart';
import 'compra_form_screen.dart';
import 'consumo_screen.dart';
import 'historial_screen.dart';
import 'lote_form_sheet.dart';
import 'producto_form_screen.dart';

/// Abre el detalle de un producto. Úsalo desde cualquier lista.
Future<void> abrirDetalleProducto(BuildContext context, int productoId) {
  return Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => ProductoDetalleScreen(productoId: productoId)),
  );
}

class _Datos {
  final ProductoResumen? resumen;
  final List<Lote> lotes;
  final List<Tienda> tiendas;
  final List<HistorialCompra> compras;
  _Datos(this.resumen, this.lotes, this.tiendas, this.compras);
}

class ProductoDetalleScreen extends StatefulWidget {
  final int productoId;
  const ProductoDetalleScreen({super.key, required this.productoId});

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  late Future<_Datos> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_Datos> _cargar() async {
    final productos = context.read<ProductoRepository>();
    final lotesRepo = context.read<LoteRepository>();
    final comprasRepo = context.read<CompraRepository>();

    final resumen = await productos.getById(widget.productoId);
    final lotes = await lotesRepo.getPorProducto(widget.productoId);
    final tiendas = await comprasRepo.getTiendasDeProducto(widget.productoId);
    final compras = await comprasRepo.getHistorial(productoId: widget.productoId);

    lotes.sort((a, b) {
      if (a.fechaCaducidad == null) return b.fechaCaducidad == null ? 0 : 1;
      if (b.fechaCaducidad == null) return -1;
      return a.fechaCaducidad!.compareTo(b.fechaCaducidad!);
    });
    return _Datos(resumen, lotes, tiendas, compras);
  }

  void _recargar() {
  if (!mounted) return;
  final futuro = _cargar();
  setState(() {
    _futuro = futuro;
  });
}

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _colorLote(Lote l) {
    if (l.cantidad == 0) return Colors.grey;
    final f = l.fechaCaducidad;
    if (f == null) return Colors.green;
    final h = hoy();
    if (f.isBefore(h)) return Colors.red;
    if (!f.isAfter(h.add(const Duration(days: kDiasPorCaducar)))) {
      return Colors.orange;
    }
    return Colors.green;
  }

  Future<bool> _confirmar(String titulo, String mensaje) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _editarProducto(Producto p) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductoFormScreen(producto: p)),
    );
    if (ok == true) _recargar();
  }

  Future<void> _eliminarProducto(Producto p) async {
    final repo = context.read<ProductoRepository>();
    final navigator = Navigator.of(context);
    final ok = await _confirmar('Eliminar producto',
        '¿Eliminar "${p.nombre}"? También se borrarán sus lotes e historial de compras.');
    if (!ok) return;
    try {
      await repo.eliminar(p.id!);
      navigator.pop(true);
    } on AppException catch (e) {
      _aviso(e.mensaje);
    } catch (e) {
      _aviso('Error: $e');
    }
  }

  Future<void> _eliminarLote(Lote l) async {
    final repo = context.read<LoteRepository>();
    final ok = await _confirmar('Eliminar lote', '¿Eliminar este lote?');
    if (!ok) return;
    try {
      await repo.eliminar(l.id!);
      _recargar();
    } on AppException catch (e) {
      _aviso(e.mensaje);
    } catch (e) {
      _aviso('Error: $e');
    }
  }

  Future<void> _lote(Producto p, {Lote? lote}) async {
    final ok = await mostrarLoteSheet(context, producto: p, lote: lote);
    if (ok == true) _recargar();
  }

  Future<void> _comprar(Producto p) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CompraFormScreen(productoId: p.id)),
    );
    if (ok == true) _recargar();
  }

  Future<void> _consumir(ProductoResumen r) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ConsumoScreen(item: r)),
    );
    if (ok == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Datos>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()));
        }
        final r = snap.data?.resumen;
        if (r == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Producto no encontrado')));
        }
        final datos = snap.data!;
        final lotes = datos.lotes;
        final primeroFefo = lotes.indexWhere((l) => l.cantidad > 0);
        final p = r.producto;
        final recientes = datos.compras.take(5).toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(p.nombre),
                actions: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editarProducto(p),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _eliminarProducto(p),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductoImagen(
                          productoId: p.id,
                          path: p.imagenPath,
                          size: 96,
                          radius: 16),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Chip(
                              avatar: Icon(r.estado.icono,
                                  size: 18, color: Colors.white),
                              label: Text(r.estado.etiqueta,
                                  style: const TextStyle(color: Colors.white)),
                              backgroundColor: r.estado.color,
                            ),
                            const SizedBox(height: 8),
                            Text('Categoría: ${r.categoriaNombre}'),
                            Text('Stock total: ${r.stockTotal} ${p.unidad}'),
                            Text('Stock mínimo: ${p.stockMinimo} ${p.unidad}'),
                            if (r.proximaCaducidad != null)
                              Text(
                                  'Próxima caducidad: ${fmtFecha.format(r.proximaCaducidad!)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- Trazabilidad de tiendas ----------
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trazabilidad de tiendas',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.store, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(r.ultimaTiendaNombre == null
                                ? 'Sin compras registradas'
                                : 'Última compra en: ${r.ultimaTiendaNombre}'),
                          ),
                        ]),
                        if (datos.tiendas.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Se ha comprado en:'),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final t in datos.tiendas)
                                Chip(
                                  label: Text(t.nombre),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ---------- Lotes (CRUD) ----------
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.inventory),
                    title: Text('Lotes (${lotes.length})'),
                    children: [
                      if (lotes.isEmpty)
                        const ListTile(
                            title: Text('Este producto no tiene lotes')),
                      for (var i = 0; i < lotes.length; i++)
                        ListTile(
                          leading: Icon(Icons.circle,
                              size: 14, color: _colorLote(lotes[i])),
                          title: Text('${lotes[i].cantidad} ${p.unidad}'),
                          subtitle: Text(lotes[i].fechaCaducidad == null
                              ? 'Sin caducidad'
                              : 'Caduca: ${fmtFecha.format(lotes[i].fechaCaducidad!)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (i == primeroFefo)
                                const Chip(
                                    label: Text('Sale primero'),
                                    visualDensity: VisualDensity.compact),
                              PopupMenuButton<String>(
                                onSelected: (v) => v == 'editar'
                                    ? _lote(p, lote: lotes[i])
                                    : _eliminarLote(lotes[i]),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'editar', child: Text('Editar')),
                                  PopupMenuItem(
                                      value: 'eliminar',
                                      child: Text('Eliminar')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('Agregar lote'),
                        onTap: () => _lote(p),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- Historial reciente ----------
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('Compras (${datos.compras.length})'),
                    children: [
                      if (recientes.isEmpty)
                        const ListTile(title: Text('Aún no hay compras')),
                      for (final c in recientes)
                        ListTile(
                          dense: true,
                          title: Text('${c.cantidad} ${p.unidad}'),
                          subtitle: Text(fmtFecha.format(c.fechaCompra)),
                          trailing: c.precio == null
                              ? null
                              : Text(fmtDinero(c.precio!)),
                        ),
                      if (datos.compras.length > 5)
                        ListTile(
                          title: const Text('Ver todas'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    HistorialScreen(productoId: p.id)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<CarritoRepository>().agregar(p.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Agregado al carrito'),
                                duration: Duration(seconds: 1)));
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Carrito'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _comprar(p),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Comprar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: r.stockTotal == 0 ? null : () => _consumir(r),
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text('Consumir'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
