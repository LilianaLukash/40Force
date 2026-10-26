import 'package:core40/core40.dart';
import 'package:test/test.dart';

DayData day(int n, {double sleep = 0.8, Set<String> factors = const {}}) {
  return DayData(
    date: DateTime(2026, 1, n),
    targets: {'sleep': sleep},
    factors: factors,
  );
}

void main() {
  test('no early observations before 5 days', () {
    final days = [for (var i = 1; i <= 4; i++) day(i)];
    expect(CardEngine.earlyObservations(days, targetId: 'sleep'), isEmpty);
  });

  test('early observations appear on day 6 without full cards', () {
    final days = [
      for (var i = 1; i <= 6; i++)
        day(i, sleep: i.isOdd ? 0.2 : 0.9, factors: i.isOdd ? {'coffee'} : {}),
    ];
    final early = CardEngine.earlyObservations(days, targetId: 'sleep');
    expect(early, isNotEmpty);
    expect(early.first.factorId, 'coffee');
    expect(early.first.early, isTrue);
    expect(CardEngine.fullCards(days, targetId: 'sleep'), isEmpty);
  });

  test('full card finds same-day co-occurrence after 14 days', () {
    final days = [
      for (var i = 1; i <= 20; i++)
        day(i,
            sleep: i <= 10 ? 0.2 : 0.9,
            factors: i <= 10 ? {'coffee'} : {}),
    ];
    final cards = CardEngine.fullCards(days, targetId: 'sleep');
    final coffee = cards.where((c) => c.factorId == 'coffee' && c.lagDays == 0);
    expect(coffee, isNotEmpty);
    expect(coffee.first.factorDays, 10);
    expect(coffee.first.early, isFalse);
  });

  test('factor with too few days never becomes a full card', () {
    final days = [
      for (var i = 1; i <= 20; i++)
        day(i, sleep: 0.2, factors: i <= 2 ? {'rare_tea'} : {}),
    ];
    final cards = CardEngine.fullCards(days, targetId: 'sleep');
    expect(cards.where((c) => c.factorId == 'rare_tea'), isEmpty);
  });

  test('lag 1 card is detected', () {
    // Factor on day i -> low sleep on day i+1.
    final days = <DayData>[];
    for (var i = 1; i <= 20; i++) {
      final lowNext = i > 1 && (i - 1) <= 8;
      days.add(day(i,
          sleep: lowNext ? 0.2 : 0.9, factors: i <= 8 ? {'late_dinner'} : {}));
    }
    final cards = CardEngine.fullCards(days, targetId: 'sleep');
    expect(
      cards.any((c) => c.factorId == 'late_dinner' && c.lagDays == 1),
      isTrue,
    );
  });
}
