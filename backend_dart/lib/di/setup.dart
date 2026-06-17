import 'dart:io';
import 'package:dotenv/dotenv.dart';

import 'package:backend_dart/repositories/order_repository.dart';
import 'package:backend_dart/repositories/report_repository.dart';
import 'package:backend_dart/services/auth_service.dart';
import 'package:backend_dart/services/dashboard_service.dart';
import 'package:backend_dart/services/inventory_service.dart';
import 'package:backend_dart/services/menu_service.dart';
import 'package:backend_dart/services/order_service.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';

final getIt = GetIt.instance;

bool _isInitialized = false;
final _env = DotEnv(includePlatformEnvironment: true);

/// Lê uma variável de ambiente obrigatória.
/// Lança [StateError] imediatamente se a variável não estiver configurada,
/// garantindo falha rápida e ruidosa em vez de usar credenciais hard-coded.
String _requireEnv(String key) {
  final value = _env[key];
  if (value == null || value.isEmpty) {
    throw StateError(
      '❌ Variável de ambiente "$key" não configurada. '
      'Defina-a no arquivo .env do backend antes de iniciar o servidor.',
    );
  }
  return value;
}

/// Injeção de Dependências (Factory 2 — Backend Dart Frog)
/// Registra todos os Services e Repositories com suas dependências.
/// Padrão: LazySingleton — cada instância é criada apenas uma vez.
void setupDependencyInjection() {
  if (_isInitialized) return;

  // Carrega o arquivo .env
  try {
    _env.load(['.env']);
  } catch (e) {
    print('Aviso: Não foi possível carregar o arquivo .env: $e');
  }

  // 1. Supabase Client (Singleton base)
  // As variáveis de ambiente SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY
  // devem ser definidas no arquivo .env do backend_dart/ (não comitado no Git).
  final supabaseUrl = _requireEnv('SUPABASE_URL');
  final supabaseKey = _requireEnv('SUPABASE_PUBLISHABLE_KEY');

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);
  getIt.registerLazySingleton<SupabaseClient>(() => supabase);

  // 2. Repositories — camada de acesso a dados (sem lógica de negócio)

  /// Pedidos: acesso direto às tabelas pedidos/pedido_itens e RPC de baixa de estoque
  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepository(getIt<SupabaseClient>()),
  );

  /// Relatórios: queries de leitura para métricas brutas do dashboard
  getIt.registerLazySingleton<ReportRepository>(
    () => ReportRepository(getIt<SupabaseClient>()),
  );

  // 3. Services — camada de lógica de negócio

  /// Autenticação: Login, Logout e gestão de sessão via Supabase Auth
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(getIt<SupabaseClient>()),
  );

  /// Pedidos: Criação, atualização de status e orquestração da baixa de estoque
  getIt.registerLazySingleton<OrderService>(
    () => OrderService(getIt<SupabaseClient>()),
  );

  /// Dashboard: Cálculo dos 7 KPIs (Receita, CMV, Lucro, Margem, Ticket, Despesas, Pedidos)
  getIt.registerLazySingleton<DashboardService>(
    () => DashboardService(getIt<SupabaseClient>()),
  );

  /// Estoque: Entrada de insumos, ajuste manual e alertas de mínimo via RPC
  getIt.registerLazySingleton<InventoryService>(
    () => InventoryService(getIt<SupabaseClient>()),
  );

  /// Cardápio: Criação de produtos e sua ficha técnica associada
  getIt.registerLazySingleton<MenuService>(
    () => MenuService(getIt<SupabaseClient>()),
  );

  _isInitialized = true;
}
