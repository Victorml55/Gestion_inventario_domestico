import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'data/repositories/calendario_repository.dart';
import 'data/repositories/carrito_repository.dart';
import 'data/repositories/mock_repositories.dart';
import 'data/repositories/producto_repository.dart';
import 'ui/providers/calendario_provider.dart';
import 'ui/providers/inventario_provider.dart';
import 'ui/screens/calendario_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/providers/carrito_provider.dart';
import 'ui/screens/carrito_screen.dart';

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
        Provider<ProductoRepository>(
        create: (_) => MockProductoRepository(),
        ),
        Provider<CarritoRepository>(
        create: (c) => MockCarritoRepository(c.read<ProductoRepository>()),
        ),
        Provider<CalendarioRepository>(
        create: (c) => MockCalendarioRepository(c.read<ProductoRepository>()),
        ),

        // ---------- Providers de estado (ChangeNotifier) ----------
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

        // Localización (necesaria para table_calendar y DateFormat en español)
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
          // Pendientes: placeholders
          Routes.carrito: (_) => const CarritoScreen(),
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(titulo)),
        body: Center(child: Text(titulo)),
      );
}