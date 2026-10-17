import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/date_utils.dart';
import '../../data/models/models.dart';
import '../providers/calendario_provider.dart';
import '../widgets/estado_style.dart';
import 'dia_alertas_screen.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<CalendarioProvider>().cargar());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CalendarioProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de alertas')),
      body: prov.cargando
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? Center(child: Text(prov.error!))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      TableCalendar<ProductoResumen>(
                        locale: 'es_MX',
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2100),
                        focusedDay: prov.diaEnfocado,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Mes',
                        },
                        selectedDayPredicate: (d) =>
                            prov.diaSeleccionado != null &&
                            isSameDay(prov.diaSeleccionado, d),
                        eventLoader: prov.eventosDe,
                        onPageChanged: prov.cambiarEnfoque,
                        onDaySelected: (sel, foc) async {
                          prov.seleccionar(sel, foc);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => DiaAlertasScreen(dia: sel),
                            ),
                          );
                          if (context.mounted) {
                            context.read<CalendarioProvider>().cargar();
                          }
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, eventos) {
                            if (eventos.isEmpty) return null;
                            final n = eventos.length > 5 ? 5 : eventos.length;
                            return Positioned(
                              bottom: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var i = 0; i < n; i++)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: eventos[i].estado.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      const _Leyenda(),
                    ],
                  ),
                ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          for (final e in EstadoProducto.values.where((e) => e != EstadoProducto.normal))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(e.icono, size: 16, color: e.color),
                const SizedBox(width: 4),
                Text(e.etiqueta, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}