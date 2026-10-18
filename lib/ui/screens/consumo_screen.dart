import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_exception.dart';
import '../../data/models/models.dart';
import '../../data/repositories/producto_repository.dart';

class ConsumoScreen extends StatefulWidget {
  final ProductoResumen item;
  const ConsumoScreen({super.key, required this.item});

  @override
  State<ConsumoScreen> createState() => _ConsumoScreenState();
}

class _ConsumoScreenState extends State<ConsumoScreen> {
  int _cantidad = 1;
  bool _guardando = false;

  Future<void> _consumir() async {
    final repo = context.read<ProductoRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _guardando = true);
    try {
      await repo.consumirStock(widget.item.producto.id!, _cantidad);
      messenger.showSnackBar(
          SnackBar(content: Text('Se consumieron $_cantidad ${widget.item.producto.unidad}')));
      navigator.pop(true);
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
      if (mounted) setState(() => _guardando = false);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.item.producto;
    final stock = widget.item.stockTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Consumir')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(p.nombre, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Disponible: $stock ${p.unidad}'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  iconSize: 32,
                  onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text('$_cantidad',
                      style: Theme.of(context).textTheme.displayMedium),
                ),
                IconButton.filledTonal(
                  iconSize: 32,
                  onPressed: _cantidad < stock ? () => setState(() => _cantidad++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Se descuenta primero del lote que caduca antes.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _guardando ? null : _consumir,
                icon: const Icon(Icons.check),
                label: const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}