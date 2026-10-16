import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes.dart';
import 'data/repositories/carrito_repository.dart';
import 'data/repositories/mock_repositories.dart';
import 'data/repositories/producto_repository.dart';
import 'ui/providers/inventario_provider.dart';
import 'ui/screens/home_screen.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Cambiar Mock* por las implementaciones reales cuando el backend esté listo
        Provider<ProductoRepository>(create: (_) => MockProductoRepository()),
        Provider<CarritoRepository>(create: (_) => MockCarritoRepository()),
        ChangeNotifierProvider(
            create: (c) => InventarioProvider(c.read<ProductoRepository>())),
      ],
      child: MaterialApp(
        title: 'Alacena',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        initialRoute: Routes.home,
        routes: {
          Routes.home: (_) => const HomeScreen(),
          // Pendientes: placeholders
          Routes.calendario: (_) => const _Pendiente('Calendario'),
          Routes.carrito: (_) => const _Pendiente('Carrito'),
          Routes.productoForm: (_) => const _Pendiente('Nuevo producto'),
        },
      ),
    );
  }
}

class _Pendiente extends StatelessWidget {
  final String titulo;
  const _Pendiente(this.titulo);

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(titulo)), body: Center(child: Text(titulo)));
}