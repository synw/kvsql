import 'package:flutter/material.dart';
import 'conf.dart';

class _SimpleMapState extends State<SimpleMap> {
  String value = "";
  bool inserted = false;

  Future<void> updateUi() async {
    final v = await store.select<Map<String, int>>("key37");
    setState(() {
      if (v == null) {
        value = "";
      } else
        value = "$v";
    });
    print("Key (${v.runtimeType}): $v");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Kvsql")),
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(padding: EdgeInsets.only(bottom: 10.0)),
                if (inserted == false)
                  RaisedButton(
                    child: const Text("Map"),
                    onPressed: () {
                      final val = <String, int>{"one": 1, "two": 2};
                      store
                          .put<Map<String, int>>("key37", val)
                          .then((_) => updateUi());
                      inserted = true;
                    },
                  ),
                const Padding(padding: EdgeInsets.only(bottom: 10.0)),
                if (inserted == true)
                  RaisedButton(
                    child: const Text("Update key"),
                    onPressed: () {
                      final val = <String, int>{"one": 10, "two": 20};
                      store
                          .put<Map<String, int>>("key37", val)
                          .then((_) => updateUi());
                    },
                  ),
                const Padding(padding: EdgeInsets.only(bottom: 10.0)),
                if (value != "")
                  RaisedButton(
                      child: const Text("Delete key"),
                      onPressed: () {
                        store.delete("key37").then((_) => updateUi());
                        inserted = false;
                      }),
                const Padding(padding: EdgeInsets.only(bottom: 10.0)),
                Text(value)
              ]),
        ));
  }
}

class SimpleMap extends StatefulWidget {
  @override
  _SimpleMapState createState() => _SimpleMapState();
}
