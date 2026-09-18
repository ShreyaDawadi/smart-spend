import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'main.dart';

class InsightsScreen extends StatelessWidget {
  final List<Transaction> transactions;

  const InsightsScreen({super.key, required this.transactions});

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};
    for (final t in transactions.where((t) => t.amount < 0)) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount.abs();
    }
    return totals;
  }

  double get _totalIncome =>
      transactions.where((t) => t.amount > 0).fold(0, (sum, t) => sum + t.amount);

  double get _totalExpense =>
      transactions.where((t) => t.amount < 0).fold(0, (sum, t) => sum + t.amount.abs());

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _categoryTotals;
    final totalExpense = _totalExpense;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: const Color(0xFFF7F7FB),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: transactions.isEmpty
          ? const Center(child: Text('Add some transactions to see insights.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Income vs Expense bar comparison
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Income vs Expense',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: [_totalIncome, totalExpense]
                                      .reduce((a, b) => a > b ? a : b) *
                                  1.2,
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final label = value == 0 ? 'Income' : 'Expense';
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(label),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [
                                  BarChartRodData(
                                    toY: _totalIncome,
                                    color: const Color(0xFF00B894),
                                    width: 40,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ]),
                                BarChartGroupData(x: 1, barRods: [
                                  BarChartRodData(
                                    toY: totalExpense,
                                    color: const Color(0xFFE74C3C),
                                    width: 40,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Spending by category pie chart
                  if (categoryTotals.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Spending by Category',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                sections: categoryTotals.entries.map((entry) {
                                  final style = styleFor(entry.key);
                                  final percentage =
                                      (entry.value / totalExpense * 100).toStringAsFixed(0);
                                  return PieChartSectionData(
                                    value: entry.value,
                                    title: '$percentage%',
                                    color: style.color,
                                    radius: 70,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: categoryTotals.entries.map((entry) {
                              final style = styleFor(entry.key);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: style.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${entry.key}: Rs ${entry.value.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              );
                            }).toList(),
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