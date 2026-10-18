import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes.dart';
import '../../data/models/models.dart';
import '../../data/repositories/carrito_repository.dart';
import '../../data/repositories/categoria_repository.dart';
import '../providers/inventario_provider.dart';
import '../widgets/producto_card.dart';
import 'producto_detalle_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  late final Future<List<Categoria>> _categorias;

  @override
  void initState() {
    super.initState();
    _categorias = context.read<CategoriaRepository>().getTodos();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<InventarioProvider>().cargarTodos());
  }

  Future<void> _abrirDetalle(ProductoResumen item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ProductoDetalleScreen(productoId: item.producto.id!)),
    );
    if (mounted) {
      final prov = context.read<InventarioProvider>();
      prov.cargarTodos(categoriaId: prov.categoriaFiltro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InventarioProvider>();
    final carrito = context.read<CarritoRepository>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(floating: true, snap: true, title: Text('Inventario')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: FutureBuilder<List<Categoria>>(
                future: _categorias,
                builder: (context, snap) {
                  final cats = snap.data ?? [];
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Todos'),
                          selected: prov.categoriaFiltro == null,
                          onSelected: (_) => prov.cargarTodos(),
                        ),
                      ),
                      for (final c in cats)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.nombre),
                            selected: prov.categoriaFiltro == c.id,
                            onSelected: (_) => prov.cargarTodos(categoriaId: c.id),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (prov.cargandoTodos && prov.todos.isEmpty)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (prov.todos.isEmpty)
            const SliverFillRemaining(
                child: Center(child: Text('No hay productos')))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = prov.todos[i];
                  return ProductoCard(
                    item: item,
                    onTap: () => _abrirDetalle(item),
                    onAgregarCarrito: () {
                      carrito.agregar(item.producto.id!);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${item.producto.nombre} agregado al carrito'),
                          duration: const Duration(seconds: 1)));
                    },
                  );
                },
                childCount: prov.todos.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await Navigator.pushNamed(context, Routes.productoForm);
          if (ok == true && context.mounted) {
            context
                .read<InventarioProvider>()
                .cargarTodos(categoriaId: prov.categoriaFiltro);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}