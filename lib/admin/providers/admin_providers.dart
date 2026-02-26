// lib/admin/providers/admin_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../models/admin_models.dart';
import '../repository/admin_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final adminRepositoryProvider = Provider<IAdminRepository>(
  (_) => MockAdminRepository(),
);

// ── Main dashboard provider ───────────────────────────────────────────────────

final adminProvider =
    StateNotifierProvider.autoDispose<AdminController, AdminState>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminController(repo);
});

// ── Derived providers ─────────────────────────────────────────────────────────

final adminPoojasProvider = Provider.autoDispose<List<AdminPooja>>((ref) {
  return ref.watch(adminProvider).poojas;
});

final adminPanditsProvider = Provider.autoDispose<List<AdminPandit>>((ref) {
  return ref.watch(adminProvider).pandits;
});

final adminBookingsProvider =
    Provider.autoDispose<List<AdminBookingRow>>((ref) {
  return ref.watch(adminProvider).bookings;
});

final adminConsultationsProvider =
    Provider.autoDispose<List<AdminConsultationRow>>((ref) {
  return ref.watch(adminProvider).consultations;
});

final adminReportProvider = Provider.autoDispose<AdminReport?>((ref) {
  return ref.watch(adminProvider).report;
});

final adminLoadingProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(adminProvider).loading;
});
