import 'dart:async';
import 'package:pedantic/pedantic.dart';
import 'package:sqlcool/sqlcool.dart';
import 'serializers.dart';
import 'schema.dart';

/// The key/value store
class KvStore {
  /// If an existing [Db] is provided it has to be initialized
  /// with the [kvSchema] before using. If no [Db] is provided
  /// the store wil use it's own database
  KvStore(
      {this.db,
      this.inMemory = false,
      this.path = "kvstore.db",
      this.verbose = false}) {
    if (db != null) {
      assert(db.schema != null);
      if (this.db.schema.table("kvstore") == null) {
        throw (ArgumentError("The kvstore table schema does not exist. " +
            "Please initialize your database with the kvSchema like this:\n" +
            'db.init(path: "dbname.db", schema: [kvSchema()])'));
      }
    }
    _init();
  }

  /// The Sqlcool [Db] to use
  Db db;

  /// The location of the db file, relative
  /// to the documents directory. Used if no database is provided
  final String path;

  /// Verbosity
  final bool verbose;

  /// Use an in memory copy of the store
  ///
  /// Required to use [selectSync]
  final bool inMemory;

  /// The ready callback
  Future get onReady => _readyCompleter.future;

  final Completer _readyCompleter = Completer<Null>();
  Db _db;
  final _changefeed = StreamController<List<dynamic>>.broadcast();
  Map<String, dynamic> _inMemoryStore;

  /// Dispose the store
  void dispose() {
    _changefeed.close();
  }

  /// Initialize the database
  Future<void> _init() async {
    /// [path] is the location of the database file, relative
    /// to the documents directory
    if (db == null) {
      _db = Db();
      db = _db;
      await _db.init(path: path, schema: [kvSchema()], verbose: verbose);
    } else {
      _db = db;
    }

    /// Initialize the in memory store if needed
    if (inMemory) {
      await _db.onReady;
      /*String query = "SELECT name FROM sqlite_master WHERE " +
          "type ='table' AND name NOT LIKE 'sqlite_%';";
      final t = await db.query(query);
      print("---- TABLES $t");*/
      _inMemoryStore = <String, dynamic>{};
      final List<Map<String, dynamic>> res = await _db.select(table: "kvstore");
      res.forEach((Map<String, dynamic> item) =>
          _inMemoryStore[item["key"].toString()] =
              decode(item["value"], item["type"].toString()));
    }

    /// Run the queue for the [push] method
    unawaited(_runQueue());
    _readyCompleter.complete();
  }

  /// Insert a key/value pair into the database
  ///
  /// Returns the id of the new inserted database row
  Future<int> insert<T>(String key, dynamic value) async {
    if (!(value is T)) {
      throw ArgumentError(
          "The value is of type ${value.runtimeType} and should be $T");
    }
    int id;
    if (inMemory == true) _inMemoryStore[key] = value;
    final List<String> res = encode(value);
    final String val = res[0] ?? "NULL";
    final String typeStr = res[1];
    try {
      final Map<String, String> row = <String, String>{
        "key": key,
        "value": val,
        "type": typeStr
      };
      id = await _db.insert(table: "kvstore", row: row, verbose: verbose);
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
  Future<bool> update<T>(String key, dynamic value) async {
    if (!(value is T)) {
      throw ArgumentError(
          "The value is of type ${value.runtimeType} and should be $T");
    }
    int updated = 0;
    try {
      if (inMemory == true) _inMemoryStore[key] = value;
      final List<String> res = encode(value);
      final String val = res[0] ?? "NULL";
      final String typeStr = res[1];
      final Map<String, String> row = <String, String>{
        "value": val,
        "type": typeStr
      };
      updated = await _db.update(
          table: "kvstore", where: 'key="$key"', row: row, verbose: verbose);
    } catch (e) {
      throw ("Can not update data $e");
    }
    bool ok = false;
    if (updated == 1) ok = true;
    return ok;
  }

  /// Get a value from a key
  Future<T> select<T>(String key) async {
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
        dynamic val = res[0]["value"];
        if (val.toString() == "NULL") val = null;
        final String type = res[0]["type"].toString();
        value = decode(val, type);
      } else {
        return null;
      }
    } catch (e) {
      throw ("Can not decode data from $res : $e");
    }
    if (!(value is T)) {
      throw ("Value is of type ${value.runtimeType} and should be $T");
    }
    return value as T;
  }

  /// Insert a key or update it if not present
  Future<void> upsert<T>(String key, dynamic value) async {
    try {
      if (!(value is T)) {
        throw (ArgumentError(
            "The value is of type ${value.runtimeType} and should be $T"));
      }
      if (inMemory == true) _inMemoryStore[key] = value;
      final List<String> res = encode(value);
      final String val = res[0] ?? "NULL";
      final String typeStr = res[1];
      final Map<String, String> row = <String, String>{
        "key": key,
        "value": val,
        "type": typeStr
      };
      await _db
          .upsert(table: "kvstore", row: row, verbose: verbose)
          .catchError((dynamic e) {
        throw ("Can not update store $e");
      });
    } catch (e) {
      throw ("Can not update data $e");
    }
  }

  /// Change the value of a key if it exists or insert it otherwise
  ///
  /// Limitation: this method runs asynchronously but can not be awaited.
  /// The queries are queued so this method can
  /// be safely called concurrently
  void push<T>(String key, dynamic value) {
    if (!(value is T)) {
      throw (ArgumentError(
          "The value is of type ${value.runtimeType} and should be $T"));
    }
    final List<dynamic> kv = <dynamic>[key, value];
    _changefeed.sink.add(kv);
    if (inMemory == true) _inMemoryStore[key] = value;
  }

  /// Synchronously get a value from the in memory store
  ///
  /// The [inMemory] option must be set to true when initilializing
  /// the store for this to work
  T selectSync<T>(String key) {
    if (!inMemory) {
      throw (ArgumentError("The [inMemory] parameter must be set " +
          "to true at database initialization to use select sync methods"));
    }
    dynamic value;
    try {
      if (_inMemoryStore.containsKey(key) == true) {
        value = _inMemoryStore[key];
        if (!(value is T)) {
          throw (ArgumentError("The selected value is of type " +
              "${value.runtimeType} and should be $T"));
        }
      } else {
        return null;
      }
    } catch (e) {
      throw ("Can not select data $e");
    }
    if (verbose) {
      print("# KVstore: select $key : $value");
    }
    if (value == null) {
      return null;
    }
    return value as T;
  }

  /// synchronously select a map
  Map<T, T2> selectMapSync<T, T2>(String key) => selectSync<Map<T, T2>>(key);

  /// synchronously select a list
  List<T> selectListSync<T>(String key) => selectSync<List<T>>(key);

  Future<void> _runQueue() async {
    await for (final item in _changefeed.stream) {
      final String k = item[0].toString();
      final dynamic v = item[1];
      unawaited(upsert<dynamic>(k, v));
    }
  }
}
