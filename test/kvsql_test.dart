import 'package:flutter_test/flutter_test.dart';
import 'package:pedantic/pedantic.dart';
import 'package:sqlcool/sqlcool.dart';
import 'package:kvsql/kvsql.dart';
import 'base.dart';

Future<void> main() async {
  await setup();

  final db = Db();
  final db2 = Db();
  KvStore store;
  KvStore memStore;

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
    unawaited(
        store.onReady.whenComplete(() => print("In memory store is ready")));
    await store.onReady;
    return true;
  });

  group("Base", () {
    test("put string", () async {
      await store.put<String>("k", "v").then((_) async {
        final insertedVal = await store.select<String>("k");
        expect(insertedVal is String, true);
        expect(insertedVal, "v");
      });
      return true;
    });

    test("put int", () async {
      await store.put<int>("k_int", 1).then((_) async {
        final insertedVal = await store.select<int>("k_int");
        expect(insertedVal is int, true);
        expect(insertedVal, 1);
      });
      return true;
    });

    test("put double", () async {
      await store.put<double>("k_double", 1.0).then((_) async {
        final insertedVal = await store.select<double>("k_double");
        expect(insertedVal is double, true);
        expect(insertedVal, 1.0);
      });
      return true;
    });

    test("put list", () async {
      await store.put<List<int>>("k_list", [1, 2, 3]).then((_) async {
        final insertedVal = await store.select<List<int>>("k_list");
        expect(insertedVal is List<int>, true);
        expect(insertedVal, [1, 2, 3]);
      });
      return true;
    });

    test("put map", () async {
      await store.put<Map<String, int>>(
          "k_map", <String, int>{"1": 1, "2": 2}).then((_) async {
        final insertedVal = await store.select<Map<String, int>>("k_map");
        expect(insertedVal is Map<String, int>, true);
        expect(insertedVal, <String, int>{"1": 1, "2": 2});
      });
      return true;
    });

    test("put dynamic", () async {
      try {
        await store.put<dynamic>("k_int", 1);
      } on ArgumentError catch (e) {
        expect(e.message, "Please provide a non dynamic type");
        return true;
      }
      throw ("Argument error exception expected");
    });
  });

  group("in memory", () {
    test("Init in memory kvstore", () async {
      await db2.init(
          path: "testdb2.sqlite",
          absolutePath: true,
          schema: [kvSchema()],
          verbose: true);
      expect(db2.isReady, true);
      memStore = KvStore(db: db2, inMemory: true, verbose: true);
      unawaited(memStore.onReady.whenComplete(() => print("Store is ready")));
      await memStore.onReady;
      return true;
    });

    test("select string sync", () async {
      await memStore.put<String>("k", "v").then((_) async {
        final insertedVal = memStore.selectSync<String>("k");
        expect(insertedVal is String, true);
        expect(insertedVal, "v");
      });
      return true;
    });

    test("select int sync", () async {
      await memStore.put<int>("k_int", 1).then((_) async {
        final insertedVal = memStore.selectSync<int>("k_int");
        expect(insertedVal is int, true);
        expect(insertedVal, 1);
      });
      return true;
    });

    test("select double sync", () async {
      await memStore.put<double>("k_double", 1.0).then((_) async {
        final insertedVal = memStore.selectSync<double>("k_double");
        expect(insertedVal is double, true);
        expect(insertedVal, 1.0);
      });
      return true;
    });

    test("select list sync", () async {
      await memStore.put<List<int>>("k_list", [1, 2, 3]).then((_) async {
        final insertedVal = memStore.selectSync<List<int>>("k_list");
        expect(insertedVal is List<int>, true);
        expect(insertedVal, [1, 2, 3]);
      });
      return true;
    });

    test("select map sync", () async {
      await memStore.put<Map<String, int>>(
          "k_map", <String, int>{"1": 1, "2": 2}).then((_) async {
        final insertedVal = memStore.selectSync<Map<String, int>>("k_map");
        expect(insertedVal is Map<String, int>, true);
        expect(insertedVal, <String, int>{"1": 1, "2": 2});
      });
      return true;
    });
  });
}
