import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/date_utils.dart';
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
import 'data/repositories/tienda_repository.dart';
import 'data/repositories/tienda_repository_impl.dart';
import 'data/services/notification_service.dart';
import 'ui/providers/calendario_provider.dart';
import 'ui/providers/carrito_provider.dart';
import 'ui/providers/inventario_provider.dart';
import 'ui/screens/calendario_screen.dart';
import 'ui/screens/carrito_screen.dart';
import 'ui/screens/categorias_screen.dart';
import 'ui/screens/dia_alertas_screen.dart';
import 'ui/screens/estadisticas_screen.dart';
import 'ui/screens/historial_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/inventario_screen.dart';
import 'ui/screens/producto_form_screen.dart';
import 'ui/screens/tiendas_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Se llama al tocar una notificación de caducidad.
void _abrirDia(DateTime dia) {
  navigatorKey.currentState?.pushNamed(Routes.alarmaDia, arguments: dia);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  await NotificationService.init();
  NotificationService.onAbrirDia = _abrirDia;
  runApp(const App());

  // Si la app se abrió tocando una notificación (estaba cerrada)
  final inicial = await NotificationService.diaDeLanzamiento();
  if (inicial != null) {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) => _abrirDia(inicial));
    binding.scheduleFrame();
  }
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
        Provider<TiendaRepository>(create: (_) => TiendaRepositoryImpl()),
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
        navigatorKey: navigatorKey,
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
          Routes.categorias: (_) => const CategoriasScreen(),
          Routes.tiendas: (_) => const TiendasScreen(),
          Routes.historial: (_) => const HistorialScreen(),
          Routes.estadisticas: (_) => const EstadisticasScreen(),
        },
        // Pantalla de alarma: productos que caducan en el día de la notificación
        onGenerateRoute: (settings) {
          if (settings.name == Routes.alarmaDia) {
            final dia = settings.arguments is DateTime
                ? settings.arguments as DateTime
                : hoy();
            return MaterialPageRoute(
              fullscreenDialog: true,
              settings: settings,
              builder: (_) => DiaAlertasScreen(dia: dia),
            );
          }
          return null;
        },
      ),
    );
  }
}
