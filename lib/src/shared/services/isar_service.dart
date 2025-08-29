import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myapp/src/shared/models/health_data.dart';
import 'package:myapp/src/shared/models/medication.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [HealthDataSchema, MedicationSchema],
        directory: dir.path,
      );
    }
    return Future.value(Isar.getInstance());
  }

  Future<void> saveHealthData(HealthData healthData) async {
    final isar = await db;
    isar.writeTxnSync(() => isar.healthDatas.putSync(healthData));
  }

  Future<List<HealthData>> getHealthData() async {
    final isar = await db;
    return await isar.healthDatas.where().findAll();
  }

  Future<void> saveMedication(Medication medication) async {
    final isar = await db;
    isar.writeTxnSync(() => isar.medications.putSync(medication));
  }

  Future<List<Medication>> getMedications() async {
    final isar = await db;
    return await isar.medications.where().findAll();
  }

  Future<void> deleteMedication(int id) async {
    final isar = await db;
    isar.writeTxnSync(() => isar.medications.deleteSync(id));
  }
}

final isarServiceProvider = Provider((ref) => IsarService());
