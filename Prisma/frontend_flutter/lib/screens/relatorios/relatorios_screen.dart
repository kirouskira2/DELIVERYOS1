import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/reports_repository.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  final ReportsRepository _repository = ReportsRepository();
  bool _isLoading = true;
  List<dynamic> _topSellers = [];
  List<dynamic> _melhoresClientes = [];
  String _periodoSelecionado = 'Últimos 30 dias';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repository.getReportsData();
      if (mounted) {
        setState(() {
          _topSellers = res['top_sellers'] is List ? res['top_sellers'] : [];
          _melhoresClientes = res['melhores_clientes'] is List ? res['melhores_clientes'] : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _topSellers = [];
          _melhoresClientes = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportarPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Relatorio de Vendas - Delivery OS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Periodo: $_periodoSelecionado'),
              pw.SizedBox(height: 20),
              pw.Text('Pratos Mais Vendidos:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Prato', 'Quantidade'],
                  ..._topSellers.map((item) => [item['nome'].toString(), '${item['quantidade_pedida']}x']),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text('Melhores Clientes B2B (LTV):', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Empresa / Cliente', 'Total Investido'],
                  ..._melhoresClientes.map((item) => [item['nome'].toString(), 'R\$ ${(item['total_gasto'] as num).toStringAsFixed(2)}']),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Footer(
                trailing: pw.Text('Gerado em: ${DateTime.now().toString()}'),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'relatorio.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
      ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
      : RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF3B82F6),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Relatórios e Analytics', style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _periodoSelecionado,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          underline: const SizedBox(),
                          icon: const Icon(LucideIcons.calendar, color: Colors.white, size: 16),
                          items: ['Últimos 30 dias', 'Este Mês', 'Este Ano']
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (val) => setState(() => _periodoSelecionado = val!),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _exportarPdf,
                          icon: const Icon(LucideIcons.download, size: 16),
                          label: const Text('Exportar Relatório'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),
                
                // Gráfico Area de Desempenho Contínuo
                Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Desempenho de Vendas (Volume Financeiro)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              drawHorizontalLine: true,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: const Color(0xFF334155).withOpacity(0.4),
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
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Sem ${value.toInt()}',
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
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 1,
                            maxX: 4,
                            minY: 0,
                            maxY: 8000,
                            lineTouchData: LineTouchData(
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (touchedSpot) => const Color(0xFF0F172A),
                                tooltipBorder: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                                tooltipRoundedRadius: 8,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      'Semana ${spot.x.toInt()}\nVal: R\$ ${spot.y.toStringAsFixed(2)}',
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
                                spots: const [
                                  FlSpot(1, 3000),
                                  FlSpot(2, 4500),
                                  FlSpot(3, 3800),
                                  FlSpot(4, 6200),
                                ],
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
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Listas Rankeadas (Top Sellers & Melhores Clientes B2B)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(LucideIcons.flame, color: Colors.orangeAccent, size: 20),
                                SizedBox(width: 8),
                                Text('Pratos Mais Vendidos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._topSellers.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item['nome'], style: const TextStyle(color: Colors.white)),
                                      Text('${item['quantidade_pedida']}x', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(LucideIcons.briefcase, color: Colors.blueAccent, size: 20),
                                SizedBox(width: 8),
                                Text('Melhores Clientes B2B (LTV)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._melhoresClientes.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _InfoRow(
                                    label: item['nome'], 
                                    valor: 'R\$ ${(item['total_gasto'] as num).toStringAsFixed(2)}'
                                  ),
                                )).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;
  const _InfoRow({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Text(valor, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
      ],
    );
  }
}
