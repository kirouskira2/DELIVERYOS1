import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/responsive.dart';

/// AppShell — Sidebar adaptativa com Glassmorphism.
/// Desktop: Sidebar lateral animada.
/// Mobile: BottomNavigationBar (5 itens) + Drawer para rotas secundárias.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  /// Todos os itens de navegação.
  static const _allNavItems = [
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

  /// Itens visíveis na BottomNav mobile (máximo 4 + "Mais").
  static const _mobileNavItems = [
    _NavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard', path: '/dashboard'),
    _NavItem(icon: LucideIcons.shoppingCart, label: 'PDV', path: '/pdv'),
    _NavItem(icon: LucideIcons.utensils, label: 'Cardápio', path: '/cardapio'),
    _NavItem(icon: LucideIcons.trendingUp, label: 'Financeiro', path: '/financeiro'),
  ];



  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      key: const ValueKey('app_shell_scaffold'),
      backgroundColor: const Color(0xFF020617),
      drawer: isDesktop ? null : _AppDrawer(
        allNavItems: _allNavItems,
        currentPath: currentPath,
      ),
      body: Row(
        children: [
          // Sidebar apenas em Desktop
          if (isDesktop) _Sidebar(navItems: _allNavItems, currentPath: currentPath),

          // Conteúdo principal
          Expanded(
            child: Column(
              children: [
                _TopBar(currentPath: currentPath, isDesktop: isDesktop),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar apenas em Mobile/Tablet
      bottomNavigationBar: isDesktop
          ? null
          : _MobileBottomNav(
              mobileNavItems: _mobileNavItems,
              currentPath: currentPath,
            ),
    );
  }
}

// ─── DRAWER PARA MOBILE ─────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final List<_NavItem> allNavItems;
  final String currentPath;

  const _AppDrawer({required this.allNavItems, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do Drawer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text('OS', style: TextStyle(
                      fontFamily: 'Inter', color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 16,
                    )),
                  ),
                  const SizedBox(width: 12),
                  const Text('Delivery OS', style: TextStyle(
                    fontFamily: 'Inter', color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 18,
                  )),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 8),

            // Itens de navegação
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: allNavItems.length,
                itemBuilder: (context, index) {
                  final item = allNavItems[index];
                  final isActive = currentPath.startsWith(item.path);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      selected: isActive,
                      selectedTileColor: const Color(0xFF2563EB).withOpacity(0.15),
                      leading: Icon(
                        item.icon, size: 20,
                        color: isActive ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
                      ),
                      title: Text(item.label, style: TextStyle(
                        fontFamily: 'Inter', fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? Colors.white : const Color(0xFF94A3B8),
                      )),
                      onTap: () {
                        Navigator.pop(context); // Fechar drawer
                        context.go(item.path);
                      },
                    ),
                  );
                },
              ),
            ),

            // Botão Logout
            const Divider(color: Color(0xFF1E293B), height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              leading: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFEF4444)),
              title: const Text('Sair', style: TextStyle(
                fontFamily: 'Inter', fontSize: 14, color: Color(0xFFEF4444),
              )),
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM NAV MOBILE (Máx 5 destinos) ─────────────────────────────────────

class _MobileBottomNav extends StatelessWidget {
  final List<_NavItem> mobileNavItems;
  final String currentPath;

  const _MobileBottomNav({required this.mobileNavItems, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    // Determinar se a rota atual está em uma das abas mobile ou é uma "mais"
    int selectedIndex = mobileNavItems.indexWhere(
      (e) => currentPath.startsWith(e.path),
    );
    // Se a rota não está nas abas mobile, selecionar "Mais" (índice 4)
    final isOnMoreRoute = selectedIndex == -1;
    if (isOnMoreRoute) selectedIndex = 4;

    return NavigationBar(
      backgroundColor: const Color(0xFF0F172A),
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFF2563EB).withOpacity(0.2),
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: selectedIndex.clamp(0, 4),
      onDestinationSelected: (i) {
        if (i < mobileNavItems.length) {
          context.go(mobileNavItems[i].path);
        } else {
          // "Mais" → Abrir Drawer
          Scaffold.of(context).openDrawer();
        }
      },
      destinations: [
        ...mobileNavItems.map((e) => NavigationDestination(
          icon: Icon(e.icon, size: 20, color: const Color(0xFF94A3B8)),
          selectedIcon: Icon(e.icon, size: 20, color: const Color(0xFF60A5FA)),
          label: e.label,
        )),
        NavigationDestination(
          icon: Icon(
            LucideIcons.moreHorizontal, size: 20,
            color: isOnMoreRoute ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
          ),
          selectedIcon: const Icon(LucideIcons.moreHorizontal, size: 20, color: Color(0xFF60A5FA)),
          label: 'Mais',
        ),
      ],
    );
  }
}

// ─── SIDEBAR DESKTOP (preservada com pequenas melhorias) ─────────────────────

class _Sidebar extends StatefulWidget {
  final List<_NavItem> navItems;
  final String currentPath;
  const _Sidebar({required this.navItems, required this.currentPath});

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _isHovered = false;
  int _hoveredIndex = -1;

  static const double _minWidth = 70.0;
  static const double _maxWidth = 220.0;
  static const double _itemHeight = 44.0;
  static const double _itemSpacing = 4.0;

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.navItems.indexWhere((e) => widget.currentPath.startsWith(e.path));

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
          color: Color(0xFF0F172A),
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
            // Itens de navegação com pílula de seleção animada
            Expanded(
              child: Stack(
                children: [
                  // --- PILULA DESLIZANTE DE SELEÇÃO ---
                  if (activeIndex != -1)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      top: activeIndex * (_itemHeight + _itemSpacing),
                      left: 12,
                      right: 12,
                      height: _itemHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2563EB).withOpacity(0.18),
                              const Color(0xFF2563EB).withOpacity(0.04),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  
                  // --- LISTA DE ITENS INTERATIVOS ---
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.navItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.navItems[index];
                      final isActive = index == activeIndex;
                      final isHovered = index == _hoveredIndex;

                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredIndex = index),
                        onExit: (_) => setState(() => _hoveredIndex = -1),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: _itemSpacing),
                          child: _SidebarItem(
                            item: item,
                            isActive: isActive,
                            isHovered: isHovered,
                            isExpanded: _isHovered,
                            height: _itemHeight,
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
    return GestureDetector(
      onTap: () => context.go('/dashboard'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
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
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isHovered;
  final bool isExpanded;
  final double height;
  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.isHovered,
    required this.isExpanded,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.path),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: (!isActive && isHovered)
                ? Colors.white.withOpacity(0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: isActive
                    ? const Color(0xFF60A5FA)
                    : (isHovered ? Colors.white : const Color(0xFF94A3B8)),
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
                                : (isHovered ? Colors.white70 : const Color(0xFF94A3B8)),
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

// ─── TOPBAR ──────────────────────────────────────────────────────────────────

class _TopBar extends StatefulWidget {
  final String currentPath;
  final bool isDesktop;
  const _TopBar({required this.currentPath, required this.isDesktop});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final _supabase = Supabase.instance.client;
  List<String> _notifications = [];


  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;


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
        });
      }
    } catch (_) {
      // Silently handle errors
    }
  }

  void _showNotificationsOverlay() {
    final screenWidth = MediaQuery.of(context).size.width;
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
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth < 500 ? screenWidth * 0.85 : 400,
          ),
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
                      Text('Nenhum alerta de estoque ou novos pedidos.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontFamily: 'Inter'), textAlign: TextAlign.center),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          // Botão hamburger no mobile
          if (!widget.isDesktop)
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(LucideIcons.menu, color: Color(0xFF94A3B8), size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          if (!widget.isDesktop) const SizedBox(width: 8),

          Expanded(
            child: Text(_title,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFFF8FAFC),
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _showNotificationsOverlay,
                icon: const Icon(LucideIcons.bell, color: Color(0xFF94A3B8), size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  right: -2,
                  top: -2,
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
