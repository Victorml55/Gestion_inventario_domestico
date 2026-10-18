import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes.dart';
import '../../data/repositories/carrito_repository.dart';
import '../providers/inventario_provider.dart';
import '../widgets/producto_card.dart';
import 'producto_detalle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<InventarioProvider>().cargar());
  }

  Future<void> _ir(String ruta) async {
    await Navigator.pushNamed(context, ruta);
    if (mounted) context.read<InventarioProvider>().cargar();
  }

  Future<void> _irDesdeMenu(String ruta) async {
    Navigator.pop(context); // cierra el drawer
    await _ir(ruta);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InventarioProvider>();
    final carrito = context.read<CarritoRepository>();

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              ListTile(
                title: Text('Mi alacena',
                    style: Theme.of(context).textTheme.headlineSmall),
                subtitle: const Text('Control de inventario doméstico'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text('Inventario'),
                onTap: () => _irDesdeMenu(Routes.inventario),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Calendario'),
                onTap: () => _irDesdeMenu(Routes.calendario),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Historial de compras'),
                onTap: () => _irDesdeMenu(Routes.historial),
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Gasto por tienda'),
                onTap: () => _irDesdeMenu(Routes.estadisticas),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Categorías'),
                onTap: () => _irDesdeMenu(Routes.categorias),
              ),
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('Tiendas'),
                onTap: () => _irDesdeMenu(Routes.tiendas),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: prov.cargar,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: const Text('Mi alacena'),
              actions: [
                IconButton(
                  tooltip: 'Inventario',
                  icon: const Icon(Icons.inventory_2),
                  onPressed: () => _ir(Routes.inventario),
                ),
                IconButton(
                  tooltip: 'Calendario',
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => _ir(Routes.calendario),
                ),
                StreamBuilder<int>(
                  stream: carrito.watchCantidad(),
                  initialData: 0,
                  builder: (context, snap) {
                    final n = snap.data ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: badges.Badge(
                        showBadge: n > 0,
                        position: badges.BadgePosition.topEnd(top: 0, end: 0),
                        badgeContent: Text('$n',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                        child: IconButton(
                          tooltip: 'Lista de compra',
                          icon: const Icon(Icons.shopping_cart),
                          onPressed: () => _ir(Routes.carrito),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (prov.cargando && prov.alertas.isEmpty)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (prov.error != null)
              SliverFillRemaining(child: Center(child: Text(prov.error!)))
            else if (prov.alertas.isEmpty)
              const SliverFillRemaining(
                  child: Center(child: Text('Sin alertas, todo en orden 🎉')))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = prov.alertas[i];
                    return ProductoCard(
                      item: item,
                      onTap: () async {
                        await abrirDetalleProducto(context, item.producto.id!);
                        if (context.mounted) {
                          context.read<InventarioProvider>().cargar();
                        }
                      },
                      onAgregarCarrito: () {
                        carrito.agregar(item.producto.id!);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                '${item.producto.nombre} agregado al carrito'),
                            duration: const Duration(seconds: 1)));
                      },
                    );
                  },
                  childCount: prov.alertas.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ir(Routes.productoForm),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}
