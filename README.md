# Kvsql

A key/value store for Flutter backed by Sqlite. Powered by [Sqlcool](https://github.com/synw/sqlcool).

## Usage

### Initialize

   ```dart
   import 'package:kvsql/kvsql.dart';

   store = KvStore();
   await store.onReady;
   ```

Initialize with an existing [Sqlcool database](https://github.com/synw/sqlcool):

   ```dart
   db.init(path: "mydb.db", schema=[kvSchema()]);
   store = KvStore(db: db);
   ```

## Insert

   ```dart
   await store.insert("mykey", "myvalue");
   ```

Supported value types are: `String`, `int`, `double`, `List`, `Map`

## Update

   ```dart
   await store.update("mykey", "my_new_value");
   ```

## Delete

   ```dart
   await store.delete("mykey");
   ```

## Select

Returns a typed value

   ```dart
   final dynamic myValue = await store.select("mykey");
   ```

## Upsert

Inserts a value if it does not exists or update it otherwise

   ```dart
    await store.upsert("mykey", "my_new_value");
   ```

## Push

This method upserts a key/value using a queue: it can be safely
called concurrently. Useful for high throughput updates.

Limitation: this method is executed asynchronously but can not be awaited.

   ```dart
    store.push("mykey", "my_value");
   ```

Check the examples for detailled usage.

## Select sync

Synchronously select a value.

   ```dart
   final dynamic myValue = store.selectSync("mykey");
   ```

For this to work you need to initialize the store with the `inMemory` option that keeps an in memory copy of the store values.

   ```dart
   store = KvStore(inMemory = true);
   ```

Note: if you don't await your mutations or use `push` you are exposed to
eventual consistency using this method

Typed values select sync are available:

   ```dart
   final double myValue = store.selectDoubleSync("mykey");
   final int myValue = store.selectIntegerSync("mykey");
   final String myValue = store.selectStringSync("mykey");
   final List myValue = store.selectListSync("mykey");
   final Map myValue = store.selectMapSync("mykey");
   ```
