# Kvsql

[![pub package](https://img.shields.io/pub/v/kvsql.svg)](https://pub.dartlang.org/packages/kvsql)
[![Build Status](https://travis-ci.org/synw/kvsql.svg?branch=master)](https://travis-ci.org/synw/kvsql)
[![Coverage Status](https://coveralls.io/repos/github/synw/kvsql/badge.svg?branch=master)](https://coveralls.io/github/synw/kvsql?branch=master)

A type safe key/value store for Flutter backed by Sqlite. Powered by [Sqlcool](https://github.com/synw/sqlcool).

## Usage

### Initialize

   ```dart
   import 'package:kvsql/kvsql.dart';

   store = KvStore();
   await store.onReady;
   ```

Initialize with an existing [Sqlcool database](https://github.com/synw/sqlcool):

   ```dart
   import 'package:kvsql/kvsql.dart';
   import 'package:sqlcool/sqlcool.dart';

   final db = Db();
   await db.init(path: "mydb.db", schema=[kvSchema()]);
   store = KvStore(db: db);
   ```

### Insert or update

   ```dart
   await store.put<String>("mykey", "myvalue");
   ```

Supported value types are: `String`, `int`, `double`, `bool`, `List<T>`, `Map<K, V>`

Allowed types for map keys are: `String`, `int` and `double`

Allowed types for lists and maps values are `String`, `int`, `bool`, `double` and `dynamic`

### Delete

   ```dart
   await store.delete("mykey");
   ```

### Select

Returns a typed value

   ```dart
   final List<int> myValue = await store.select<List<int>>("mykey");
   ```

### Select sync

Synchronously select a value.

   ```dart
   final Map<String, int> myValue = store.selectSync<Map<String, int>>("mykey");
   ```

For this to work you need to initialize the store with the `inMemory` option that keeps an in memory copy of the store values.

   ```dart
   store = KvStore(inMemory = true);
   ```

### Push

This method upserts a key/value using a queue: it can be safely
called concurrently. Useful for high throughput updates.

   ```dart
   store.push("mykey", "my_value");
   ```

**Limitations**:

- This method is executed asynchronously but can not be awaited
- It does not control the type of the data

*Note*: if you don't await your mutations or use `push` you are exposed to
eventual consistency

Check the examples for detailled usage.

## Persistant state

The kvstore can be used to persist the app state. Example with provider:

   ```dart
   import 'package:flutter/foundation.dart';
   import 'package:kvsql/kvsql.dart';

   final stateStore =
       KvStore(inMemory: true, path: "stateStore.db");

   class AppState with ChangeNotifier {
     int get value => stateStore.selectSync<int>("value");
     set value(int v) => stateStore.put<int>("value", v);

     void updateValue(int val) {
       value = val;
       notifyListeners();
     }
   }
   ```
