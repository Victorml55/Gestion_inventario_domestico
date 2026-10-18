import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../data/models/models.dart';
import '../../data/repositories/tienda_repository.dart';
import '../widgets/nombre_dialog.dart';

class TiendasScreen extends StatefulWidget {
  const TiendasScreen({super.key});

  @override
  State<TiendasScreen> createState() => _TiendasScreenState();
}

class _TiendasScreenState extends State<TiendasScreen> {
  late Future<List<Tienda>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = context.read<TiendaRepository>().getTodos();
  }

  void _recargar() {
  if (!mounted) return;
  final futuro = context.read<TiendaRepository>().getTodos();
  setState(() {
    _futuro = futuro;
  });
}

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guardar({Tienda? actual}) async {
    final repo = context.read<TiendaRepository>();
    final datos = await pedirDatosCatalogo(
      context,
      titulo: actual == null ? 'Nueva tienda' : 'Editar tienda',
      nombreInicial: actual?.nombre,
      etiquetaExtra: 'Dirección (opcional)',
      extraInicial: actual?.direccion,
    );
    if (datos == null) return;
    try {
      if (actual == null) {
        await repo.insertar(Tienda(nombre: datos.nombre, direccion: datos.extra));
      } else {
        await repo.actualizar(
            Tienda(id: actual.id, nombre: datos.nombre, direccion: datos.extra));
      }
      _recargar();
    } on AppException catch (e) {
      _aviso(e.mensaje);
    } catch (e) {
      _aviso('Error: $e');
    }
  }

  Future<void> _eliminar(Tienda t) async {
    final repo = context.read<TiendaRepository>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tienda'),
        content: Text('¿Eliminar "${t.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.eliminar(t.id!);
      _recargar();
    } on AppException catch (e) {
      _aviso(e.mensaje);
    } catch (e) {
      _aviso('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Tienda>>(
        future: _futuro,
        builder: (context, snap) {
          final tiendas = snap.data ?? [];
          return CustomScrollView(
            slivers: [
              const SliverAppBar(pinned: true, title: Text('Tiendas')),
              if (snap.connectionState != ConnectionState.done)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (tiendas.isEmpty)
                const SliverFillRemaining(
                    child: Center(child: Text('No hay tiendas')))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final t = tiendas[i];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.store)),
                        title: Text(t.nombre),
                        subtitle: t.direccion == null ? null : Text(t.direccion!),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) =>
                              v == 'editar' ? _guardar(actual: t) : _eliminar(t),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'editar', child: Text('Editar')),
                            PopupMenuItem(
                                value: 'eliminar', child: Text('Eliminar')),
                          ],
                        ),
                        onTap: () => _guardar(actual: t),
                      );
                    },
                    childCount: tiendas.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _guardar(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}
