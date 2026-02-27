/// Demo-mode configuration for the DivinePooja client demo.
///
/// When [demoMode] is `true`:
///   - The login screen shows quick-login chips for the 3 demo accounts.
///   - Admin destructive actions (delete pooja, toggle pandit) show a
///     snackbar instead of hitting the backend.
///   - Payment always simulates success (MockPaymentService — already wired).
///   - Auto-assign pandit to new bookings when no pandit is specified.
///
/// Set to `false` before building a production release.
class DemoConfig {
  DemoConfig._();

  /// Master switch for demo-mode behaviour.
  static const bool demoMode = true;

  // ── Demo account credentials ───────────────────────────────────────────

  static const String demoUserEmail = 'demo_user@divinepooja.com';
  static const String demoPanditEmail = 'demo_pandit@divinepooja.com';
  static const String demoAdminEmail = 'demo_admin@divinepooja.com';
  static const String demoPassword = 'Demo@123';

  /// Human-readable labels for the quick-login chips.
  static const List<DemoAccount> demoAccounts = [
    DemoAccount(
      label: 'Demo User',
      email: demoUserEmail,
      password: demoPassword,
      icon: '👤',
    ),
    DemoAccount(
      label: 'Demo Pandit',
      email: demoPanditEmail,
      password: demoPassword,
      icon: '🙏',
    ),
    DemoAccount(
      label: 'Demo Admin',
      email: demoAdminEmail,
      password: demoPassword,
      icon: '🛡️',
    ),
  ];
}

/// A pre-configured demo account entry.
class DemoAccount {
  const DemoAccount({
    required this.label,
    required this.email,
    required this.password,
    required this.icon,
  });

  final String label;
  final String email;
  final String password;
  final String icon;
}
