import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqlcool/sqlcool.dart';
import 'serializers.dart';
import 'schema.dart';

/// The key/value store
class KvStore {
  /// If an existing [Db] is provided it has to be initialized
  /// with the [kvSchema] before using. If no [Db] is provided
  /// the store wil use it's own database
  KvStore({this.db, this.inMemory = false, this.verbose = false}) {
    if (this.db != null) if (this.db.schema.table("kvstore") == null)
      throw (ArgumentError("The kvstore table schema does not exist. " +
          "Please initialize your database with the kvSchema like this:\n" +
          'db.init(path: "dbname.db", schema: [kvSchema()])'));
    _init();
  }

  /// The Sqlcool [Db] to use
  Db db;

  /// Verbosity
  bool verbose;

  /// Use an in memory copy of the store
  bool inMemory;

  /// The ready callback
  Future get onReady => _readyCompleter.future;

  final Completer _readyCompleter = Completer<Null>();
  Db _db;
  final _changefeed = StreamController<List<dynamic>>.broadcast();
  Map<String, Map<String, dynamic>> _inMemoryStore;

  /// Dispose the store
  void dispose() {
    _changefeed.close();
  }

  /// Initialize the database
  Future<void> _init() async {
    if (db == null) {
      _db = Db();
      final Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      final String dbPath = documentsDirectory.path + "/kvstore.db";
      _db.init(path: dbPath, schema: [kvSchema()], verbose: verbose);
    } else
      _db = db;
    // Initialize the in memory store if needed
    if (inMemory) {
      _inMemoryStore = <String, Map<String, dynamic>>{};
      final List<Map<String, dynamic>> res = await _db.select(table: "kvstore");
      res.forEach((Map<String, dynamic> item) =>
          _inMemoryStore[item["key"].toString()] = <String, dynamic>{
            "value": item["value"],
            "type": item["type"].toString()
          });
    }
    // Run the queue for the [push] method
    _runQueue();
    _readyCompleter.complete();
  }

  /// Insert a key/value pair into the database
  ///
  /// Returns the id of the new inserted database row
  Future<int> insert(String key, dynamic value) async {
    int id;
    final List<String> res = encode(value);
    final String val = res[0];
    final String typeStr = res[1];
    try {
      final Map<String, String> row = <String, String>{
        "key": key,
        "value": val,
        "type": typeStr
      };
      id = await _db.insert(table: "kvstore", row: row, verbose: verbose);
      if (inMemory == true)
        _inMemoryStore[key] = <String, dynamic>{"value": val, "type": typeStr};
    } catch (e) {
      throw ("Can not insert data $e");
    }
    return id;
  }

  /// Delete a key from the database
  ///
  /// Returns the number of deleted items
  Future<void> delete(String key) async {
    int deleted = 0;
    try {
      deleted = await _db.delete(
          table: "kvstore", where: 'key="$key"', verbose: verbose);
      if (inMemory == true) _inMemoryStore.remove(key);
    } catch (e) {
      throw ("Can not delete data $e");
    }
    return deleted;
  }

  /// Update a key to a new value
  ///
  /// Return true if the key has been updated
  Future<bool> update(String key, dynamic value) async {
    int updated = 0;
    try {
      final List<String> res = encode(value);
      final String val = res[0];
      final String typeStr = res[1];
      final Map<String, String> row = <String, String>{
        "value": val,
        "type": typeStr
      };
      updated = await _db.update(
          table: "kvstore", where: 'key="$key"', row: row, verbose: verbose);
      if (inMemory == true)
        _inMemoryStore[key] = <String, dynamic>{"value": val, "type": typeStr};
    } catch (e) {
      throw ("Can not update data $e");
    }
    bool ok = false;
    if (updated == 1) ok = true;
    return ok;
  }

  /// Get a value from a key
  Future<dynamic> select(String key) async {
    dynamic value;
    List<Map<String, dynamic>> res;
    try {
      res = await _db.select(
          table: "kvstore",
          columns: "key,value,type",
          where: 'key="$key"',
          verbose: verbose);
    } catch (e) {
      throw ("Can not select data $e");
    }
    try {
      if (res.isNotEmpty) {
        final dynamic val = res[0]["value"];
        final String type = res[0]["type"].toString();
        value = decode(val, type);
      }
    } catch (e) {
      throw ("Can not decode data from $res : $e");
    }
    return value;
  }

  /// Insert a key or update it if not present
  Future<void> upsert(String key, dynamic value) async {
    try {
      final List<String> res = encode(value);
      final String val = res[0];
      final String typeStr = res[1];
      final Map<String, String> row = <String, String>{
        "key": key,
        "value": val,
        "type": typeStr
      };
      _db.upsert(table: "kvstore", row: row, verbose: verbose);
      if (inMemory == true)
        _inMemoryStore[key] = <String, dynamic>{"value": val, "type": typeStr};
    } catch (e) {
      throw ("Can not update data $e");
    }
  }

  /// Change the value of a key if it exists or insert it otherwise
  ///
  /// Limitation: this method runs asynchronously but can not be awaited.
  /// The queries are queued so this method can
  /// be safely called concurrently
  void push(String key, dynamic value) {
    final List<dynamic> kv = <dynamic>[key, value];
    _changefeed.sink.add(kv);
    if (inMemory == true) {
      final List<String> res = encode(value);
      final String val = res[0];
      final String typeStr = res[1];
      _inMemoryStore[key] = <String, dynamic>{"value": val, "type": typeStr};
    }
  }

  /// Synchronously get a value from the in memory store
  dynamic selectSync(String key) {
    assert(inMemory == true);
    dynamic value;
    try {
      value = decode(
          _inMemoryStore[key]["value"], _inMemoryStore[key]["type"].toString());
    } catch (e) {
      throw ("Can not select data $e");
    }
    return value;
  }

  Future<void> _runQueue() async {
    await for (final item in _changefeed.stream) {
      final String k = item[0].toString();
      final dynamic v = item[1];
      upsert(k, v);
    }
  }
}
