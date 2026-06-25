import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_app/src/data/local_store.dart';
import 'package:time_app/src/state/categories_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<CategoriesNotifier> make() async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();
    return CategoriesNotifier(store, (_) async {});
  }

  test('defaults to the nine native categories, all enabled', () async {
    final c = await make();
    expect(c.all.length, 9);
    expect(c.enabled.length, 9);
    expect(c.all.every((x) => x.native), true);
  });

  test('disabling a native category hides it from enabled but keeps it', () async {
    final c = await make();
    c.update('work', enabled: false);
    expect(c.enabled.any((x) => x.key == 'work'), false);
    expect(c.all.any((x) => x.key == 'work'), true); // still present
  });

  test('rename + recolor a native category', () async {
    final c = await make();
    c.update('work', label: 'Job', color: 0xFF112233);
    final def = c.resolve('work');
    expect(def.label, 'Job');
    expect(def.color.toARGB32(), 0xFF112233);
  });

  test('add and remove a custom category', () async {
    final c = await make();
    final def = c.addCustom('Yoga', 0xFF445566);
    expect(c.all.length, 10);
    expect(def.native, false);
    c.remove(def.key);
    expect(c.all.length, 9);
  });

  test('native categories cannot be removed', () async {
    final c = await make();
    c.remove('work');
    expect(c.all.any((x) => x.key == 'work'), true);
  });

  test('resolve falls back for unknown keys', () async {
    final c = await make();
    final def = c.resolve('custom_gone');
    expect(def.key, 'custom_gone');
    expect(def.enabled, false);
  });
}
