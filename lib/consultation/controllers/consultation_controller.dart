import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/consultation_session.dart';
import '../models/pandit_model.dart';
import '../repository/consultation_repository.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PART 1 — CONSULTATION FLOW CONTROLLER
// Manages the pre-session flow: duration selection → payment → connect.
// ═════════════════════════════════════════════════════════════════════════════

// ── Flow State ────────────────────────────────────────────────────────────────

class ConsultationFlowState {
  const ConsultationFlowState({
    required this.pandit,
    this.selectedRate,
    this.step = ConsultationFlowStep.selectDuration,
    this.processingPayment = false,
    this.error,
    this.createdSession,
  });

  final PanditModel pandit;
  final ConsultationRate? selectedRate;
  final ConsultationFlowStep step;
  final bool processingPayment;
  final String? error;

  /// Set once the session is created (step == started).
  final ConsultationSession? createdSession;

  bool get canProceedToPayment =>
      selectedRate != null && step == ConsultationFlowStep.selectDuration;

  ConsultationFlowState copyWith({
    ConsultationRate? selectedRate,
    ConsultationFlowStep? step,
    bool? processingPayment,
    String? error,
    ConsultationSession? createdSession,
    bool clearError = false,
    bool clearSession = false,
  }) =>
      ConsultationFlowState(
        pandit: pandit,
        selectedRate: selectedRate ?? this.selectedRate,
        step: step ?? this.step,
        processingPayment: processingPayment ?? this.processingPayment,
        error: clearError ? null : (error ?? this.error),
        createdSession:
            clearSession ? null : (createdSession ?? this.createdSession),
      );
}

// ── Flow Controller ───────────────────────────────────────────────────────────

/// Manages the consultation booking flow for a single pandit.
/// Key: `pandit.id`
class ConsultationFlowController
    extends StateNotifier<ConsultationFlowState> {
  ConsultationFlowController(PanditModel pandit)
      : super(ConsultationFlowState(pandit: pandit));

  // ── Step 1: select duration ──────────────────────────────────────────────

  void selectRate(ConsultationRate rate) {
    state = state.copyWith(
      selectedRate: rate,
      clearError: true,
    );
  }

  void proceedToPayment() {
    if (state.selectedRate == null) {
      state = state.copyWith(
          error: 'Please select a session duration first.');
      return;
    }
    state = state.copyWith(
      step: ConsultationFlowStep.payment,
      clearError: true,
    );
  }

  void backToSelectDuration() {
    state = state.copyWith(step: ConsultationFlowStep.selectDuration);
  }

  // ── Step 2: payment placeholder ──────────────────────────────────────────
  //
  // In production: integrate Razorpay / Paytm SDK here.
  // On success callback → call [confirmPayment].

  Future<void> confirmPayment({
    required String userId,
    required String userName,
  }) async {
    state =
        state.copyWith(processingPayment: true, clearError: true);

    try {
      // TODO: Replace with real payment SDK call.
      // await RazorpayService.charge(amount: state.selectedRate!.totalPaise);
      await Future.delayed(const Duration(seconds: 1)); // mock payment delay

      final session = ConsultationSession.create(
        pandit: state.pandit,
        rate: state.selectedRate!,
        userId: userId,
        userName: userName,
      );

      state = state.copyWith(
        processingPayment: false,
        step: ConsultationFlowStep.connecting,
        createdSession: session,
      );
    } catch (e) {
      state = state.copyWith(
        processingPayment: false,
        error: 'Payment failed: ${e.toString()}',
      );
    }
  }

  void reset() {
    state = ConsultationFlowState(pandit: state.pandit);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PART 2 — SESSION CONTROLLER
// Manages the active chat session: timer, messages, extension, locking.
// ═════════════════════════════════════════════════════════════════════════════

// ── Session State ─────────────────────────────────────────────────────────────

class SessionState {
  const SessionState({
    required this.session,
    this.messages = const [],
    required this.remainingSeconds,
    this.chatLocked = false,
    this.isPanditTyping = false,
    this.extending = false,
    this.extendError,
    this.endRequested = false,
  });

  final ConsultationSession session;
  final List<ChatMessage> messages;

  /// Countdown value driven by local Timer (synced with server TimeUpdate).
  final int remainingSeconds;

  /// True when time expired — chat input is locked.
  final bool chatLocked;

  /// Pandit typing indicator.
  final bool isPanditTyping;

  /// True while payment for extension is processing.
  final bool extending;
  final String? extendError;

  /// True when end-session confirmation has been requested.
  final bool endRequested;

  // ── Derived ──────────────────────────────────────────────────────────────

  /// Show 1-minute warning banner.
  bool get showWarning =>
      remainingSeconds > 0 &&
      remainingSeconds <= 60 &&
      session.status == SessionStatus.active;

  bool get isConnecting => session.status == SessionStatus.connecting;
  bool get isActive => session.status.isLive;
  bool get isEnded => session.status.isTerminal;

  String get formattedRemaining {
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Progress 0.0→1.0 (elapsed / total).
  double get timerProgress {
    final total = session.allottedSeconds;
    if (total == 0) return 1.0;
    final elapsed = total - remainingSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  SessionState copyWith({
    ConsultationSession? session,
    List<ChatMessage>? messages,
    int? remainingSeconds,
    bool? chatLocked,
    bool? isPanditTyping,
    bool? extending,
    String? extendError,
    bool? endRequested,
    bool clearExtendError = false,
  }) =>
      SessionState(
        session: session ?? this.session,
        messages: messages ?? this.messages,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        chatLocked: chatLocked ?? this.chatLocked,
        isPanditTyping: isPanditTyping ?? this.isPanditTyping,
        extending: extending ?? this.extending,
        extendError: clearExtendError ? null : (extendError ?? this.extendError),
        endRequested: endRequested ?? this.endRequested,
      );
}

// ── Session Controller ────────────────────────────────────────────────────────

/// Manages an active consultation chat session.
///
/// Timer architecture (server-controlled design):
///   - A local `Timer.periodic` counts down every second for smooth UI.
///   - When the server sends `TimeUpdateEvent`, local timer syncs to server
///     value — prevents drift over long sessions.
///   - In production the server is the source of truth for time; the client
///     timer is only for display smoothness.
///
/// Key: `session.id`
class SessionController extends StateNotifier<SessionState> {
  SessionController({
    required ConsultationSession session,
    required ISessionRepository repository,
  })  : _repo = repository,
        super(SessionState(
          session: session,
          remainingSeconds: session.totalSeconds,
        ));

  final ISessionRepository _repo;
  Timer? _countdownTimer;
  StreamSubscription<SessionEvent>? _streamSub;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Call immediately after construction.
  void init() {
    _streamSub = _repo
        .connect(state.session)
        .listen(_onEvent, onError: _onStreamError);
  }

  @override
  void dispose() {
    _cancelTimer();
    _streamSub?.cancel();
    _repo.dispose(state.session.id);
    super.dispose();
  }

  // ── Event Handling ────────────────────────────────────────────────────────

  void _onEvent(SessionEvent event) {
    if (!mounted) return;

    switch (event) {
      case SessionStartedEvent():
        _startCountdown();
        state = state.copyWith(
          session: state.session.copyWith(status: SessionStatus.active),
        );
        _addSystemMessage('Session started. Your time is running.');

      case PanditMessageEvent(:final message):
        state = state.copyWith(
          messages: [...state.messages, message],
          isPanditTyping: false,
        );

      case TypingEvent(:final isTyping):
        state = state.copyWith(isPanditTyping: isTyping);

      case TimeUpdateEvent(:final remainingSeconds):
        // Server sync — override local timer value.
        state = state.copyWith(remainingSeconds: remainingSeconds);
        _checkWarningAndExpiry(remainingSeconds);

      case SessionExtendedEvent(:final addedSeconds):
        final updated = state.session.copyWith(
          extendedSeconds:
              state.session.extendedSeconds + addedSeconds,
          status: SessionStatus.active,
        );
        state = state.copyWith(
          session: updated,
          remainingSeconds:
              state.remainingSeconds + addedSeconds,
          extending: false,
          chatLocked: false,
          clearExtendError: true,
        );
        _addSystemMessage(
            'Session extended by ${addedSeconds ~/ 60} minutes.');
        if (!(_countdownTimer?.isActive ?? false)) _startCountdown();

      case SessionEndedEvent(:final reason):
        _cancelTimer();
        final status = reason == 'time_expired'
            ? SessionStatus.expired
            : SessionStatus.ended;
        state = state.copyWith(
          session: state.session.copyWith(status: status),
          chatLocked: true,
          remainingSeconds: 0,
        );
        _addSystemMessage(
            reason == 'time_expired'
                ? 'Session time expired. Chat is now locked.'
                : 'Session ended.');
    }
  }

  void _onStreamError(Object error) {
    if (!mounted) return;
    // In production: surface a reconnection UI / retry logic.
    _addSystemMessage('Connection error. Please check your network.');
  }

  // ── Countdown Timer ───────────────────────────────────────────────────────

  void _startCountdown() {
    _cancelTimer();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (!mounted) return;
    final next = state.remainingSeconds - 1;
    state = state.copyWith(remainingSeconds: next.clamp(0, 9999));
    _checkWarningAndExpiry(next);
  }

  void _checkWarningAndExpiry(int remaining) {
    if (!mounted) return;

    if (remaining <= 0) {
      _cancelTimer();
      if (!state.isEnded) {
        state = state.copyWith(
          session: state.session.copyWith(status: SessionStatus.expired),
          chatLocked: true,
          remainingSeconds: 0,
        );
        _addSystemMessage('Session time expired. Chat is now locked.');
      }
    } else if (remaining <= 60 &&
        state.session.status == SessionStatus.active) {
      state = state.copyWith(
        session:
            state.session.copyWith(status: SessionStatus.warning),
      );
    }
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // ── User Actions ──────────────────────────────────────────────────────────

  /// Send a message from the user side.
  Future<void> sendMessage(String text, String userId, String userName) async {
    if (state.chatLocked || text.trim().isEmpty) return;

    final msg = ChatMessage(
      sessionId: state.session.id,
      senderId: userId,
      senderName: userName,
      text: text.trim(),
      isFromPandit: false,
    );

    state = state.copyWith(messages: [...state.messages, msg]);

    await _repo.sendMessage(state.session.id, text.trim(), userId);
  }

  /// Request a 10-minute extension.
  /// In production: triggers a payment flow before calling extendSession.
  Future<void> requestExtension({int addMinutes = 10}) async {
    if (state.extending) return;
    state = state.copyWith(extending: true, clearExtendError: true);

    try {
      // TODO: Trigger payment for extension before calling repo.
      // await RazorpayService.charge(amount: extensionRate.totalPaise);
      await _repo.extendSession(state.session.id, addMinutes);
    } catch (e) {
      state = state.copyWith(
        extending: false,
        extendError: 'Could not extend session. Please try again.',
      );
    }
  }

  /// User requested graceful end — ask confirmation before calling this.
  Future<void> endSession() async {
    _cancelTimer();
    await _repo.endSession(state.session.id);
  }

  void setEndRequested(bool value) {
    state = state.copyWith(endRequested: value);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _addSystemMessage(String text) {
    final msg = ChatMessage(
      sessionId: state.session.id,
      senderId: 'system',
      senderName: 'System',
      text: text,
      isFromPandit: false,
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PART 3 — PANDITS LIST CONTROLLER
// ═════════════════════════════════════════════════════════════════════════════

class PanditsState {
  const PanditsState({
    this.pandits = const [],
    this.loading = false,
    this.error,
  });

  final List<PanditModel> pandits;
  final bool loading;
  final String? error;

  PanditsState copyWith({
    List<PanditModel>? pandits,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      PanditsState(
        pandits: pandits ?? this.pandits,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class PanditsController extends StateNotifier<PanditsState> {
  PanditsController(this._repo) : super(const PanditsState());

  final IPanditRepository _repo;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final list = await _repo.fetchOnlinePandits();
      state = state.copyWith(pandits: list, loading: false);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to load consultants: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() => load();
}
