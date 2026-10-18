import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'data/repositories/calendario_repository.dart';
import 'data/repositories/carrito_repository.dart';
import 'data/repositories/categoria_repository.dart';
import 'data/repositories/lote_repository.dart';
import 'data/repositories/mock_repositories.dart';
import 'data/repositories/producto_repository.dart';
import 'ui/providers/calendario_provider.dart';
import 'ui/providers/carrito_provider.dart';
import 'ui/providers/inventario_provider.dart';
import 'ui/screens/calendario_screen.dart';
import 'ui/screens/carrito_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/producto_form_screen.dart';

// Un solo almacén en memoria compartido por productos y lotes
final _almacenMock = MockProductoRepository();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ---------- Repositorios (cambiar Mock* por los reales luego) ----------
        Provider<ProductoRepository>(create: (_) => _almacenMock),
        Provider<LoteRepository>(create: (_) => MockLoteRepository(_almacenMock)),
        Provider<CategoriaRepository>(create: (_) => MockCategoriaRepository()),
        Provider<CarritoRepository>(
          create: (c) => MockCarritoRepository(c.read<ProductoRepository>()),
        ),
        Provider<CalendarioRepository>(
          create: (c) => MockCalendarioRepository(c.read<ProductoRepository>()),
        ),

        // ---------- Estado ----------
        ChangeNotifierProvider<InventarioProvider>(
          create: (c) => InventarioProvider(c.read<ProductoRepository>()),
        ),
        ChangeNotifierProvider<CalendarioProvider>(
          create: (c) => CalendarioProvider(c.read<CalendarioRepository>()),
        ),
        ChangeNotifierProvider<CarritoProvider>(
          create: (c) => CarritoProvider(c.read<CarritoRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Alacena',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: Routes.home,
        routes: {
          Routes.home: (_) => const HomeScreen(),
          Routes.calendario: (_) => const CalendarioScreen(),
          Routes.carrito: (_) => const CarritoScreen(),
          Routes.productoForm: (_) => const ProductoFormScreen(),
        },
      ),
    );
  }
}