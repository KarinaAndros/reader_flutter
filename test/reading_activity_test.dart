import 'package:flutter_app/features/home/data/reading_activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Activity counts unique opened pages per book per local day', () async {
    final repository = ReadingActivityRepository();
    final today = DateTime(2026, 11, 13, 23, 59);
    await repository.record('a', 1, now: today);
    await repository.record('a', 1, now: today);
    await repository.record('a', 2, now: today);
    await repository.record('b', 1, now: today);
    final restored = await ReadingActivityRepository().load();
    expect(restored.series(7, now: today).map((day) => day.pages), [
      0,
      0,
      0,
      0,
      0,
      0,
      3,
    ]);
    final tomorrow = DateTime(2026, 11, 14);
    final updated = await repository.record('a', 1, now: tomorrow);
    expect(updated.series(2, now: tomorrow).map((day) => day.pages), [3, 1]);
    expect(updated.hasOpened('a'), isTrue);
    expect(updated.hasOpened('unknown'), isFalse);
  });

  test('Concurrent page callbacks preserve every page and skip gaps', () async {
    final repository = ReadingActivityRepository();
    final today = DateTime(2026, 11, 13);
    await Future.wait([
      for (final page in [1, 2, 2, 100, 0, -1])
        repository.record('a', page, now: today),
    ]);
    final restored = await repository.load();
    expect(restored.series(1, now: today).single.pages, 3);
    expect(restored.days['2026-11-13']!['a'], {1, 2, 100});
  });

  test(
    'Activity fills missing days across month boundaries and drops old history',
    () {
      var activity = const ReadingActivity();
      activity = activity.record('a', 1, DateTime(2024, 1, 1));
      activity = activity.record('a', 2, DateTime(2026, 2, 28));
      activity = activity.record('a', 3, DateTime(2026, 3, 2));
      expect(activity.days.containsKey('2024-01-01'), isFalse);
      expect(
        activity.series(3, now: DateTime(2026, 3, 2)).map((day) => day.pages),
        [1, 0, 1],
      );
      expect(activity.series(28, now: DateTime(2026, 3, 2)).length, 28);
    },
  );

  test(
    'Corrupt or invalid stored activity does not prevent opening the app',
    () async {
      SharedPreferences.setMockInitialValues({
        ReadingActivityRepository.storageKey: '{bad',
      });
      expect((await ReadingActivityRepository().load()).days, isEmpty);
      final activity = ReadingActivity.fromJson({
        'bad-date': {
          'a': [1],
        },
        '2026-11-13': {
          'a': [1, 1, 2, 0, 'invalid'],
          'b': 'bad',
        },
      });
      expect(activity.series(1, now: DateTime(2026, 11, 13)).single.pages, 2);
    },
  );
}
