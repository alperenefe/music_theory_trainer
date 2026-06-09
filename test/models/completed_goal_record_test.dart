import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/completed_goal_record.dart';
import 'package:music_theory_trainer/models/goal_completion_report.dart';
import 'package:music_theory_trainer/services/stats_summary.dart';

void main() {
  test('CompletedGoalRecord json roundtrip', () {
    const original = CompletedGoalRecord(
      kind: 'mcq',
      goalTitle: 'Çoktan seçmeli',
      target: 10,
      completedAtMillis: 1_700_000_000_000,
      total: 10,
      correct: 9,
      avgLatencyMs: 1200,
      bestStreak: 5,
      totalWrong: 1,
      medianLatencyMs: 1100,
      totalThinkingMs: 12000,
      midiStats: [
        MidiStat(midi: 60, total: 5, correct: 5, avgMs: 1000),
      ],
    );
    final decoded = CompletedGoalRecord.fromJson(original.toJson());
    expect(decoded.kind, original.kind);
    expect(decoded.goalTitle, original.goalTitle);
    expect(decoded.midiStats, hasLength(1));
    expect(decoded.midiStats.first.midi, 60);

    final report = decoded.toReport();
    expect(report.summary.total, 10);
    expect(report.summary.midiStats.first.correct, 5);
  });

  test('fromReport preserves summary', () {
    const report = GoalCompletionReport(
      goalTitle: 'Test',
      target: 3,
      summary: StatsSummary(
        total: 3,
        correct: 2,
        avgLatencyMs: 500,
        midiStats: [],
      ),
      bestStreak: 2,
      totalWrong: 1,
      medianLatencyMs: 450,
      totalThinkingMs: 1500,
    );
    final record = CompletedGoalRecord.fromReport(
      kind: 'mcq',
      report: report,
      completedAtMillis: 100,
    );
    expect(record.toReport().summary.correct, 2);
  });
}
