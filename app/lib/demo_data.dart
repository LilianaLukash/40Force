import 'package:core40/core40.dart';

/// Twenty days of demo entries so graphs and the first full card
/// are visible immediately at a presentation.
List<DayData> buildDemoDays() {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day)
      .subtract(const Duration(days: 19));
  return List<DayData>.generate(20, (i) {
    final date = start.add(Duration(days: i));
    final coffee = i < 10;
    return DayData(
      date: date,
      targets: <String, double>{
        'sleep': coffee ? 0.25 : 0.85,
        'energy': coffee ? 0.40 : 0.75,
        'mood': 0.55 + (i % 4) * 0.08,
      },
      factors: coffee ? <String>{'coffee'} : <String>{},
    );
  });
}
