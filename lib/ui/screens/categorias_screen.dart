import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../data/models/models.dart';
import '../../data/repositories/categoria_repository.dart';
import '../widgets/nombre_dialog.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late Future<List<Categoria>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = context.read<CategoriaRepository>().getTodos();
  }

  void _recargar() {
  if (!mounted) return;
  final futuro = context.read<CategoriaRepository>().getTodos();
  setState(() {
    _futuro = futuro;
  });
}

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guardar({Categoria? actual}) async {
    final repo = context.read<CategoriaRepository>();
    final datos = await pedirDatosCatalogo(
      context,
      titulo: actual == null ? 'Nueva categoría' : 'Editar categoría',
      nombreInicial: actual?.nombre,
    );
    if (datos == null) return;
    try {
      if (actual == null) {
        await repo.insertar(Categoria(nombre: datos.nombre));
      } else {
        await repo.actualizar(actual.copyWith(nombre: datos.nombre));
      }
      _recargar();
    } on AppException catch (e) {
      _aviso(e.mensaje);
    } catch (e) {
      _aviso('Error: $e');
    }
  }

  Future<void> _eliminar(Categoria c) async {
    final repo = context.read<CategoriaRepository>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${c.nombre}"?'),
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
      await repo.eliminar(c.id!);
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
      body: FutureBuilder<List<Categoria>>(
        future: _futuro,
        builder: (context, snap) {
          final cats = snap.data ?? [];
          return CustomScrollView(
            slivers: [
              const SliverAppBar(pinned: true, title: Text('Categorías')),
              if (snap.connectionState != ConnectionState.done)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (cats.isEmpty)
                const SliverFillRemaining(
                    child: Center(child: Text('No hay categorías')))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final c = cats[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(c.nombre.characters.first.toUpperCase()),
                        ),
                        title: Text(c.nombre),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) =>
                              v == 'editar' ? _guardar(actual: c) : _eliminar(c),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'editar', child: Text('Editar')),
                            PopupMenuItem(
                                value: 'eliminar', child: Text('Eliminar')),
                          ],
                        ),
                        onTap: () => _guardar(actual: c),
                      );
                    },
                    childCount: cats.length,
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
