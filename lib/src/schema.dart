import 'package:sqlcool/sqlcool.dart';

String _checkBaseType(String field) {
  return '$field="int" OR $field="String" OR $field="double"';
}

String _checkType(String field) {
  return '$field="int" OR $field="String" OR $field="double"' +
      ' OR $field="List" OR $field="Map"';
}

/// Define the database schema
DbTable kvSchema({bool index = true}) {
  final DbTable table = DbTable("kvstore")
    ..varchar("key", unique: true)
    ..varchar("value", nullable: true)
    ..varchar("type", check: _checkType("type"))
    ..varchar("list_type", check: _checkBaseType("list_type"))
    ..varchar("map_key_type", check: _checkBaseType("map_key_type"))
    ..varchar("map_value_type", check: _checkBaseType("map_value_type"))
    ..timestamp('updated');
  if (index) {
    table.index("key");
  }
  return table;
}
