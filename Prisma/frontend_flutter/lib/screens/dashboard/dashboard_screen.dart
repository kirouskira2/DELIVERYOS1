import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/dashboard_repository.dart';

/// Sprint 5.2: DashboardScreen — KPIs animados + LineChart de receita (Refatorado para API)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardRepository _repository = DashboardRepository();
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final data = await _repository.getMetrics(
        dataInicio: startOfMonth,
        dataFim: now,
      );

      if (mounted) {
        setState(() {
          _metrics = {
            'receita': data['receita_total'] ?? 0.0,
            'cmv': data['cmv_total'] ?? 0.0,
            'lucro': data['lucro_bruto'] ?? 0.0,
            'margem': data['margem_pct'] ?? 0.0,
            'ticket_medio': data['ticket_medio'] ?? 0.0,
            'pedidos': data['quantidade_pedidos'] ?? 0,
            // Removido mock do gráfico: agora ele vem da API
            'pedidos_lista': data['pedidos_lista'] ?? [],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Em caso de erro real, mostrar zero em vez de dados falsos
          _metrics = {
            'receita': 0.0,
            'cmv': 0.0,
            'lucro': 0.0,
            'margem': 0.0,
            'ticket_medio': 0.0,
            'pedidos': 0,
            'pedidos_lista': [],
          };
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildShimmerGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(4, (index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF1E293B),
          highlightColor: const Color(0xFF334155),
          child: Container(
            width: 160,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadMetrics,
      color: const Color(0xFF2563EB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF8FAFC))),
            const SizedBox(height: 4),
            const Text('Visão gerencial de alto nível do sistema.',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF94A3B8))),
            const SizedBox(height: 24),

            if (_isLoading)
              _buildShimmerGrid()
            else
              LayoutBuilder(builder: (context, constraints) {
                final cols = constraints.maxWidth > 700 ? 4 : 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _KpiCard(
                      label: 'Receita Total',
                      value: 'R\$ ${_metrics['receita']?.toStringAsFixed(2)}',
                      icon: LucideIcons.trendingUp,
                      color: const Color(0xFF34D399),
                      width: (constraints.maxWidth - (cols - 1) * 16) / cols,
                    ),
                    _KpiCard(
                      label: 'CMV',
                      value: 'R\$ ${_metrics['cmv']?.toStringAsFixed(2)}',
                      icon: LucideIcons.shoppingBag,
                      color: const Color(0xFFEF4444),
                      width: (constraints.maxWidth - (cols - 1) * 16) / cols,
                    ),
                    _KpiCard(
                      label: 'Lucro Bruto',
                      value: 'R\$ ${_metrics['lucro']?.toStringAsFixed(2)}',
                      icon: LucideIcons.dollarSign,
                      color: const Color(0xFF3B82F6),
                      width: (constraints.maxWidth - (cols - 1) * 16) / cols,
                    ),
                    _KpiCard(
                      label: 'Margem (%)',
                      value: '${_metrics['margem']?.toStringAsFixed(1)}%',
                      icon: LucideIcons.percent,
                      color: const Color(0xFFF59E0B),
                      width: (constraints.maxWidth - (cols - 1) * 16) / cols,
                    ),
                  ],
                );
              }),
            const SizedBox(height: 32),

            if (_isLoading)
              Shimmer.fromColors(
                baseColor: const Color(0xFF1E293B),
                highlightColor: const Color(0xFF334155),
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )
            else
              Container(
                height: 350,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Evolução de Receitas',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF8FAFC))),
                    const SizedBox(height: 24),
                    Expanded(
                      child: () {
                        final List pedidosLista = _metrics['pedidos_lista'] as List? ?? [];
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
                        
                        // Encontra o valor máximo para ajustar o maxY dinamicamente
                        double maxVal = 100.0;
                        for (var s in finalSpots) {
                          if (s.y > maxVal) maxVal = s.y;
                        }
                        final double finalMaxY = maxVal * 1.15;

                        return LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              drawHorizontalLine: true,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: const Color(0xFF1E293B).withOpacity(0.4),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 55,
                                  getTitlesWidget: (value, meta) {
                                    if (value == meta.max || value == meta.min) return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        'R\$ ${value.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 10,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: (finalSpots.length > 5) ? (finalSpots.length / 5).floorToDouble() : 1.0,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < finalSpots.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'Dia ${index + 1}',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 10,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: maxX,
                            minY: 0,
                            maxY: finalMaxY,
                            lineTouchData: LineTouchData(
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (touchedSpot) => const Color(0xFF0F172A),
                                tooltipBorder: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                                tooltipRoundedRadius: 8,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      'Dia ${spot.x.toInt() + 1}\nVal: R\$ ${spot.y.toStringAsFixed(2)}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        fontFamily: 'Inter',
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                                return spotIndexes.map((index) {
                                  return TouchedSpotIndicatorData(
                                    FlLine(
                                      color: const Color(0xFF64748B).withOpacity(0.5),
                                      strokeWidth: 1.5,
                                      dashArray: [4, 4],
                                    ),
                                    FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                        color: Colors.white,
                                        strokeColor: const Color(0xFF38BDF8),
                                        radius: 5,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: finalSpots,
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: const Color(0xFF38BDF8),
                                barWidth: 3.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF38BDF8).withOpacity(0.18),
                                      const Color(0xFF38BDF8).withOpacity(0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                        );
                      }(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF8FAFC),
            ),
          ),
        ],
      ),
    );
  }
}
