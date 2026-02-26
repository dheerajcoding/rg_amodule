import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/signup_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../packages/screens/packages_screen.dart';
import '../../packages/screens/package_detail_screen.dart';
import '../../booking/screens/booking_screen.dart';
import '../../booking/screens/booking_wizard_screen.dart';
import '../../booking/screens/booking_detail_screen.dart';
import '../../booking/screens/proof_upload_screen.dart';
import '../../consultation/screens/consultation_screen.dart';
import '../../consultation/screens/chat_screen.dart';
import '../../consultation/models/consultation_session.dart';
import '../../shop/screens/shop_screen.dart';
import '../../shop/screens/product_detail_screen.dart';
import '../../shop/screens/cart_screen.dart';
import '../../shop/screens/checkout_screen.dart';
import '../../admin/screens/admin_screen.dart';
import '../../admin/screens/admin_poojas_screen.dart';
import '../../admin/screens/admin_pandits_screen.dart';
import '../../admin/screens/admin_bookings_screen.dart';
import '../../admin/screens/admin_consultations_screen.dart';
import '../../admin/screens/admin_reports_screen.dart';
import '../../pandit/screens/pandit_screen.dart';
import '../../pandit/screens/pandit_booking_detail_screen.dart';
import '../../services/screens/services_screen.dart';
import '../../splash/splash_screen.dart';
import '../../widgets/bottom_nav_shell.dart';
import '../../models/role_enum.dart';

// ── Route path constants ───────────────────────────────────────────────────────
abstract class Routes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const register = '/register'; // kept for backward-compat, redirects to signup
  static const home = '/home';
  static const packages = '/packages';
  static const booking = '/booking';
  static const consultation = '/consultation';
  static const consultationChat = '/consultation/chat';
  static const shop = '/shop';
  static const productDetail = '/shop/product/:id';
  static const cart = '/shop/cart';
  static const checkout = '/shop/checkout';
  static const admin = '/admin';
  static const adminPoojas = '/admin/poojas';
  static const adminPandits = '/admin/pandits';
  static const adminBookings = '/admin/bookings';
  static const adminConsultations = '/admin/consultations';
  static const adminReports = '/admin/reports';
  static const pandit = '/pandit';
  static const panditBookingDetail = '/pandit/booking/:id';
  static const services = '/services';
  static const packageDetail = '/packages/:id';
  static const bookingWizard = '/booking/wizard';
  static const bookingDetail = '/booking/:id';
  static const bookingUploadProof = '/booking/:id/upload-proof';
}

// ── RouterNotifier (ChangeNotifier that drives GoRouter refresh) ───────────────
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    // Listen to auth state changes and notify GoRouter to re-evaluate redirects.
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  /// Central redirect logic called on every navigation event.
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final location = state.matchedLocation;

    final bool isOnSplash = location == Routes.splash;
    final bool isOnAuth = location.startsWith(Routes.login) ||
        location.startsWith(Routes.signup) ||
        location.startsWith(Routes.register);

    // ── 1. Still initialising (checking persisted session) ─────────────────
    if (authState is AuthInitial || authState is AuthLoading) {
      return isOnSplash ? null : Routes.splash;
    }

    // ── 2. Email confirmation pending — stay on auth screen ────────────────
    if (authState is AuthEmailConfirmationPending) {
      return isOnAuth ? null : Routes.login;
    }

    // ── 3. Unauthenticated or Error — always send to login ─────────────────
    if (authState is AuthUnauthenticated || authState is AuthError) {
      if (isOnAuth) return null; // already on login/signup
      return Routes.login;       // from splash or any other screen → login
    }

    // ── 4. Authenticated ───────────────────────────────────────────────────────────
    if (authState is AuthAuthenticated) {
      // Redirect away from splash / auth screens
      if (isOnSplash || isOnAuth) return Routes.home;

      final user = authState.user;

      // Admin guard
      if (location.startsWith(Routes.admin) && !user.role.isAdmin) {
        return Routes.home;
      }

      // Pandit guard (admin may also view pandit dashboard)
      if (location.startsWith(Routes.pandit) &&
          !user.role.isPandit &&
          !user.role.isAdmin) {
        return Routes.home;
      }

      return null; // allow navigation
    }

    return null;
  }
}

// ── Bottom-nav destination config ────────────────────────────────────────────
final _navDestinations = [
  const NavDestination(
    label: 'Home',
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home),
    initialLocation: Routes.home,
  ),
  const NavDestination(
    label: 'Packages',
    icon: Icon(Icons.folder_outlined),
    activeIcon: Icon(Icons.folder),
    initialLocation: Routes.packages,
  ),
  const NavDestination(
    label: 'Booking',
    icon: Icon(Icons.calendar_today_outlined),
    activeIcon: Icon(Icons.calendar_today),
    initialLocation: Routes.booking,
  ),
  const NavDestination(
    label: 'Consult',
    icon: Icon(Icons.video_call_outlined),
    activeIcon: Icon(Icons.video_call),
    initialLocation: Routes.consultation,
  ),
  const NavDestination(
    label: 'Shop',
    icon: Icon(Icons.store_outlined),
    activeIcon: Icon(Icons.store),
    initialLocation: Routes.shop,
  ),
];

// ── Router Provider ────────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (_, _) => const SplashScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: Routes.signup,
        name: 'signup',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignupScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      // Legacy alias → redirect to /signup
      GoRoute(
        path: Routes.register,
        name: 'register',
        redirect: (_, _) => Routes.signup,
      ),

      // ── Main Shell (Bottom Navigation) ────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BottomNavShell(
          navigationShell: navigationShell,
          destinations: _navDestinations,
        ),
        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                name: 'home',
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          // Packages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.packages,
                name: 'packages',
                builder: (_, _) => const PackagesScreen(),
              ),
            ],
          ),
          // Booking
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.booking,
                name: 'booking',
                builder: (_, _) => const BookingScreen(),
              ),
            ],
          ),
          // Consultation
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.consultation,
                name: 'consultation',
                builder: (_, _) => const ConsultationScreen(),
              ),
            ],
          ),
          // Shop
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.shop,
                name: 'shop',
                builder: (_, _) => const ShopScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Services (outside shell, accessible from Home) ────────────────────
      GoRoute(
        path: Routes.services,
        name: 'services',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ServicesScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),

      // ── Admin (role-guarded) ──────────────────────────────────────────────
      GoRoute(
        path: Routes.admin,
        name: 'admin',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: Routes.adminPoojas,
        name: 'admin-poojas',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminPoojasScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: Routes.adminPandits,
        name: 'admin-pandits',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminPanditsScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: Routes.adminBookings,
        name: 'admin-bookings',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminBookingsScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: Routes.adminConsultations,
        name: 'admin-consultations',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminConsultationsScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: Routes.adminReports,
        name: 'admin-reports',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminReportsScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),

      // ── Pandit (role-guarded) ─────────────────────────────────────────────
      GoRoute(
        path: Routes.pandit,
        name: 'pandit',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PanditScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      // ── Pandit booking detail ─────────────────────────────────────────────
      GoRoute(
        path: '/pandit/booking/:id',
        name: 'pandit-booking-detail',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: PanditBookingDetailScreen(
            bookingId: state.pathParameters['id']!,
          ),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      // ── Package detail ────────────────────────────────────────────────────
      GoRoute(
        path: '/packages/:id',
        name: 'package-detail',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: PackageDetailScreen(
            packageId: state.pathParameters['id']!,
          ),
          transitionsBuilder: _slideRightTransition,
        ),
      ),

      // ── Booking wizard ────────────────────────────────────────────────────
      GoRoute(
        path: Routes.bookingWizard,
        name: 'booking-wizard',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BookingWizardScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ── Booking detail ────────────────────────────────────────────────────
      GoRoute(
        path: '/booking/:id',
        name: 'booking-detail',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BookingDetailScreen(
            bookingId: state.pathParameters['id']!,
          ),
          transitionsBuilder: _slideRightTransition,
        ),
      ),

      // ── Upload proof ──────────────────────────────────────────────────────
      GoRoute(
        path: '/booking/:id/upload-proof',
        name: 'booking-upload-proof',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ProofUploadScreen(
            bookingId: state.pathParameters['id']!,
            panditId: (state.extra as Map?)?['panditId'] as String? ?? 'mock_pandit',
            bookingTitle: (state.extra as Map?)?['title'] as String? ?? 'Service',
          ),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ── Shop: product detail ─────────────────────────────────────────────────
      GoRoute(
        path: '/shop/product/:id',
        name: 'product-detail',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ProductDetailScreen(
            productId: state.pathParameters['id']!,
          ),
          transitionsBuilder: _slideRightTransition,
        ),
      ),

      // ── Shop: cart ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/shop/cart',
        name: 'cart',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CartScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),

      // ── Shop: checkout ────────────────────────────────────────────────────────
      GoRoute(
        path: '/shop/checkout',
        name: 'checkout',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CheckoutScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ── Consultation chat session ───────────────────────────────────────────
      GoRoute(
        path: '/consultation/chat',
        name: 'consultation-chat',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ChatScreen(
            session: state.extra as ConsultationSession,
          ),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
    ],

    // Global error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri.path}',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// ── Page Transition Helpers ───────────────────────────────────────────────────
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) =>
    FadeTransition(opacity: animation, child: child);

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) =>
    SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    );

Widget _slideRightTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) =>
    SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    );
