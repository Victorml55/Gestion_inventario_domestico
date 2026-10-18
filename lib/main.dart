import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'data/repositories/calendario_repository.dart';
import 'data/repositories/calendario_repository_impl.dart';
import 'data/repositories/carrito_repository.dart';
import 'data/repositories/carrito_repository_impl.dart';
import 'data/repositories/categoria_repository.dart';
import 'data/repositories/categoria_repository_impl.dart';
import 'data/repositories/compra_repository.dart';
import 'data/repositories/compra_repository_impl.dart';
import 'data/repositories/lote_repository.dart';
import 'data/repositories/lote_repository_impl.dart';
import 'data/repositories/producto_repository.dart';
import 'data/repositories/producto_repository_impl.dart';
import 'data/services/notification_service.dart';
import 'ui/providers/calendario_provider.dart';
import 'ui/providers/carrito_provider.dart';
import 'ui/providers/inventario_provider.dart';
import 'ui/screens/calendario_screen.dart';
import 'ui/screens/carrito_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/inventario_screen.dart';
import 'ui/screens/producto_form_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  await NotificationService.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ---------- Repositorios reales (SQLite) ----------
        Provider<ProductoRepository>(create: (_) => ProductoRepositoryImpl()),
        Provider<LoteRepository>(create: (_) => LoteRepositoryImpl()),
        Provider<CategoriaRepository>(create: (_) => CategoriaRepositoryImpl()),
        Provider<CarritoRepository>(create: (_) => CarritoRepositoryImpl()),
        Provider<CompraRepository>(create: (_) => CompraRepositoryImpl()),
        Provider<CalendarioRepository>(
          create: (c) => CalendarioRepositoryImpl(c.read<ProductoRepository>()),
        ),

        // ---------- Estado ----------
        ChangeNotifierProvider<InventarioProvider>(
          create: (c) => InventarioProvider(c.read<ProductoRepository>()),
        ),
        ChangeNotifierProvider<CalendarioProvider>(
          create: (c) => CalendarioProvider(c.read<CalendarioRepository>()),
        ),
        ChangeNotifierProvider<CarritoProvider>(
          create: (c) => CarritoProvider(
            c.read<CarritoRepository>(),
            c.read<ProductoRepository>(),
          ),
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
          Routes.inventario: (_) => const InventarioScreen(),
        },
      ),
    );
  }
}