/// Aggregated data of one wake-day, used by statistics.
///
/// Target values are normalized to 0..1 (1 = best). A day counts as
/// "low" for a target when its value is at or below
/// [CardEngine]'s low threshold.
class DayData {
  final DateTime date;
  final Map<String, double> targets;
  final Set<String> factors;

  const DayData({
    required this.date,
    this.targets = const {},
    this.factors = const {},
  });
}

/// One honest co-occurrence card: a factor and a target that coincided
/// in time. Never a cause claim.
class InsightCard {
  final String factorId;
  final String targetId;
  final int lagDays;
  final int totalDays;
  final int factorDays;
  final double baseLowShare;
  final double factorLowShare;
  final bool early;

  const InsightCard({
    required this.factorId,
    required this.targetId,
    required this.lagDays,
    required this.totalDays,
    required this.factorDays,
    required this.baseLowShare,
    required this.factorLowShare,
    required this.early,
  });

  /// Signed shift of low-day share on factor days vs base level.
  double get delta => factorLowShare - baseLowShare;
}
