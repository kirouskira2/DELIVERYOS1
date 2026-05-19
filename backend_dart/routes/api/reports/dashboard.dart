import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/dashboard_service.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'error': 'Method Not Allowed'},
    );
  }

  try {
    final params = context.request.uri.queryParameters;
    final dataInicio =
        DateTime.tryParse(params['data_inicio'] ?? '') ??
        DateTime.now().subtract(const Duration(days: 30));
    final dataFim =
        DateTime.tryParse(params['data_fim'] ?? '') ?? DateTime.now();

    final dashboardService = getIt<DashboardService>();
    final result = await dashboardService.getMetrics(
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    return Response.json(
      statusCode: result.statusCode,
      body: result.success
          ? {'success': true, 'data': result.data}
          : {'success': false, 'error': result.error},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'error': 'Failed to load dashboard metrics',
        'details': e.toString(),
      },
    );
  }
}
