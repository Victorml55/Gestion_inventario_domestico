import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../data/models/models.dart';
import '../../data/repositories/carrito_repository.dart';
import '../../data/repositories/lote_repository.dart';
import '../../data/repositories/producto_repository.dart';
import '../widgets/estado_style.dart';
import 'consumo_screen.dart';

class _Datos {
  final ProductoResumen? resumen;
  final List<Lote> lotes;
  _Datos(this.resumen, this.lotes);
}

class ProductoDetalleScreen extends StatefulWidget {
  final int productoId;
  const ProductoDetalleScreen({super.key, required this.productoId});

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  late Future<_Datos> _futuro;
  final _fmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_Datos> _cargar() async {
    final resumen =
        await context.read<ProductoRepository>().getById(widget.productoId);
    final lotes =
        await context.read<LoteRepository>().getPorProducto(widget.productoId);
    lotes.sort((a, b) => a.fechaCaducidad.compareTo(b.fechaCaducidad));
    return _Datos(resumen, lotes);
  }

  void _recargar() => setState(() => _futuro = _cargar());

  Color _colorLote(Lote l) {
    if (l.cantidad == 0) return Colors.grey;
    final h = hoy();
    if (l.fechaCaducidad.isBefore(h)) return Colors.red;
    if (!l.fechaCaducidad.isAfter(h.add(const Duration(days: kDiasPorCaducar)))) {
      return Colors.orange;
    }
    return Colors.green;
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
        final lotes = snap.data!.lotes;
        final primeroFefo = lotes.indexWhere((l) => l.cantidad > 0);
        final p = r.producto;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(pinned: true, title: Text(p.nombre)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        avatar: Icon(r.estado.icono, size: 18, color: Colors.white),
                        label: Text(r.estado.etiqueta,
                            style: const TextStyle(color: Colors.white)),
                        backgroundColor: r.estado.color,
                      ),
                      const SizedBox(height: 12),
                      Text('Categoría: ${r.categoriaNombre}'),
                      Text('Stock total: ${r.stockTotal} ${p.unidad}'),
                      Text('Stock mínimo: ${p.stockMinimo} ${p.unidad}'),
                      if (r.proximaCaducidad != null)
                        Text('Próxima caducidad: ${_fmt.format(r.proximaCaducidad!)}'),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.inventory),
                    title: Text('Lotes (${lotes.length})'),
                    children: [
                      if (lotes.isEmpty)
                        const ListTile(title: Text('Este producto no tiene lotes')),
                      for (var i = 0; i < lotes.length; i++)
                        ListTile(
                          leading: Icon(Icons.circle, size: 14, color: _colorLote(lotes[i])),
                          title: Text('${lotes[i].cantidad} ${p.unidad}'),
                          subtitle: Text('Caduca: ${_fmt.format(lotes[i].fechaCaducidad)}'),
                          trailing: i == primeroFefo
                              ? const Chip(
                                  label: Text('Sale primero'),
                                  visualDensity: VisualDensity.compact)
                              : null,
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Agregado al carrito'),
                            duration: Duration(seconds: 1)));
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Al carrito'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: r.stockTotal == 0
                          ? null
                          : () async {
                              final ok = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ConsumoScreen(item: r)),
                              );
                              if (ok == true) _recargar();
                            },
                      icon: const Icon(Icons.remove_circle_outline),
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