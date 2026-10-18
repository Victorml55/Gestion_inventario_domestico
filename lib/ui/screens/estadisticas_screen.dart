import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formato.dart';
import '../../data/models/models.dart';
import '../../data/repositories/compra_repository.dart';
import '../../data/repositories/tienda_repository.dart';

class _GastoTienda {
  final String nombre;
  double total = 0;
  int compras = 0;
  int unidades = 0;
  _GastoTienda(this.nombre);
}

/// Funcionalidad extra: cuánto se ha gastado y cuántas veces se ha comprado
/// en cada tienda.
class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  late final Future<List<_GastoTienda>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<_GastoTienda>> _cargar() async {
    final comprasRepo = context.read<CompraRepository>();
    final tiendasRepo = context.read<TiendaRepository>();
    final compras = await comprasRepo.getHistorial();
    final tiendas = await tiendasRepo.getTodos();
    final nombres = {for (final Tienda t in tiendas) t.id!: t.nombre};

    final porTienda = <int, _GastoTienda>{};
    for (final c in compras) {
      final g = porTienda.putIfAbsent(
          c.tiendaId, () => _GastoTienda(nombres[c.tiendaId] ?? 'Tienda'));
      g.total += c.precio ?? 0;
      g.compras += 1;
      g.unidades += c.cantidad;
    }
    final lista = porTienda.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<_GastoTienda>>(
        future: _futuro,
        builder: (context, snap) {
          final lista = snap.data ?? [];
          final total = lista.fold<double>(0, (s, g) => s + g.total);
          final maximo = lista.isEmpty ? 0.0 : lista.first.total;

          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                  pinned: true, title: Text('Gasto por tienda')),
              if (snap.connectionState != ConnectionState.done)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (lista.isEmpty)
                const SliverFillRemaining(
                    child: Center(child: Text('Aún no hay compras registradas')))
              else ...[
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Gasto total',
                                    style: Theme.of(context).textTheme.bodySmall),
                                Text(fmtDinero(total),
                                    style:
                                        Theme.of(context).textTheme.headlineSmall),
                                Text('Tienda con más gasto: ${lista.first.nombre}',
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final g = lista[i];
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.store, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(g.nombre,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                  ),
                                  Text(fmtDinero(g.total),
                                      style:
                                          Theme.of(context).textTheme.titleMedium),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: maximo == 0 ? 0 : g.total / maximo,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${g.compras} compra(s) • ${g.unidades} unidad(es)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: lista.length,
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
