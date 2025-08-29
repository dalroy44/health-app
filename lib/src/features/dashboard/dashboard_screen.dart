import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myapp/src/shared/models/health_data.dart';
import 'package:myapp/src/shared/models/medication.dart';
import 'package:myapp/src/shared/services/health_service.dart';
import 'package:myapp/src/shared/services/isar_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthData = ref.watch(healthDataProvider);
    final medications = ref.watch(medicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHealthCharts(healthData),
            _buildMedicationList(medications, ref),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/medication'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHealthCharts(AsyncValue<List<HealthData>> healthData) {
    return healthData.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('No health data yet.'));
        }
        return Column(
          children: [
            _buildChart('Steps', data.map((d) => FlSpot(d.date.millisecondsSinceEpoch.toDouble(), d.steps?.toDouble() ?? 0)).toList()),
            _buildChart('Heart Rate', data.map((d) => FlSpot(d.date.millisecondsSinceEpoch.toDouble(), d.heartRate ?? 0)).toList()),
            _buildChart('Calories', data.map((d) => FlSpot(d.date.millisecondsSinceEpoch.toDouble(), d.calories ?? 0)).toList()),
            _buildChart('Sleep', data.map((d) => FlSpot(d.date.millisecondsSinceEpoch.toDouble(), d.sleep ?? 0)).toList()),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildChart(String title, List<FlSpot> spots) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [LineChartBarData(spots: spots)],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text(DateFormat.MMMd().format(date));
                        },
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

  Widget _buildMedicationList(AsyncValue<List<Medication>> medications, WidgetRef ref) {
    return medications.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('No medications added yet.'));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final medication = data[index];
            return ListTile(
              title: Text(medication.name),
              subtitle: Text('${medication.dosage}, ${medication.frequency}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  ref.read(isarServiceProvider).deleteMedication(medication.id);
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

final healthDataProvider = FutureProvider<List<HealthData>>((ref) async {
  final healthService = ref.watch(healthProvider);
  await healthService.syncHealthData();
  return ref.watch(isarServiceProvider).getHealthData();
});

final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  return ref.watch(isarServiceProvider).getMedications();
});
