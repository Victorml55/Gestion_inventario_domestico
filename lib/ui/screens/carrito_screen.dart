import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import '../widgets/estado_style.dart';

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
              if (prov.lineas.isNotEmpty)
                IconButton(
                  tooltip: 'Vaciar',
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () async {
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
                  },
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
                      leading: Icon(l.producto.estado.icono,
                          color: l.producto.estado.color),
                      title: Text(p.nombre),
                      subtitle: Text(
                          '${l.producto.categoriaNombre} • Stock: ${l.producto.stockTotal} ${p.unidad}'),
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