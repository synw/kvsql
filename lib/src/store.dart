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

  final Completer _readyCompleter = Completer<Null>();
  Db _db;
  final _pushFeed = StreamController<List<dynamic>>.broadcast();
  Map<String, dynamic> _inMemoryStore;

  /// The ready callback
  Future get onReady => _readyCompleter.future;

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
      _inMemoryStore = <String, dynamic>{};
      final List<Map<String, dynamic>> res = await _db.select(table: "kvstore");
      res.forEach((Map<String, dynamic> item) =>
          _inMemoryStore[item["key"].toString()] = decodeFromTypeStr<dynamic>(
              item["value"],
              item["type"].toString(),
              item["list_type"].toString(),
              item["map_key_type"].toString(),
              item["map_value_type"].toString()));
    }

    /// Run the queue for the [push] method
    unawaited(_runQueue());
    _readyCompleter.complete();
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

  /// Get a value from a key
  Future<T> select<T>(String key) async {
    return _select<T>(key);
  }

  Future<T> _select<T>(String key, {bool untyped = false}) async {
    if (!untyped) {
      if (T == dynamic) {
        throw (ArgumentError("Please provide a non dynamic type"));
      }
    }
    if (T is Map) {
      throw (ArgumentError("Please use selectMap<K, V> for maps data type"));
    } else if (T is List) {
      throw (ArgumentError("Please use selectList<T> for lists data type"));
    }
    final res = await _selectQuery(key);
    T value;
    try {
      if (res != null) {
        final dynamic val = res["value"];
        if (val.toString() == "NULL") {
          return null;
        }
        if (!untyped) {
          final typeStr = res["type"].toString();
          final listTypeStr = res["list_type"].toString();
          final mapKeyTypeStr = res["map_key_type"].toString();
          final mapValueTypeStr = res["map_value_type"].toString();
          value = decodeFromTypeStr<T>(
              val, typeStr, listTypeStr, mapKeyTypeStr, mapValueTypeStr);
        } else {
          value = val as T;
        }
      } else {
        return null;
      }
    } catch (e) {
      throw ("Can not decode data from $res : $e");
    }
    if (T != dynamic) {
      if (!(value is T)) {
        throw ("Value is of type ${value.runtimeType} and should be $T");
      }
    }
    return value;
  }

  Future<Map<String, dynamic>> _selectQuery(String key) async {
    Map<String, dynamic> res;
    try {
      final qres = await _db.select(
          table: "kvstore",
          columns: "key,value,type,list_type,map_key_type,map_value_type",
          where: 'key="$key"',
          verbose: verbose);
      if (qres.isEmpty) {
        return null;
      }
      res = qres[0];
    } catch (e) {
      throw ("Can not select data $e");
    }
    return res;
  }

  /// Insert a key or update it if not present
  Future<void> put<T>(String key, T value) async {
    await _upsert<T>(key, value);
  }

  Future<void> _upsert<T>(String key, T value, {bool untyped = false}) async {
    if (!untyped) {
      if (T == dynamic) {
        throw (ArgumentError("Please provide a non dynamic type"));
      }
    }
    if (!(value is T)) {
      throw (ArgumentError(
          "The value is of type ${value.runtimeType} and should be $T"));
    }
    try {
      if (inMemory == true) {
        _inMemoryStore[key] = value;
      }
      DatabaseEncodedRow encoded;
      try {
        encoded = encode<T>(value);
      } catch (e) {
        throw ("Encoding $value failed: $e");
      }
      final Map<String, String> row = <String, String>{
        "key": key,
        "value": encoded.value,
        "type": encoded.type,
        "list_type": encoded.listType,
        "map_key_type": encoded.mapKeyType,
        "map_value_type": encoded.mapValueType
      };
      await _db
          .upsert(table: "kvstore", row: row, verbose: verbose)
          .catchError((dynamic e) {
        throw ("Can not update store $e");
      });
    } catch (e) {
      throw ("Can not upsert data $e");
    }
  }

  /// Change the value of a key if it exists or insert it otherwise
  ///
  /// Limitation: this method runs asynchronously but can not be awaited.
  /// The queries are queued so this method can
  /// be safely called concurrently
  void push(String key, dynamic value) {
    final List<dynamic> kv = <dynamic>[key, value];
    _pushFeed.sink.add(kv);
    if (inMemory == true) {
      _inMemoryStore[key] = value;
    }
  }

  /// Count the keys in the store
  Future<int> count() async {
    int n = 0;
    try {
      n = await _db.count(table: "kvstore");
    } catch (e) {
      throw ("Can not count keys in the store $e");
    }
    return n;
  }

  /// Check if a key exists in the store
  Future<bool> hasKey(String key) async {
    var has = false;
    try {
      if (inMemory) {
        if (_inMemoryStore.containsKey(key)) {
          has = true;
        }
      } else {
        final n = await _db.count(table: "kvstore", where: 'key="$key"');
        if (n > 0) {
          has = true;
        }
      }
    } catch (e) {
      throw ("Can not check hasKey in the store $e");
    }
    return has;
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
    if (_inMemoryStore.containsKey(key)) {
      try {
        value = _inMemoryStore[key];
        if (value != null) {
          value = value as T;
        } else {
          return null;
        }
      } catch (e) {
        if (!(value is T)) {
          throw (ArgumentError("The selected value is of type " +
              "${value.runtimeType} and should be $T"));
        } else {
          rethrow;
        }
      }
    } else {
      return null;
    }
    if (verbose) {
      print("# KVstore: select $key : $value");
    }
    if (value == null) {
      return null;
    }
    return value as T;
  }

  Future<void> _runQueue() async {
    await for (final item in _pushFeed.stream) {
      final String k = item[0].toString();
      final dynamic v = item[1];
      unawaited(_upsert<dynamic>(k, v, untyped: true));
    }
  }

  /// Dispose the store
  void dispose() {
    _pushFeed.close();
    _db.database.close();
  }
}
