import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../data/repositories/calendario_repository.dart';
import '../../data/repositories/carrito_repository.dart';
import '../widgets/producto_card.dart';

class DiaAlertasScreen extends StatelessWidget {
  final DateTime dia;
  const DiaAlertasScreen({super.key, required this.dia});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalendarioRepository>();
    final carrito = context.read<CarritoRepository>();
    final titulo = DateFormat("EEEE d 'de' MMMM yyyy", 'es_MX').format(dia);

    return Scaffold(
      body: FutureBuilder<List<ProductoResumen>>(
        future: repo.getAlertasDeDia(dia),
        builder: (context, snap) {
          final items = snap.data ?? [];
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(titulo, style: const TextStyle(fontSize: 16)),
              ),
              if (snap.connectionState != ConnectionState.done)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (items.isEmpty)
                const SliverFillRemaining(
                    child: Center(child: Text('Sin alertas para este día')))
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('${items.length} producto(s) con alerta',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ProductoCard(
                      item: items[i],
                      onAgregarCarrito: () {
                        carrito.agregar(items[i].producto.id!);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                '${items[i].producto.nombre} agregado al carrito'),
                            duration: const Duration(seconds: 1)));
                      },
                    ),
                    childCount: items.length,
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