import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sprint 5.1: LoginScreen — Tela de autenticação premium (Dark Mode)
/// Conecta ao backend Dart Frog via HTTP POST /api/auth/login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isRegistering = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isRegistering) {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'As senhas não coincidem';
            _isLoading = false;
          });
          return;
        }

        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Deslogar automaticamente após criar conta para poder redirecionar para tela de login
        await Supabase.instance.client.auth.signOut();

        setState(() {
          _isRegistering = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
          _successMessage = 'Conta criada com sucesso! Por favor, verifique seu e-mail para confirmar a conta antes de fazer login.';
        });
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        if (mounted) {
          context.go('/dashboard');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _isRegistering 
            ? 'Erro ao criar conta. Tente novamente.' 
            : 'E-mail ou senha inválidos.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo e título
                const Icon(LucideIcons.utensils,
                    size: 40, color: Color(0xFF2563EB)),
                const SizedBox(height: 24),
                const Text(
                  'Delivery OS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegistering
                      ? 'Crie uma conta para começar.'
                      : 'Faça login para acessar seu painel.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 40),

                // Formulário
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Campo E-mail
                      _buildInputField(
                        controller: _emailController,
                        label: 'E-mail',
                        hint: 'seu@email.com',
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            v == null || !v.contains('@') ? 'E-mail inválido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Campo Senha
                      _buildInputField(
                        controller: _passwordController,
                        label: 'Senha',
                        hint: '••••••••',
                        icon: LucideIcons.lock,
                        obscureText: _obscurePassword,
                        textInputAction: _isRegistering ? TextInputAction.next : TextInputAction.done,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: const Color(0xFF94A3B8),
                            size: 18,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Senha obrigatória';
                          if (v.length < 6) return 'Senha muito curta (min. 6 caracteres)';
                          if (_isRegistering) {
                            final hasNumbers = RegExp(r'[0-9]').hasMatch(v);
                            final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(v);
                            final hasSpecial = RegExp(r'[\W_]').hasMatch(v);
                            if (!hasNumbers || !hasLetters || !hasSpecial) {
                              return 'A senha deve conter letras, números e caracteres especiais';
                            }
                          }
                          return null;
                        },
                        onFieldSubmitted: _isRegistering ? null : (_) => _isLoading ? null : _handleAuth(),
                      ),
                      
                      // Campo Confirmar Senha (apenas no registro)
                      if (_isRegistering) ...[
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _confirmPasswordController,
                          label: 'Confirmar Senha',
                          hint: '••••••••',
                          icon: LucideIcons.lock,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              color: const Color(0xFF94A3B8),
                              size: 18,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirmação de senha obrigatória';
                            if (v != _passwordController.text) return 'As senhas não coincidem';
                            return null;
                          },
                          onFieldSubmitted: (_) => _isLoading ? null : _handleAuth(),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Mensagem de erro
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFEF4444).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.alertCircle,
                                  color: Color(0xFFEF4444), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontFamily: 'Inter',
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Mensagem de sucesso
                      if (_successMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.checkCircle,
                                  color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_successMessage!,
                                    style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontFamily: 'Inter',
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 24),

                      // Botão de Auth
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(
                                  _isRegistering ? 'Criar Conta' : 'Entrar',
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Toggle para Criar Conta/Login
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isRegistering = !_isRegistering;
                              _errorMessage = null;
                              _successMessage = null;
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF334155)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            _isRegistering
                                ? 'Já tenho uma conta (Fazer Login)'
                                : 'Ainda não tem conta? Criar agora',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                                fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFCBD5E1))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          autocorrect: false,
          enableSuggestions: !obscureText,
          style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF475569)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E293B)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E293B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ),
      ],
    );
  }
}
