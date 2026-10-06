import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../diseases/domain/disease.dart';
import '../../diseases/domain/disease_notifier.dart';
import '../domain/consultation.dart';
import '../domain/consultation_notifier.dart';

class ConsultationFormScreen extends ConsumerStatefulWidget {
  const ConsultationFormScreen({super.key});

  @override
  ConsumerState<ConsultationFormScreen> createState() => _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends ConsumerState<ConsultationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  final _doctorController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _facilityController = TextEditingController();
  final _motiveController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _selectedDiseaseIds = [];

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveConsultation() async {
    if (!_formKey.currentState!.validate()) return;

    final created = await ref.read(consultationNotifierProvider.notifier).addConsultation(
          consultationDate: _selectedDate,
          doctorName: _doctorController.text.trim().isEmpty ? null : _doctorController.text.trim(),
          specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
          facility: _facilityController.text.trim().isEmpty ? null : _facilityController.text.trim(),
          motive: _motiveController.text.trim().isEmpty ? null : _motiveController.text.trim(),
          diagnosis: _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          diseaseIds: _selectedDiseaseIds,
        );

    if (created != null && mounted) {
      _showConfirmationModal(context, created);
    }
  }

  void _showConfirmationModal(BuildContext context, Consultation consultation) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 40),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Consultation enregistrée !',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Que souhaitez-vous ajouter à cette consultation ?',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
                    icon: const Text('💊', style: TextStyle(fontSize: 20)),
                    label: const Text('Ajouter un traitement', style: TextStyle(fontSize: 15)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Module Traitement (Sprint 3)')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
                    icon: const Text('🧪', style: TextStyle(fontSize: 20)),
                    label: const Text('Ajouter un examen', style: TextStyle(fontSize: 15)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Module Examen (Sprint 3)')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
                    icon: const Text('📄', style: TextStyle(fontSize: 20)),
                    label: const Text('Ajouter un document', style: TextStyle(fontSize: 15)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Module Ordonnance (Sprint 3)')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56, // Touch target min 56px
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'TERMINER',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final diseasesState = ref.watch(diseaseNotifierProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Consultation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélecteur de date Senior
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blue.shade50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date de consultation *', style: TextStyle(fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(_selectedDate),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Icon(Icons.calendar_today, size: 32, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _doctorController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Nom du Médecin',
                  prefixIcon: Icon(Icons.person_outline, size: 28),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _specialtyController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Spécialité (ex: Cardiologue)',
                  prefixIcon: Icon(Icons.medical_services_outlined, size: 28),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _facilityController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Établissement / Cabinet',
                  prefixIcon: Icon(Icons.local_hospital_outlined, size: 28),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _motiveController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Motif de consultation',
                  prefixIcon: Icon(Icons.help_outline, size: 28),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _diagnosisController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Diagnostic',
                  prefixIcon: Icon(Icons.rate_review_outlined, size: 28),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                style: const TextStyle(fontSize: 18),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes personnelles',
                  prefixIcon: Icon(Icons.note_alt_outlined, size: 28),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Puces de sélection de maladies associées
              const Text(
                'Maladies associées :',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              diseasesState.when(
                data: (diseases) {
                  if (diseases.isEmpty) {
                    return const Text('Aucune maladie enregistrée.');
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: diseases.map((d) {
                      final isSelected = _selectedDiseaseIds.contains(d.id);
                      return FilterChip(
                        label: Text(d.title, style: const TextStyle(fontSize: 16)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDiseaseIds.add(d.id);
                            } else {
                              _selectedDiseaseIds.remove(d.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 56, // Touch target senior min 56px
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveConsultation,
                  child: const Text(
                    'ENREGISTRER LA CONSULTATION',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
