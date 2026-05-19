import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    
    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception("SUPABASE_URL ou SUPABASE_ANON_KEY não estão configurados no arquivo .env");
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    runApp(const DeliveryOSApp());
  } catch (e, stackTrace) {
    debugPrint("ERRO CRÍTICO NA INICIALIZAÇÃO: $e");
    debugPrint(stackTrace.toString());
    
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Erro de Inicialização',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontFamily: 'Monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verifique o arquivo .env ou o console de desenvolvimento.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class DeliveryOSApp extends StatelessWidget {
  const DeliveryOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Delivery OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
    );
  }
}
