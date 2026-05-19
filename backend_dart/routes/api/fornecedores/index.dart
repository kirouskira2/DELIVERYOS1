import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

import 'package:backend_dart/di/setup.dart';

Future<Response> onRequest(RequestContext context) async {
  final supabase = getIt<SupabaseClient>();

  if (context.request.method == HttpMethod.get) {
    try {
      final data = await supabase
          .from('fornecedores')
          .select('*')
          .order('nome');
      return Response.json(body: {'success': true, 'data': data});
    } catch (e) {
      return Response.json(statusCode: 500, body: {'success': false, 'error': e.toString()});
    }
  }

  if (context.request.method == HttpMethod.post) {
    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final data = await supabase.from('fornecedores').insert(body).select().single();
      return Response.json(statusCode: 201, body: {'success': true, 'data': data});
    } catch (e) {
      return Response.json(statusCode: 500, body: {'success': false, 'error': e.toString()});
    }
  }

  return Response.json(statusCode: 405, body: {'success': false, 'error': 'Method Not Allowed'});
}
