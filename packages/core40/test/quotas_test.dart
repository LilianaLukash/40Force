import 'package:core40/core40.dart';
import 'package:test/test.dart';

void main() {
  test('free and paid quota values match owner decisions', () {
    expect(PlanQuotas.free.customTargets, 3);
    expect(PlanQuotas.free.factorEvents, 8);
    expect(PlanQuotas.free.newCardsPerDay, 1);
    expect(PlanQuotas.free.historyDays, 90);
    expect(PlanQuotas.free.voiceCheckInsPerDay, 1);
    expect(PlanQuotas.free.companionRepliesPerDay, 5);
    expect(PlanQuotas.paid.customTargets, 30);
    expect(PlanQuotas.paid.factorEvents, 100);
    expect(PlanQuotas.paid.newCardsPerDay, isNull);
    expect(PlanQuotas.paid.historyDays, isNull);
    expect(PlanQuotas.paid.voiceCheckInsPerDay, 20);
    expect(PlanQuotas.paid.companionRepliesPerDay, 50);
  });

  test('custom target quota boundary', () {
    expect(canAddCustomTarget(PlanTier.free, 2), isTrue);
    expect(canAddCustomTarget(PlanTier.free, 3), isFalse);
    expect(canAddCustomTarget(PlanTier.paid, 29), isTrue);
    expect(canAddCustomTarget(PlanTier.paid, 30), isFalse);
  });

  test('factor quota boundary', () {
    expect(canAddFactor(PlanTier.free, 7), isTrue);
    expect(canAddFactor(PlanTier.free, 8), isFalse);
    expect(canAddFactor(PlanTier.paid, 99), isTrue);
    expect(canAddFactor(PlanTier.paid, 100), isFalse);
  });

  test('base targets never consume quota and trial caps exist', () {
    expect(baseTargetIds, containsAll(['cycle', 'physical_form', 'mental_form']));
    expect(voiceTrialDays, 14);
    expect(trialMaxVoiceCheckInsPerDay, 5);
    expect(trialMaxVoiceMinutesPerDay, 10);
    expect(trialMaxVoiceRecordMinutes, 3);
  });
}
