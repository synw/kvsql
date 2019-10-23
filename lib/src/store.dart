import 'dart:async';

import 'package:kvsql/exceptions.dart';
import 'package:pedantic/pedantic.dart';
import 'package:sqlcool/sqlcool.dart';

import 'schema.dart';
import 'serializers.dart';

/// The key/value store
class KvStore {
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

  final Completer _readyCompleter = Completer<void>();

  Db _db;
  final _pushFeed = StreamController<List<dynamic>>.broadcast();
  Map<String, dynamic> _inMemoryStore;

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
        throw ArgumentError("The kvstore table schema does not exist. "
            "Please initialize your database with the kvSchema like this:\n"
            'db.init(path: "dbname.db", schema: [kvSchema()])');
      }
    }
    _init();
  }

  /// The ready callback
  Future get onReady => _readyCompleter.future;

  /// Count all rows in the store
  Future<int> count() async {
    int n = 0;
    if (inMemory == true) {
      return _inMemoryStore.length;
    }
    try {
      n = await _db.count(table: "kvstore", verbose: verbose);
    } catch (e) {
      throw ReadQueryException("Can not count keys in the store $e");
    }
    return n;
  }

  /// Count keys ending with and expression
  Future<int> countKeysEndsWith(String expression) async {
    int n = 0;
    if (inMemory) {
      for (final k in _inMemoryStore.keys) {
        if (k.startsWith(expression)) {
          ++n;
        }
        return n;
      }
    }
    try {
      final where = "key LIKE $expression%";
      n = await _db.count(table: "kvstore", where: where, verbose: verbose);
    } catch (e) {
      throw ReadQueryException("Can not count keys in the store $e");
    }
    return n;
  }

  /// Count keys starting with and expression
  Future<int> countKeysStartsWith(String expression) async {
    int n = 0;
    if (inMemory) {
      for (final k in _inMemoryStore.keys) {
        if (k.startsWith(expression)) {
          ++n;
        }
        return n;
      }
    }
    try {
      final where = "key LIKE $expression%";
      n = await _db.count(table: "kvstore", where: where, verbose: verbose);
    } catch (e) {
      throw ReadQueryException("Can not count keys in the store $e");
    }
    return n;
  }

  /// Count rows in the store that match the [where] expression
  ///
  /// Where is an sql clause statement. ex of where: 'key LIKE %something' or
  /// 'type="integer"' or 'value > 2'. Available columns for this: key, value,
  /// type and updated (a timestamp)
  ///
  /// **Note**: this function uses sql and does not work in memory. A query is
  /// made each time to the database
  Future<int> countWhere(String where) async {
    int n = 0;
    try {
      n = await _db.count(table: "kvstore", where: where, verbose: verbose);
    } catch (e) {
      throw ReadQueryException("Can not count keys in the store $e");
    }
    return n;
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
      throw WriteQueryException("Can not delete data $e");
    }
    return deleted;
  }

  /// Dispose the store
  void dispose() {
    _pushFeed.close();
    _db.database.close();
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
      throw ReadQueryException("Can not check hasKey in the store $e");
    }
    return has;
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

  /// Insert a key or update it if not present
  Future<void> put<T>(String key, T value) async {
    await _upsert<T>(key, value);
  }

  /// Get a value from a key
  Future<T> select<T>(String key) async {
    return _select<T>(key);
  }

  /// Synchronously get a value from the in memory store
  ///
  /// The [inMemory] option must be set to true when initilializing
  /// the store for this to work
  T selectSync<T>(String key, {bool quiet = false}) {
    if (!inMemory) {
      throw ArgumentError("The [inMemory] parameter must be set "
          "to true at database initialization to use select sync methods");
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
          throw ArgumentError("The selected value is of type "
              "${value.runtimeType} and should be $T");
        } else {
          rethrow;
        }
      }
    } else {
      return null;
    }
    if (verbose && (!quiet)) {
      print("# KVstore: select $key : $value");
    }
    if (value == null) {
      return null;
    }
    return value as T;
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

  Future<void> _runQueue() async {
    await for (final item in _pushFeed.stream) {
      final String k = item[0].toString();
      final dynamic v = item[1];
      unawaited(_upsert<dynamic>(k, v, untyped: true));
    }
  }

  Future<T> _select<T>(String key, {bool untyped = false}) async {
    if (!untyped) {
      if (T == dynamic) {
        throw ArgumentError("Please provide a non dynamic type");
      }
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
      throw DecodingException("Can not decode data from $res : $e");
    }
    if (T != dynamic) {
      if (!(value is T)) {
        throw WrongWalueTypeException(
            "Value is of type ${value.runtimeType} and should be $T");
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
      throw ReadQueryException("Can not select data $e");
    }
    return res;
  }

  Future<void> _upsert<T>(String key, T value, {bool untyped = false}) async {
    if (!untyped) {
      if (T == dynamic) {
        throw ArgumentError("Please provide a non dynamic type");
      }
    }
    if (!(value is T)) {
      throw ArgumentError(
          "The value is of type ${value.runtimeType} and should be $T");
    }
    try {
      if (inMemory == true) {
        _inMemoryStore[key] = value;
      }
      DatabaseEncodedRow encoded;
      try {
        encoded = encode<T>(value);
      } catch (e) {
        throw EncodingException("Encoding $value failed: $e");
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
        throw WriteQueryException("Can not update store $e");
      });
    } catch (e) {
      throw WriteQueryException("Can not upsert data $e");
    }
  }
}
