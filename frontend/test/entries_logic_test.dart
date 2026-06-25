import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_app/src/data/api_client.dart';
import 'package:time_app/src/data/local_store.dart';
import 'package:time_app/src/state/entries_notifier.dart';
import 'package:time_app/src/util/time_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<EntriesNotifier> makeNotifier() async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();
    // token getter returns null -> never tries to hit the network.
    return EntriesNotifier(store, ApiClient(), () => null);
  }

  group('time_utils', () {
    test('formatMinutes', () {
      expect(formatMinutes(0), '00:00');
      expect(formatMinutes(90), '01:30');
      expect(formatMinutes(1440), '24:00');
    });
    test('formatDuration', () {
      expect(formatDuration(0), '0m');
      expect(formatDuration(60), '1h');
      expect(formatDuration(90), '1h 30m');
      expect(formatDuration(45), '45m');
    });
    test('dayString/parseDay round-trip', () {
      final d = DateTime(2026, 6, 25);
      expect(dayString(d), '2026-06-25');
      expect(parseDay('2026-06-25'), d);
    });
  });

  group('EntriesNotifier', () {
    test('initializes today with a running Sleep focus from 00:00', () async {
      final n = await makeNotifier();
      final t = today();
      final running = n.runningEntry(t);
      expect(running, isNotNull);
      expect(running!.category, 'sleep');
      expect(running.startMin, 0);
      expect(n.currentFocus(t), 'sleep');
    });

    test('addManual + sumByCategory + totalMin', () async {
      final n = await makeNotifier();
      const day = '2026-01-10'; // a past day, no auto-sleep
      n.addManual(day, 'work', 9 * 60, 12 * 60); // 180
      n.addManual(day, 'leisure', 13 * 60, 14 * 60); // 60
      n.addManual(day, 'work', 14 * 60, 15 * 60); // 60 more work
      final sums = n.sumByCategory(day, 1440);
      expect(sums['work'], 240);
      expect(sums['leisure'], 60);
      expect(n.totalMin(day, 1440), 300);
      expect(n.forDay(day).length, 3);
    });

    test('updateEntry category keeps the existing end time', () async {
      final n = await makeNotifier();
      const day = '2026-01-10';
      n.addManual(day, 'work', 600, 660);
      final id = n.forDay(day).first.clientId;
      n.updateEntry(id, category: 'growth');
      final e = n.forDay(day).first;
      expect(e.category, 'growth');
      expect(e.endMin, 660); // not reopened
    });

    test('deleteEntry removes the entry', () async {
      final n = await makeNotifier();
      const day = '2026-01-10';
      n.addManual(day, 'work', 600, 660);
      final id = n.forDay(day).first.clientId;
      n.deleteEntry(id);
      expect(n.forDay(day), isEmpty);
    });

    test('handoff + moveHandoff adjusts the shared boundary', () async {
      final n = await makeNotifier();
      const day = '2026-01-10';
      n.addManual(day, 'work', 540, 600); // 9:00-10:00
      n.addManual(day, 'leisure', 600, 660); // 10:00-11:00, contiguous at 600
      final h = n.handoff(day, 'work', 'leisure', 720);
      expect(h, isNotNull);
      expect(h!.boundary, 600);
      n.moveHandoff(h.aId, h.bId, 630, push: false);
      final work = n.forDay(day).firstWhere((e) => e.category == 'work');
      final leisure = n.forDay(day).firstWhere((e) => e.category == 'leisure');
      expect(work.endMin, 630);
      expect(leisure.startMin, 630);
    });

    test('handoff returns null when not contiguous', () async {
      final n = await makeNotifier();
      const day = '2026-01-10';
      n.addManual(day, 'work', 540, 600);
      n.addManual(day, 'leisure', 620, 660); // gap 600..620
      expect(n.handoff(day, 'work', 'leisure', 720), isNull);
    });

    test('totalMin caps at 1440', () async {
      final n = await makeNotifier();
      const day = '2026-01-10';
      n.addManual(day, 'sleep', 0, 1440);
      n.addManual(day, 'work', 0, 600); // overlap
      expect(n.totalMin(day, 1440), 1440);
    });
  });
}
