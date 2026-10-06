import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/disease_repository.dart';
import 'disease.dart';

final diseaseRepositoryProvider = Provider<DiseaseRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return DiseaseRepository(dbHelper: dbHelper);
});

class DiseaseNotifier extends StateNotifier<AsyncValue<List<Disease>>> {
  final DiseaseRepository _repository;

  DiseaseNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadDiseases();
  }

  Future<void> loadDiseases() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getAllDiseases();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDisease(String title, String? description, DiseaseStatus status) async {
    try {
      await _repository.createDisease(
        title: title,
        description: description,
        status: status,
      );
      await loadDiseases();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDisease(Disease disease) async {
    try {
      await _repository.updateDisease(disease);
      await loadDiseases();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDisease(String id) async {
    try {
      await _repository.deleteDisease(id);
      await loadDiseases();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final diseaseNotifierProvider =
    StateNotifierProvider<DiseaseNotifier, AsyncValue<List<Disease>>>((ref) {
  final repo = ref.watch(diseaseRepositoryProvider);
  return DiseaseNotifier(repo);
});
