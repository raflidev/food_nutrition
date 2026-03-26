import 'package:hive/hive.dart';

// Manual Hive adapter to avoid build_runner conflicts with Riverpod/Test
class MealLog {
  final String id;
  final String label;
  final String imagePath;
  final int calories;
  final int protein;
  final DateTime date;

  MealLog({
    required this.id,
    required this.label,
    required this.imagePath,
    required this.calories,
    required this.protein,
    required this.date,
  });
}

class MealLogAdapter extends TypeAdapter<MealLog> {
  @override
  final int typeId = 0;

  @override
  MealLog read(BinaryReader reader) {
    return MealLog(
      id: reader.readString(),
      label: reader.readString(),
      imagePath: reader.readString(),
      calories: reader.readInt(),
      protein: reader.readInt(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
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
  }
}
