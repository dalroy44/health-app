import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:myapp/src/shared/models/health_data.dart';
import 'package:myapp/src/shared/services/isar_service.dart';

class HealthService {
  final IsarService _isarService;
  final Health _health;

  HealthService(this._isarService, this._health);

  Future<void> syncHealthData() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.SLEEP_ASLEEP,
    ];
    final permissions = types.map((e) => HealthDataAccess.READ).toList();

    if (await _health.requestAuthorization(types, permissions: permissions)) {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final steps = await _health.getTotalStepsInInterval(yesterday, now);
      final heartRate = await _health.getHealthDataFromTypes(startTime: yesterday, endTime: now, types: [HealthDataType.HEART_RATE]);
      final calories = await _health.getHealthDataFromTypes(startTime: yesterday, endTime: now, types: [HealthDataType.ACTIVE_ENERGY_BURNED]);
      final sleep = await _health.getHealthDataFromTypes(startTime: yesterday, endTime: now, types: [HealthDataType.SLEEP_ASLEEP]);

      final healthData = HealthData(
        date: now,
        steps: steps,
        heartRate: heartRate.isNotEmpty ? (heartRate.first.value as NumericHealthValue).numericValue.toDouble() : null,
        calories: calories.isNotEmpty ? calories.fold(0.0, (sum, sample) => sum! + ((sample.value as NumericHealthValue?)?.numericValue.toDouble() ?? 0.0)) : null,
        sleep: sleep.isNotEmpty ? sleep.fold(0.0, (sum, sample) => sum! + ((sample.value as NumericHealthValue?)?.numericValue.toDouble() ?? 0.0)) : null,
      );

      await _isarService.saveHealthData(healthData);
    }
  }
}

final healthProvider = Provider((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return HealthService(isarService, Health());
});
