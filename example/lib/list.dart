import 'package:flutter/material.dart';
import 'conf.dart';

class _SimpleListState extends State<SimpleList> {
  String value = "";
  bool inserted = false;

  Future<void> updateUi() async {
    final v = await store.selectList<int>("key55");
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
                    child: const Text("List"),
                    onPressed: () {
                      final val = <int>[1, 2, 3];
                      store
                          .put<List<int>>("key55", val)
                          .then((_) => updateUi());
                      inserted = true;
                    },
                  ),
                const Padding(padding: EdgeInsets.only(bottom: 10.0)),
                if (inserted == true)
                  RaisedButton(
                    child: const Text("Update key"),
                    onPressed: () {
                      final val = <int>[1, 2, 3, 4, 5];
                      store
                          .put<List<int>>("key55", val)
                          .then((_) => updateUi());
                    },
                  ),
                const Padding(padding: EdgeInsets.only(bottom: 10.0)),
                if (value != "")
                  RaisedButton(
                      child: const Text("Delete key"),
                      onPressed: () {
                        store.delete("key55").then((_) => updateUi());
                        inserted = false;
                      }),
                const Padding(padding: EdgeInsets.only(bottom: 10.0)),
                Text(value)
              ]),
        ));
  }
}

class SimpleList extends StatefulWidget {
  @override
  _SimpleListState createState() => _SimpleListState();
}
