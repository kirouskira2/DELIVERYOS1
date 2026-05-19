import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/pdv/pdv_screen.dart';
import '../screens/estoque/estoque_screen.dart';
import '../screens/financeiro/financeiro_screen.dart';
import '../screens/cardapio/cardapio_screen.dart';
import '../screens/clientes/clientes_screen.dart';
import '../screens/fornecedores/fornecedores_screen.dart';
import '../screens/relatorios/relatorios_screen.dart';
import '../screens/configuracoes/configuracoes_screen.dart';
import '../widgets/shell/app_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Router principal com Auth Guard reativado
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggingIn = state.matchedLocation == '/login';

      if (session == null && !isLoggingIn) return '/login';
      if (session != null && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/pdv',
            builder: (context, state) => const PdvScreen(),
          ),
          GoRoute(
            path: '/cardapio',
            builder: (context, state) => const CardapioScreen(),
          ),
          GoRoute(
            path: '/estoque',
            builder: (context, state) => const EstoqueScreen(),
          ),
          GoRoute(
            path: '/financeiro',
            builder: (context, state) => const FinanceiroScreen(),
          ),
          GoRoute(
            path: '/clientes',
            builder: (context, state) => const ClientesScreen(),
          ),
          GoRoute(
            path: '/fornecedores',
            builder: (context, state) => const FornecedoresScreen(),
          ),
          GoRoute(
            path: '/relatorios',
            builder: (context, state) => const RelatoriosScreen(),
          ),
          GoRoute(
            path: '/configuracoes',
            builder: (context, state) => const ConfiguracoesScreen(),
          ),
        ],
      ),
    ],
  );
}
