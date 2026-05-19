import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sprint 4.3: AppShell — Sidebar adaptativa com Glassmorphism.
/// Estrutura visual do app: Sidebar (desktop) + BottomNav (mobile) + área de conteúdo.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard', path: '/dashboard'),
    _NavItem(icon: LucideIcons.shoppingCart, label: 'PDV', path: '/pdv'),
    _NavItem(icon: LucideIcons.utensils, label: 'Cardápio', path: '/cardapio'),
    _NavItem(icon: LucideIcons.package, label: 'Estoque', path: '/estoque'),
    _NavItem(icon: LucideIcons.trendingUp, label: 'Financeiro', path: '/financeiro'),
    _NavItem(icon: LucideIcons.users, label: 'Clientes', path: '/clientes'),
    _NavItem(icon: LucideIcons.truck, label: 'Fornecedores', path: '/fornecedores'),
    _NavItem(icon: LucideIcons.barChart2, label: 'Relatórios', path: '/relatorios'),
    _NavItem(icon: LucideIcons.settings, label: 'Config.', path: '/configuracoes'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Row(
        children: [
          // Sidebar apenas em Desktop
          if (isDesktop) _Sidebar(navItems: _navItems, currentPath: currentPath),

          // Conteúdo principal
          Expanded(
            child: Column(
              children: [
                _TopBar(currentPath: currentPath),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar apenas em Mobile
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              backgroundColor: const Color(0xFF0F172A),
              selectedIndex: _navItems.indexWhere((e) => currentPath.startsWith(e.path)).clamp(0, _navItems.length - 1),
              onDestinationSelected: (i) => context.go(_navItems[i].path),
              destinations: _navItems
                  .map((e) => NavigationDestination(icon: Icon(e.icon, size: 20), label: e.label))
                  .toList(),
            ),
    );
  }
}

/// Sidebar com efeito de animação elástica e detecção inteligente de mouse (Smart Hover)
class _Sidebar extends StatefulWidget {
  final List<_NavItem> navItems;
  final String currentPath;
  const _Sidebar({required this.navItems, required this.currentPath});

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _isHovered = false;

  static const double _minWidth = 70.0;
  static const double _maxWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        width: _isHovered ? _maxWidth : _minWidth,
        height: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border(
            right: BorderSide(color: Color(0xFF1E293B), width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Header da Sidebar (Logo) centralizada com switcher suave
            Center(child: _buildLogo()),
            const SizedBox(height: 48),
            // Itens de navegação
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: widget.navItems.map((item) {
                  final isActive = widget.currentPath.startsWith(item.path);
                  return _SidebarItem(
                    item: item, 
                    isActive: isActive, 
                    isExpanded: _isHovered,
                  );
                }).toList(),
              ),
            ),
            // Rodapé com botão de logout
            _SidebarLogoutButton(isExpanded: _isHovered),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _isHovered ? 164 : 40,
      height: 56,
      alignment: _isHovered ? Alignment.centerLeft : Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: _isHovered ? 12 : 0),
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        style: TextStyle(
          fontFamily: 'Inter',
          color: _isHovered ? Colors.white : Colors.blueAccent,
          fontSize: _isHovered ? 20 : 22,
          fontWeight: _isHovered ? FontWeight.bold : FontWeight.w900,
          letterSpacing: _isHovered ? -0.5 : 0,
        ),
        child: Text(
          _isHovered ? 'Delivery OS' : 'OS',
          maxLines: 2,
          overflow: TextOverflow.fade,
          softWrap: true,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isExpanded;
  const _SidebarItem({required this.item, required this.isActive, required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.path),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2563EB).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: const Color(0xFF2563EB).withOpacity(0.4))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isActive
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF94A3B8),
            ),
            Flexible(
              child: ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.centerLeft,
                  widthFactor: isExpanded ? 1 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isExpanded ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarLogoutButton extends StatelessWidget {
  final bool isExpanded;
  const _SidebarLogoutButton({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) context.go('/login');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            const Icon(LucideIcons.logOut, size: 18, color: Color(0xFF94A3B8)),
            Flexible(
              child: ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.centerLeft,
                  widthFactor: isExpanded ? 1 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isExpanded ? 1.0 : 0.0,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        'Sair',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontFamily: 'Inter',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  final String currentPath;
  const _TopBar({required this.currentPath});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final _supabase = Supabase.instance.client;
  List<String> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final List<String> newAlerts = [];

      // 1. Buscar itens abaixo do estoque mínimo
      final estoqueRes = await _supabase
          .from('estoque')
          .select('nome_item, quantidade_atual, quantidade_minima, unidade_medida');
      
      for (final item in estoqueRes) {
        final atual = (item['quantidade_atual'] as num).toDouble();
        final minima = (item['quantidade_minima'] as num).toDouble();
        if (atual <= minima) {
          newAlerts.add(
            'Estoque crítico: "${item['nome_item']}" está com ${atual.toStringAsFixed(1)} ${item['unidade_medida']} (Mínimo: ${minima.toStringAsFixed(1)}).',
          );
        }
      }

      // 2. Buscar novos pedidos pendentes
      final pedidosRes = await _supabase
          .from('pedidos')
          .select('id, tipo, valor_total')
          .eq('status', 'novo');
      
      if (pedidosRes.isNotEmpty) {
        newAlerts.add(
          'Há ${pedidosRes.length} novo(s) pedido(s) pendente(s) na fila!',
        );
      }

      if (mounted) {
        setState(() {
          _notifications = newAlerts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotificationsOverlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.bell, color: Color(0xFF3B82F6), size: 20),
                SizedBox(width: 8),
                Text('Notificações', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        content: SizedBox(
          width: 400,
          child: _notifications.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.checkCircle2, color: Color(0xFF34D399), size: 48),
                      SizedBox(height: 12),
                      Text('Tudo sob controle!', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Nenhum alerta de estoque ou novos pedidos.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontFamily: 'Inter')),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155)),
                  itemBuilder: (context, index) {
                    final alert = _notifications[index];
                    final isEstoque = alert.startsWith('Estoque');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isEstoque ? LucideIcons.alertTriangle : LucideIcons.shoppingBag,
                        color: isEstoque ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                      ),
                      title: Text(
                        alert,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Inter'),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadNotifications();
            },
            child: const Text('Atualizar', style: TextStyle(color: Color(0xFF3B82F6), fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  String get _title {
    const titles = {
      '/dashboard': 'Dashboard',
      '/pdv': 'PDV — Ponto de Venda',
      '/cardapio': 'Cardápio',
      '/estoque': 'Estoque',
      '/financeiro': 'Financeiro',
      '/clientes': 'Clientes',
      '/fornecedores': 'Fornecedores',
      '/relatorios': 'Relatórios',
      '/configuracoes': 'Configurações',
    };
    return titles.entries
        .firstWhere((e) => widget.currentPath.startsWith(e.key),
            orElse: () => const MapEntry('', 'Delivery OS'))
        .value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_title,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFF8FAFC),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _showNotificationsOverlay,
                icon: const Icon(LucideIcons.bell, color: Color(0xFF94A3B8), size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: Text(
                      '${_notifications.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}
