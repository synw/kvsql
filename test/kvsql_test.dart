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

  test("insert string", () async {
    Future<int> insert() async {
      final res = await store.insert<String>("k", "v");
      return res;
    }

    await insert().then((int r) async {
      expect(r, 1);
      final insertedVal = await store.select<String>("k");
      expect(insertedVal is String, true);
      expect(insertedVal, "v");
    });
    return true;
  });
}
