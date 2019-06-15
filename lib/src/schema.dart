import 'package:sqlcool/sqlcool.dart';

/// Define the database schema
DbTable kvSchema() {
  final DbTable table = DbTable("kvstore")
    ..varchar("key", unique: true)
    ..varchar("value", nullable: true)
    ..varchar("type",
        check: 'type="integer" OR type="string" OR type="double"' +
            ' OR type="list" OR type="map" OR type="unknown"')
    ..timestamp('updated')
    ..index("key");
  return table;
}
