import 'package:flutter/material.dart';
import 'package:kvsql/kvsql.dart';

class _InMemoryPageState extends State<InMemoryPage> {
  KvStore store;
  bool ready = false;

  @override
  void initState() {
    store = KvStore(inMemory: true, path: "inMemoryStore.db", verbose: true);
    store.onReady.then((dynamic _) => setState(() => ready = true));
    super.initState();
  }

  @override
  void dispose() {
    store.db.database.close();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Kvsql")),
        body: Center(
          child: ready
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                      const Padding(padding: EdgeInsets.only(bottom: 10.0)),
                      RaisedButton(
                        child: const Text("Insert"),
                        onPressed: () async {
                          await store.insert("string_value", "Foo bar");
                          await store.insert("int_value", 3);
                          await store.insert("double_value", 5.5);
                          await store
                              .insert("list_value", ["one", "two", "three"]);
                          await store.insert("map_value", <String, dynamic>{
                            "stringval": "Foo",
                            "intval": 5
                          });
                          print("Data inserted");
                          setState(() {});
                        },
                      ),
                      const Padding(padding: EdgeInsets.only(bottom: 10.0)),
                      Column(
                        children: <Widget>[
                          const Text("String value:"),
                          SelectValue(store: store, valueName: "string_value"),
                          const Text("Int value:"),
                          SelectValue(store: store, valueName: "int_value"),
                          const Text("Double value:"),
                          SelectValue(store: store, valueName: "double_value"),
                          const Text("List value:"),
                          SelectValue(store: store, valueName: "list_value"),
                          const Text("Map value:"),
                          SelectValue(store: store, valueName: "map_value"),
                        ],
                      )
                    ])
              : const CircularProgressIndicator(),
        ));
  }
}

class InMemoryPage extends StatefulWidget {
  @override
  _InMemoryPageState createState() => _InMemoryPageState();
}

class SelectValue extends StatelessWidget {
  SelectValue({@required this.valueName, @required this.store});
  final KvStore store;
  final String valueName;

  @override
  Widget build(BuildContext context) {
    final dynamic value = store.selectSync(valueName);
    final dynamic valueType = value.runtimeType;
    return Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Text("$valueType: $value"));
  }
}
