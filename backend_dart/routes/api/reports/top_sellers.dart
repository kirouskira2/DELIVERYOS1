import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

import 'package:backend_dart/di/setup.dart';

Future<Response> onRequest(RequestContext context) async {
  final supabase = getIt<SupabaseClient>();

  if (context.request.method == HttpMethod.get) {
    try {
      final topSellers = await supabase.from('view_top_sellers').select('*');
      final melhoresClientes = await supabase.from('view_melhores_clientes_b2b').select('*');
      return Response.json(body: {
        'success': true, 
        'data': {
          'top_sellers': topSellers,
          'melhores_clientes': melhoresClientes
        }
      });
    } catch (e) {
      return Response.json(statusCode: 500, body: {'success': false, 'error': e.toString()});
    }
  }

  return Response.json(statusCode: 405, body: {'success': false, 'error': 'Method Not Allowed'});
}
