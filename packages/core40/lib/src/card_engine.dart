import 'day_model.dart';
import 'entities.dart';

/// Honest co-occurrence statistics.
///
/// - Early observations: from [earlyMinDays] days, descriptive only.
/// - Full cards: from [fullMinDays] days, lags [lags], ranked by shift
///   vs base level; weak shifts below [minDelta] are hidden as noise.
/// A card never claims a cause.
class CardEngine {
  static const int earlyMinDays = 5;
  static const int fullMinDays = 14;
  static const int minFactorDays = 5;
  static const int earlyMinFactorDays = 2;
  static const double lowThreshold = 0.4;
  static const double minDelta = 0.15;
  static const List<int> lags = [0, 1, 2, 3];

  static bool _isLow(DayData day, String targetId) {
    final value = day.targets[targetId];
    return value != null && value <= lowThreshold;
  }

  static bool _hasTarget(DayData day, String targetId) =>
      day.targets.containsKey(targetId);

  static Set<String> _allFactors(List<DayData> days) =>
      days.expand((d) => d.factors).toSet();

  /// Descriptive early observations (no lags). Empty before day 5.
  static List<InsightCard> earlyObservations(
    List<DayData> days, {
    required String targetId,
  }) {
    if (days.length < earlyMinDays) return const [];
    final withTarget = days.where((d) => _hasTarget(d, targetId)).toList();
    if (withTarget.isEmpty) return const [];
    final baseLow =
        withTarget.where((d) => _isLow(d, targetId)).length / withTarget.length;
    final cards = <InsightCard>[];
    for (final factor in _allFactors(days)) {
      final factorDays =
          withTarget.where((d) => d.factors.contains(factor)).toList();
      if (factorDays.length < earlyMinFactorDays) continue;
      final lowShare =
          factorDays.where((d) => _isLow(d, targetId)).length /
              factorDays.length;
      cards.add(InsightCard(
        factorId: factor,
        targetId: targetId,
        lagDays: 0,
        totalDays: withTarget.length,
        factorDays: factorDays.length,
        baseLowShare: baseLow,
        factorLowShare: lowShare,
        early: true,
      ));
    }
    cards.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    return cards;
  }

  /// Full cards with lags 0-3. Empty before day 14.
  static List<InsightCard> fullCards(
    List<DayData> days, {
    required String targetId,
  }) {
    if (days.length < fullMinDays) return const [];
    final withTarget = days.where((d) => _hasTarget(d, targetId)).toList();
    if (withTarget.isEmpty) return const [];
    final baseLow =
        withTarget.where((d) => _isLow(d, targetId)).length / withTarget.length;
    final byDay = <DateTime, DayData>{
      for (final d in days) dayKeyForWake(d.date): d,
    };
    final cards = <InsightCard>[];
    for (final factor in _allFactors(days)) {
      for (final lag in lags) {
        var pairs = 0;
        var low = 0;
        for (final d in days) {
          if (!d.factors.contains(factor)) continue;
          final targetDay = byDay[DateTime(
            d.date.year,
            d.date.month,
            d.date.day + lag,
          )];
          if (targetDay == null || !_hasTarget(targetDay, targetId)) continue;
          pairs++;
          if (_isLow(targetDay, targetId)) low++;
        }
        if (pairs < minFactorDays) continue;
        final share = low / pairs;
        if ((share - baseLow).abs() < minDelta) continue;
        cards.add(InsightCard(
          factorId: factor,
          targetId: targetId,
          lagDays: lag,
          totalDays: withTarget.length,
          factorDays: pairs,
          baseLowShare: baseLow,
          factorLowShare: share,
          early: false,
        ));
      }
    }
    cards.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    return cards;
  }
}
