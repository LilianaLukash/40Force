/// Plan quotas (owner decisions, research log 2026-10-26).
/// Base targets are always available and never consume the quota.
enum PlanTier { free, paid }

const Set<String> baseTargetIds = {'cycle', 'physical_form', 'mental_form'};

class PlanQuotas {
  final int customTargets;
  final int factorEvents;
  final int? newCardsPerDay;
  final int? historyDays;
  final int voiceCheckInsPerDay;
  final int companionRepliesPerDay;

  const PlanQuotas({
    required this.customTargets,
    required this.factorEvents,
    required this.newCardsPerDay,
    required this.historyDays,
    required this.voiceCheckInsPerDay,
    required this.companionRepliesPerDay,
  });

  static const free = PlanQuotas(
    customTargets: 3,
    factorEvents: 8,
    newCardsPerDay: 1,
    historyDays: 90,
    voiceCheckInsPerDay: 1,
    companionRepliesPerDay: 5,
  );

  static const paid = PlanQuotas(
    customTargets: 30,
    factorEvents: 100,
    newCardsPerDay: null,
    historyDays: null,
    voiceCheckInsPerDay: 20,
    companionRepliesPerDay: 50,
  );

  static PlanQuotas of(PlanTier tier) =>
      tier == PlanTier.free ? free : paid;
}

/// Voice trial: fully free for [voiceTrialDays] days after install,
/// with anti-abuse caps below.
const int voiceTrialDays = 14;
const int trialMaxVoiceCheckInsPerDay = 5;
const int trialMaxVoiceMinutesPerDay = 10;
const int trialMaxVoiceRecordMinutes = 3;

bool canAddCustomTarget(PlanTier tier, int currentCustomTargets) =>
    currentCustomTargets < PlanQuotas.of(tier).customTargets;

bool canAddFactor(PlanTier tier, int currentFactors) =>
    currentFactors < PlanQuotas.of(tier).factorEvents;
