import 'package:hive/hive.dart';

// Manual Hive adapter to avoid build_runner conflicts with Riverpod/Test
class MealLog {
  final String id;
  final String label;
  final String imagePath;
  final int calories;
  final int protein;
  final DateTime date;
  final int carbohydrates;
  final int fat;
  final int fiber;

  MealLog({
    required this.id,
    required this.label,
    required this.imagePath,
    required this.calories,
    required this.protein,
    required this.date,
    this.carbohydrates = 0,
    this.fat = 0,
    this.fiber = 0,
  });
}

class MealLogAdapter extends TypeAdapter<MealLog> {
  @override
  final int typeId = 0;

  @override
  MealLog read(BinaryReader reader) {
    final id = reader.readString();
    final label = reader.readString();
    final imagePath = reader.readString();
    final calories = reader.readInt();
    final protein = reader.readInt();
    final date = DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    // Field baru — backward compat: data lama tidak punya field ini
    int carbohydrates = 0;
    int fat = 0;
    int fiber = 0;
    try {
      carbohydrates = reader.readInt();
      fat = reader.readInt();
      fiber = reader.readInt();
    } catch (_) {
      // Data lama, gunakan default 0
    }

    return MealLog(
      id: id,
      label: label,
      imagePath: imagePath,
      calories: calories,
      protein: protein,
      date: date,
      carbohydrates: carbohydrates,
      fat: fat,
      fiber: fiber,
    );
  }

  @override
  void write(BinaryWriter writer, MealLog obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.label);
    writer.writeString(obj.imagePath);
    writer.writeInt(obj.calories);
    writer.writeInt(obj.protein);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.carbohydrates);
    writer.writeInt(obj.fat);
    writer.writeInt(obj.fiber);
  }
}
