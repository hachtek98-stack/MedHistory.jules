import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/disease.dart';
import '../domain/disease_notifier.dart';

class DiseaseListScreen extends ConsumerWidget {
  const DiseaseListScreen({super.key});

  void _showDiseaseDialog(BuildContext context, WidgetRef ref, [Disease? disease]) {
    final titleController = TextEditingController(text: disease?.title ?? '');
    final descController = TextEditingController(text: disease?.description ?? '');
    DiseaseStatus selectedStatus = disease?.status ?? DiseaseStatus.active;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(disease == null ? 'Ajouter une maladie' : 'Modifier la maladie'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la maladie *',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description / Remarques',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text('Statut :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: DiseaseStatus.values.map((st) {
                      final isSelected = st == selectedStatus;
                      String label;
                      Color color;
                      switch (st) {
                        case DiseaseStatus.active:
                          label = 'Active';
                          color = Colors.red;
                          break;
                        case DiseaseStatus.remission:
                          label = 'En rémission';
                          color = Colors.orange;
                          break;
                        case DiseaseStatus.cured:
                          label = 'Guérie';
                          color = Colors.green;
                          break;
                      }

                      return ChoiceChip(
                        label: Text(label, style: TextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.black)),
                        selected: isSelected,
                        selectedColor: color,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => selectedStatus = st);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ANNULER', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 48),
                ),
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  final notifier = ref.read(diseaseNotifierProvider.notifier);
                  if (disease == null) {
                    notifier.addDisease(title, descController.text.trim(), selectedStatus);
                  } else {
                    notifier.updateDisease(disease.copyWith(
                      title: title,
                      description: descController.text.trim(),
                      status: selectedStatus,
                    ));
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('ENREGISTRER', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diseasesState = ref.watch(diseaseNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiches Maladies'),
      ),
      body: diseasesState.when(
        data: (diseases) {
          if (diseases.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Aucune maladie enregistrée.\nCliquez sur + pour en ajouter une.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: diseases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final disease = diseases[index];

              Color statusColor;
              String statusLabel;
              switch (disease.status) {
                case DiseaseStatus.active:
                  statusColor = Colors.red.shade100;
                  statusLabel = 'Active';
                  break;
                case DiseaseStatus.remission:
                  statusColor = Colors.orange.shade100;
                  statusLabel = 'Rémission';
                  break;
                case DiseaseStatus.cured:
                  statusColor = Colors.green.shade100;
                  statusLabel = 'Guérie';
                  break;
              }

              return Card(
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    disease.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (disease.description != null && disease.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(disease.description!, style: const TextStyle(fontSize: 16)),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 28),
                    onPressed: () => _showDiseaseDialog(context, ref, disease),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64, // Touch target senior > 56dp
        child: FloatingActionButton(
          onPressed: () => _showDiseaseDialog(context, ref),
          child: const Icon(Icons.add, size: 36),
        ),
      ),
    );
  }
}
