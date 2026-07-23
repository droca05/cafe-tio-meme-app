import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/clientes/presentation/cliente_detail_screen.dart';
import '../../features/clientes/presentation/clientes_list_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/kpis/presentation/kpis_screen.dart';
import '../../features/solicitudes/presentation/editar_solicitud_screen.dart';
import '../../features/solicitudes/presentation/nueva_solicitud_screen.dart';
import '../../features/solicitudes/presentation/solicitud_detail_screen.dart';
import '../../features/solicitudes/presentation/solicitudes_list_screen.dart';

/// Convierte el Stream de authStateChanges en un Listenable
/// para que GoRouter reevalúe el redirect ante cambios de sesión.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authRepository.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/kpis',
        builder: (context, state) => const KpisScreen(),
      ),
      GoRoute(
        path: '/solicitudes',
        builder: (context, state) => const SolicitudesListScreen(),
      ),
      GoRoute(
        path: '/solicitudes/nueva',
        builder: (context, state) => const NuevaSolicitudScreen(),
      ),
      GoRoute(
        path: '/solicitudes/:id',
        builder: (context, state) => SolicitudDetailScreen(
          solicitudId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/solicitudes/:id/editar',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditarSolicitudScreen(solicitudId: id);
        },
      ),
      GoRoute(
        path: '/clientes',
        builder: (context, state) => const ClientesListScreen(),
      ),
      GoRoute(
        path: '/clientes/:id',
        builder: (context, state) => ClienteDetailScreen(
          clienteId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
