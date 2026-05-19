import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sprint 5.10: ConfiguracoesScreen — Perfil, dados do restaurante e logout
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _isLoggingOut = false;

  String get _userEmail => Supabase.instance.client.auth.currentUser?.email ?? 'Usuário Local';
  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? 'Dev Mode';

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do perfil
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _userEmail.isNotEmpty ? _userEmail[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Administrador',
                      style: TextStyle(fontFamily: 'Inter',
                          color: Color(0xFFF8FAFC),
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(_userEmail,
                      style: const TextStyle(fontFamily: 'Inter',
                          color: Color(0xFF64748B), fontSize: 13)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Admin',
                    style: TextStyle(fontFamily: 'Inter',
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Seção: Sistema
          const _SectionTitle(label: 'Sistema'),
          const SizedBox(height: 12),

          _ConfigItem(
            icon: LucideIcons.database,
            label: 'ID do Banco de Dados',
            value: _userId.length > 16 ? '${_userId.substring(0, 16)}...' : _userId,
            iconColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 8),
          const _ConfigItem(
            icon: LucideIcons.shield,
            label: 'Segurança',
            value: 'RLS Ativado · Supabase Auth',
            iconColor: Color(0xFF34D399),
          ),
          const SizedBox(height: 8),
          const _ConfigItem(
            icon: LucideIcons.server,
            label: 'Backend',
            value: 'Dart Frog · localhost:8080',
            iconColor: Color(0xFFA78BFA),
          ),

          const SizedBox(height: 24),

          // Seção: Sobre o App
          const _SectionTitle(label: 'Sobre'),
          const SizedBox(height: 12),

          const _ConfigItem(
            icon: LucideIcons.info,
            label: 'Versão',
            value: '1.0.0 (Prisma V4.0)',
            iconColor: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 8),
          const _ConfigItem(
            icon: LucideIcons.cpu,
            label: 'Motor',
            value: 'Flutter · Dart Frog · Supabase',
            iconColor: Color(0xFFF59E0B),
          ),
          const SizedBox(height: 8),
          const _ConfigItem(
            icon: LucideIcons.user,
            label: 'Arquiteto',
            value: 'Pedro Lucas Santos de Araújo',
            iconColor: Color(0xFF2563EB),
          ),

          const SizedBox(height: 32),

          // Botão de logout
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isLoggingOut ? null : _logout,
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)))
                  : const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFEF4444)),
              label: Text(
                _isLoggingOut ? 'Saindo...' : 'Encerrar Sessão',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Versão rodapé
          const Center(
            child: Text(
              'Delivery OS · Powered by Prisma V4.0',
              style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF334155),
                  fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2));
  }
}

class _ConfigItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  const _ConfigItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontFamily: 'Inter',
                    color: Color(0xFF94A3B8), fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(fontFamily: 'Inter',
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }
}
