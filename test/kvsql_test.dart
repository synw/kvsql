import 'package:flutter_test/flutter_test.dart';
import 'package:pedantic/pedantic.dart';
import 'package:sqlcool/sqlcool.dart';
import 'package:kvsql/kvsql.dart';
import 'base.dart';

void main() async {
  await setup();

  final db = Db();
  KvStore store;

  tearDown(() {
    log.clear();
  });

  test("Init kvstore", () async {
    await db.init(
        path: "testdb.sqlite",
        absolutePath: true,
        schema: [kvSchema()],
        verbose: true);
    expect(db.isReady, true);
    store = KvStore(db: db, verbose: true);
    unawaited(store.onReady.whenComplete(() => print("Store is ready")));
    await store.onReady;
    return true;
  });

  group("insert", () {
    test("insert string", () async {
      await store.insert<String>("k", "v").then((int r) async {
        expect(r, 1);
        final insertedVal = await store.select<String>("k");
        expect(insertedVal is String, true);
        expect(insertedVal, "v");
      });
      return true;
    });

    test("insert int", () async {
      await store.insert<int>("k_int", 1).then((int r) async {
        expect(r, 1);
        final insertedVal = await store.select<int>("k_int");
        expect(insertedVal is int, true);
        expect(insertedVal, 1);
      });
      return true;
    });

    test("insert double", () async {
      await store.insert<double>("k_double", 1.0).then((int r) async {
        expect(r, 1);
        final insertedVal = await store.select<double>("k_double");
        expect(insertedVal is double, true);
        expect(insertedVal, 1.0);
      });
      return true;
    });
  });

  test("insert list", () async {
    await store.insert<List<int>>("k_list", [1, 2, 3]).then((int r) async {
      expect(r, 1);
      final insertedVal = await store.selectList<int>("k_list");
      expect(insertedVal is List<int>, true);
      expect(insertedVal, [1, 2, 3]);
    });
    return true;
  });

  test("insert map", () async {
    await store.insert<Map<String, int>>(
        "k_map", <String, int>{"1": 1, "2": 2}).then((int r) async {
      expect(r, 1);
      final insertedVal = await store.selectMap<String, int>("k_map");
      expect(insertedVal is Map<String, int>, true);
      expect(insertedVal, <String, int>{"1": 1, "2": 2});
    });
    return true;
  });
}
