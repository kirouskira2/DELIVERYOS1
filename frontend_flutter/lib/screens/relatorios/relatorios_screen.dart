import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../services/reports_repository.dart';
import '../../utils/responsive.dart';

/// Tela de Relatórios — Gráficos e Rankings Responsivos
class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  final ReportsRepository _repository = ReportsRepository();
  bool _isLoading = true;
  String _periodo = '30';
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _repository.getReportData(days: int.parse(_periodo));
      if (mounted) setState(() { _data = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _data = {}; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF3B82F6),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    const SizedBox(height: 20),
                    _buildRevenueChart(isMobile),
                    const SizedBox(height: 24),
                    _buildRankingsSection(isMobile),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isMobile) {
    final dropdown = DropdownButton<String>(
      value: _periodo,
      dropdownColor: const Color(0xFF1E293B),
      underline: const SizedBox(),
      borderRadius: BorderRadius.circular(8),
      style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
      icon: const Icon(LucideIcons.chevronDown, size: 16, color: Colors.grey),
      items: const [
        DropdownMenuItem(value: '7', child: Text('Últimos 7 dias')),
        DropdownMenuItem(value: '30', child: Text('Últimos 30 dias')),
        DropdownMenuItem(value: '90', child: Text('Últimos 90 dias')),
      ],
      onChanged: (val) {
        if (val != null) { setState(() => _periodo = val); _load(); }
      },
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Relatórios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                  child: dropdown,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _exportReport(),
                icon: const Icon(LucideIcons.download, color: Color(0xFF60A5FA), size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Relatórios', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
              child: dropdown,
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _exportReport(),
              icon: const Icon(LucideIcons.download, size: 16),
              label: const Text('Exportar', style: TextStyle(fontFamily: 'Inter')),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF60A5FA),
                side: const BorderSide(color: Color(0xFF334155)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de exportação em breve!'), backgroundColor: Color(0xFF3B82F6)),
    );
  }

  // ─── GRÁFICO DE RECEITA ──────────────────────────────────────────────────

  Widget _buildRevenueChart(bool isMobile) {
    final List pedidosLista = _data['pedidos_lista'] as List? ?? [];
    final List<FlSpot> spots = List.generate(
      pedidosLista.length,
      (i) => FlSpot(i.toDouble(), (pedidosLista[i]['valor_total'] as num?)?.toDouble() ?? 0.0),
    );
    final List<FlSpot> finalSpots = spots.length >= 2
        ? spots
        : [
            if (spots.isEmpty) const FlSpot(0, 0) else spots.first,
            FlSpot(1.0, spots.isEmpty ? 0.0 : spots.first.y),
          ];
    final double maxX = (finalSpots.length - 1).toDouble();
    
    double maxVal = 100.0;
    for (var s in finalSpots) { if (s.y > maxVal) maxVal = s.y; }
    final double finalMaxY = maxVal * 1.15;

    return Container(
      height: isMobile ? 240 : 350,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evolução de Receitas', style: TextStyle(fontFamily: 'Inter', fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600, color: const Color(0xFFF8FAFC))),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, drawVerticalLine: false, drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFF1E293B).withOpacity(0.4), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: !isMobile,
                    reservedSize: 55,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('R\$ ${value.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'Inter')),
                      );
                    },
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: (finalSpots.length > 5) ? (finalSpots.length / (isMobile ? 3 : 5)).floorToDouble().clamp(1, double.infinity) : 1.0,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < finalSpots.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('D${index + 1}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'Inter')),
                        );
                      }
                      return const SizedBox();
                    },
                  )),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: maxX, minY: 0, maxY: finalMaxY,
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFF0F172A),
                    tooltipBorder: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Dia ${spot.x.toInt() + 1}\nR\$ ${spot.y.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Inter'),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: finalSpots,
                    isCurved: true, curveSmoothness: 0.35,
                    color: const Color(0xFF38BDF8),
                    barWidth: 3.5, isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF38BDF8).withOpacity(0.18), const Color(0xFF38BDF8).withOpacity(0.0)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }

  // ─── RANKINGS ────────────────────────────────────────────────────────────

  Widget _buildRankingsSection(bool isMobile) {
    final topPratos = _data['top_pratos'] as List? ?? [];
    final topClientes = _data['top_clientes'] as List? ?? [];

    final pratosPanel = _buildRankingPanel(
      title: 'Pratos Mais Vendidos',
      icon: LucideIcons.trophy,
      iconColor: const Color(0xFFF59E0B),
      items: topPratos,
      itemBuilder: (item) => _RankingTile(
        title: item['nome'] ?? 'Desconhecido',
        subtitle: '${item['total_vendido'] ?? 0} vendidos',
        trailing: 'R\$ ${((item['receita'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
      ),
    );

    final clientesPanel = _buildRankingPanel(
      title: 'Melhores Clientes B2B',
      icon: LucideIcons.users,
      iconColor: const Color(0xFF3B82F6),
      items: topClientes,
      itemBuilder: (item) => _RankingTile(
        title: item['nome_empresa'] ?? 'Desconhecido',
        subtitle: '${item['total_pedidos'] ?? 0} pedidos',
        trailing: 'R\$ ${((item['total_gasto'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          pratosPanel,
          const SizedBox(height: 16),
          clientesPanel,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: pratosPanel),
        const SizedBox(width: 16),
        Expanded(child: clientesPanel),
      ],
    );
  }

  Widget _buildRankingPanel({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List items,
    required Widget Function(dynamic item) itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sem dados para o período selecionado.', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter')),
              ),
            )
          else
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: itemBuilder(item),
            )),
        ],
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;

  const _RankingTile({required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter', fontSize: 12)),
              ],
            ),
          ),
          Text(trailing, style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 14)),
        ],
      ),
    );
  }
}
