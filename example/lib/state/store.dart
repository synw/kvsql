import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:kvsql/kvsql.dart';

final stateStore =
    KvStore(inMemory: true, path: "stateStore.db", verbose: true);

class AppState with ChangeNotifier {
  int get value => stateStore.selectSync<int>("value");
  set value(int v) => stateStore.put<int>("value", v);

  final _rand = Random();

  void updateValue() {
    value = _rand.nextInt(100);
    notifyListeners();
  }
}
