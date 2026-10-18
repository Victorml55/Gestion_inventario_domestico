import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes.dart';
import '../../data/repositories/carrito_repository.dart';
import '../providers/inventario_provider.dart';
import '../widgets/producto_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InventarioProvider>();
    final carrito = context.read<CarritoRepository>();

    return Scaffold(
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
                onPressed: () async {
                await Navigator.pushNamed(context, Routes.inventario);
                if (context.mounted) context.read<InventarioProvider>().cargar();
                },
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => Navigator.pushNamed(context, Routes.calendario),
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
                            style: const TextStyle(color: Colors.white, fontSize: 11)),
                        child: IconButton(
                          icon: const Icon(Icons.shopping_cart),
                          onPressed: () => Navigator.pushNamed(context, Routes.carrito),
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
                      onAgregarCarrito: () {
                        carrito.agregar(item.producto.id!);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${item.producto.nombre} agregado al carrito'),
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
        onPressed: () async {
        final guardado = await Navigator.pushNamed(context, Routes.productoForm);
          if (guardado == true && context.mounted) {
          context.read<InventarioProvider>().cargar();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}