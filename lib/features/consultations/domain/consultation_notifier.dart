import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/consultation_repository.dart';
import 'consultation.dart';

final consultationRepositoryProvider = Provider<ConsultationRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return ConsultationRepository(dbHelper: dbHelper);
});

class ConsultationNotifier extends StateNotifier<AsyncValue<List<Consultation>>> {
  final ConsultationRepository _repository;

  ConsultationNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadConsultations();
  }

  Future<void> loadConsultations() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getAllConsultations();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Consultation?> addConsultation({
    required DateTime consultationDate,
    String? doctorName,
    String? specialty,
    String? facility,
    String? motive,
    String? diagnosis,
    String? notes,
    List<String> diseaseIds = const [],
  }) async {
    try {
      final created = await _repository.createConsultation(
        consultationDate: consultationDate,
        doctorName: doctorName,
        specialty: specialty,
        facility: facility,
        motive: motive,
        diagnosis: diagnosis,
        notes: notes,
        diseaseIds: diseaseIds,
      );
      await loadConsultations();
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final consultationNotifierProvider =
    StateNotifierProvider<ConsultationNotifier, AsyncValue<List<Consultation>>>((ref) {
  final repo = ref.watch(consultationRepositoryProvider);
  return ConsultationNotifier(repo);
});
