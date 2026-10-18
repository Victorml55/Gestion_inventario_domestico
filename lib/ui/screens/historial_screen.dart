import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formato.dart';
import '../../data/models/models.dart';
import '../../data/repositories/compra_repository.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/tienda_repository.dart';

enum _Orden { reciente, gasto }

class _Datos {
  final List<HistorialCompra> compras;
  final Map<int, String> productos;
  final Map<int, String> tiendas;
  _Datos(this.compras, this.productos, this.tiendas);
}

/// Historial de compras. Si recibe [productoId] solo muestra ese producto.
class HistorialScreen extends StatefulWidget {
  final int? productoId;
  const HistorialScreen({super.key, this.productoId});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late final Future<_Datos> _futuro;
  _Orden _orden = _Orden.reciente;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_Datos> _cargar() async {
    final comprasRepo = context.read<CompraRepository>();
    final productosRepo = context.read<ProductoRepository>();
    final tiendasRepo = context.read<TiendaRepository>();

    final compras = await comprasRepo.getHistorial(productoId: widget.productoId);
    final productos = await productosRepo.getTodos();
    final tiendas = await tiendasRepo.getTodos();
    return _Datos(
      compras,
      {for (final r in productos) r.producto.id!: r.producto.nombre},
      {for (final t in tiendas) t.id!: t.nombre},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_Datos>(
        future: _futuro,
        builder: (context, snap) {
          final cargando = snap.connectionState != ConnectionState.done;
          final datos = snap.data;
          final compras = [...?datos?.compras];
          if (_orden == _Orden.gasto) {
            compras.sort((a, b) => (b.precio ?? 0).compareTo(a.precio ?? 0));
          }
          final total = compras.fold<double>(0, (s, c) => s + (c.precio ?? 0));

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(widget.productoId == null
                    ? 'Historial de compras'
                    : 'Compras del producto'),
              ),
              if (cargando)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (compras.isEmpty)
                const SliverFillRemaining(
                    child: Center(child: Text('Aún no hay compras registradas')))
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${compras.length} compra(s) • Total: ${fmtDinero(total)}',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SegmentedButton<_Orden>(
                          segments: const [
                            ButtonSegment(
                                value: _Orden.reciente,
                                icon: Icon(Icons.schedule),
                                label: Text('Recientes')),
                            ButtonSegment(
                                value: _Orden.gasto,
                                icon: Icon(Icons.attach_money),
                                label: Text('Mayor gasto')),
                          ],
                          selected: {_orden},
                          onSelectionChanged: (s) =>
                              setState(() => _orden = s.first),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final c = compras[i];
                      final producto = datos!.productos[c.productoId] ?? 'Producto';
                      final tienda = datos.tiendas[c.tiendaId] ?? 'Tienda';
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.shopping_bag_outlined)),
                        title: Text('$producto × ${c.cantidad}'),
                        subtitle: Text('$tienda • ${fmtFecha.format(c.fechaCompra)}'),
                        trailing: Text(
                          c.precio == null ? '—' : fmtDinero(c.precio!),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      );
                    },
                    childCount: compras.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          );
        },
      ),
    );
  }
}
