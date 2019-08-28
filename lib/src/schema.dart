import 'package:sqlcool/sqlcool.dart';

String _checkType(String field) {
  return '$field="int" OR $field="String" OR $field="double" OR $field="bool"' +
      ' OR $field="List" OR $field="Map" OR $field IS NULL';
}

/// Define the database schema
DbTable kvSchema({bool index = true}) {
  final DbTable table = DbTable("kvstore")
    ..varchar("key", unique: true)
    ..varchar("value", nullable: true)
    ..varchar("type", check: _checkType("type"))
    ..varchar("list_type", nullable: true)
    ..varchar("map_key_type", nullable: true)
    ..varchar("map_value_type", nullable: true)
    ..timestamp('updated');
  if (index) {
    table.index("key");
  }
  return table;
}
