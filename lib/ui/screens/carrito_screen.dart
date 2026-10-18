import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import '../widgets/estado_style.dart';
import 'compra_form_screen.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<CarritoProvider>().cargar());
  }

  Future<void> _vaciar(CarritoProvider prov) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Quitar todos los productos?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vaciar')),
        ],
      ),
    );
    if (ok == true) prov.vaciar();
  }

  Future<void> _sugerir(CarritoProvider prov) async {
    final messenger = ScaffoldMessenger.of(context);
    final n = await prov.agregarSugeridos();
    messenger.showSnackBar(SnackBar(
        content: Text(n == 0
            ? 'No hay productos agotados que agregar'
            : 'Se agregaron $n producto(s) agotados o por agotarse')));
  }

  /// Registra la compra del producto y, si se guardó, lo quita de la lista.
  Future<void> _comprar(CarritoProvider prov, int productoId, int cantidad) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CompraFormScreen(productoId: productoId, cantidadInicial: cantidad),
      ),
    );
    if (ok == true) {
      await prov.quitar(productoId);
      messenger.showSnackBar(
          const SnackBar(content: Text('Compra registrada y lote agregado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CarritoProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Lista de compra'),
            actions: [
              IconButton(
                tooltip: 'Agregar agotados',
                icon: const Icon(Icons.playlist_add),
                onPressed: () => _sugerir(prov),
              ),
              if (prov.lineas.isNotEmpty)
                IconButton(
                  tooltip: 'Vaciar',
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _vaciar(prov),
                ),
            ],
          ),
          if (prov.cargando && prov.lineas.isEmpty)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (prov.lineas.isEmpty)
            const SliverFillRemaining(
                child: Center(child: Text('Tu lista de compra está vacía')))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final l = prov.lineas[i];
                  final p = l.producto.producto;
                  return Dismissible(
                    key: ValueKey(p.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => prov.quitar(p.id!),
                    child: ListTile(
                      isThreeLine: true,
                      leading: Icon(l.producto.estado.icono,
                          color: l.producto.estado.color),
                      title: Text(p.nombre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${l.producto.categoriaNombre} • Stock: ${l.producto.stockTotal} ${p.unidad}'),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _comprar(prov, p.id!, l.cantidad),
                            icon: const Icon(Icons.shopping_bag_outlined,
                                size: 18),
                            label: const Text('Registrar compra'),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                prov.cambiarCantidad(p.id!, l.cantidad - 1),
                          ),
                          Text('${l.cantidad}',
                              style: Theme.of(context).textTheme.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                prov.cambiarCantidad(p.id!, l.cantidad + 1),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: prov.lineas.length,
              ),
            ),
        ],
      ),
    );
  }
}
