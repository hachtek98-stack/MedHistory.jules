import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_helper.dart';
import '../security/security_service.dart';
import '../../features/auth/domain/auth_controller.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  final securityService = ref.watch(securityServiceProvider);
  return DatabaseHelper(securityService: securityService);
});
