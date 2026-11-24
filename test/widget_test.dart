import 'package:flutter_test/flutter_test.dart';
import 'package:green_life/data/care_db.dart';
import 'package:green_life/models/plant.dart';

void main() {
  test('Bakım veritabanı bilimsel adla eşleşir', () {
    expect(CareDb.match('Monstera deliciosa')!.waterDays, 8);
    expect(CareDb.match('Dracaena trifasciata')!.kind, PlantKind.snake);
    expect(CareDb.match('Opuntia ficus-indica', family: 'Cactaceae')!.trName, 'Kaktüs');
    expect(CareDb.match('Bilinmeyen bitki'), isNull);
  });

  test('Sulama günü hesaplanır', () {
    final p = Plant(
      id: '1',
      name: 'Test',
      scientific: 'x',
      room: '',
      kind: PlantKind.leafy,
      waterEveryDays: 7,
      lastWatered: DateTime.now().subtract(const Duration(days: 7)),
      addedAt: DateTime.now(),
      light: '',
      temperature: '',
      tip: '',
    );
    expect(p.needsWaterToday, isTrue);
    expect(p.waterLabel, 'Bugün sula');
  });
}
