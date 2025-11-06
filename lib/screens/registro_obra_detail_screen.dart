import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/registro_obra_service.dart';
import '../models/registro_obra.dart';
import '../utils/app_theme.dart';
import '../widgets/safe_image.dart';

class RegistroObraDetailScreen extends StatelessWidget {
  final String registroId;
  const RegistroObraDetailScreen({super.key, required this.registroId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RegistroObra?>(
      future: RegistroObraService.getRegistro(registroId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalhes')), 
            body: const Center(child: Text('Registro não encontrado')),
          );
        }
        final r = snapshot.data!;
        final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalhes do Registro'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: r.id,
                  child: SafeImage(
                    imageUrl: r.imageUrl,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  r.pontoObra,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(dateFmt.format(r.timestamp)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Etapa: ${r.etapaObra}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (r.latitude != null && r.longitude != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.my_location, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        '${r.latitude!.toStringAsFixed(6)}, ${r.longitude!.toStringAsFixed(6)}'
                        '${r.locationAccuracyMeters != null ? ' (±${r.locationAccuracyMeters!.toStringAsFixed(1)} m)' : ''}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Criado em: ${dateFmt.format(r.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Atualizado em: ${dateFmt.format(r.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


