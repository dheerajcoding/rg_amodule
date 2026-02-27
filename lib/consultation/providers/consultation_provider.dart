import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/supabase_provider.dart';
import '../controllers/consultation_controller.dart';
import '../models/consultation_session.dart';
import '../models/pandit_model.dart';
import '../repository/consultation_repository.dart';
import '../repository/ws_session_repository.dart';

// ── Repository Providers ──────────────────────────────────────────────────────

/// Production WebSocket + Realtime session repository.
/// Override with [MockSessionRepository] in tests or offline dev:
///   overrides: [sessionRepositoryProvider.overrideWithValue(MockSessionRepository())]
final sessionRepositoryProvider = Provider<ISessionRepository>((ref) {
  return WsSessionRepository(ref.watch(supabaseClientProvider));
});

/// Supabase pandit repository.
/// Override with [MockPanditRepository] for offline development.
final panditRepositoryProvider = Provider<IPanditRepository>((ref) {
  return SupabasePanditRepository(ref.watch(supabaseClientProvider));
});

// ── Pandits List Provider ─────────────────────────────────────────────────────

final panditsProvider =
    StateNotifierProvider<PanditsController, PanditsState>((ref) {
  final ctrl = PanditsController(ref.watch(panditRepositoryProvider));
  ctrl.load();
  return ctrl;
});

// ── Consultation Flow Provider ────────────────────────────────────────────────
//
// Keyed by panditId — creates one flow controller per pandit selection.
// Automatically disposed when no longer watched.

final consultationFlowProvider = StateNotifierProvider.family
    .autoDispose<ConsultationFlowController, ConsultationFlowState, String>(
  (ref, panditId) {
    final pandits = ref.read(panditsProvider).pandits;
    final repo    = ref.read(sessionRepositoryProvider);
    PanditModel pandit;
    try {
      pandit = pandits.firstWhere((p) => p.id == panditId);
    } catch (_) {
      // Fallback: build a minimal placeholder pandit so the screen doesn't crash.
      pandit = PanditModel(
        id: panditId,
        name: 'Pandit',
        specialty: 'Consultation',
        rating: 0,
        totalSessions: 0,
        isOnline: true,
        rates: const [
          ConsultationRate(duration: 10, totalPaise: 9900),
          ConsultationRate(duration: 15, totalPaise: 14900),
          ConsultationRate(duration: 20, totalPaise: 19900),
        ],
      );
    }
    return ConsultationFlowController(pandit, repository: repo);
  },
);

// ── Session Provider ──────────────────────────────────────────────────────────
//
// Keyed by sessionId — one controller per active session.
// The controller connects to the repository immediately on creation.

final sessionProvider = StateNotifierProvider.family
    .autoDispose<SessionController, SessionState, ConsultationSession>(
  (ref, session) {
    final repo = ref.watch(sessionRepositoryProvider);
    final ctrl = SessionController(session: session, repository: repo);
    ctrl.init();
    return ctrl;
  },
);
