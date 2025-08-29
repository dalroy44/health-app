
import 'package:isar/isar.dart';

part 'health_data.g.dart';

@collection
class HealthData {
  Id id = Isar.autoIncrement;

  DateTime date;
  int? steps;
  double? heartRate;
  double? calories;
  double? sleep;

  HealthData({
    required this.date,
    this.steps,
    this.heartRate,
    this.calories,
    this.sleep,
  });
}
