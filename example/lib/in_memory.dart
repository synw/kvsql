import 'package:flutter/material.dart';
import 'package:kvsql/kvsql.dart';

class _InMemoryPageState extends State<InMemoryPage> {
  KvStore store;
  bool ready = false;
  bool finished = false;

  @override
  void initState() {
    store = KvStore(inMemory: true, path: "inMemoryStore.db", verbose: true);
    store.onReady.then((dynamic _) {
      setState(() => ready = true);
      store.count().then((int numKeys) {
        if (numKeys > 0) {
          // prevent from resinserting already inserted data
          setState(() => finished = true);
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    store.dispose();
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
                      if (!finished)
                        RaisedButton(
                          child: const Text("Insert"),
                          onPressed: () async {
                            await store.put<String>("string_value", "Foo bar");
                            await store.put<int>("int_value", 3);
                            await store.put<double>("double_value", 5.5);
                            await store.put<List<String>>(
                                "list_value", ["one", "two", "three"]);
                            await store.put<Map<String, String>>("map_value",
                                <String, String>{"stringval": "Foo"});
                            print("Data inserted");
                            setState(() => finished = true);
                          },
                        ),
                      const Padding(padding: EdgeInsets.only(bottom: 10.0)),
                      Column(
                        children: <Widget>[
                          const Text("String value:"),
                          SelectValue(
                              store: store,
                              valueName: "string_value",
                              type: "string"),
                          const Text("Int value:"),
                          SelectValue(
                              store: store,
                              valueName: "int_value",
                              type: "integer"),
                          const Text("Double value:"),
                          SelectValue(
                              store: store,
                              valueName: "double_value",
                              type: "double"),
                          const Text("List value:"),
                          SelectValue(
                              store: store,
                              valueName: "list_value",
                              type: "list"),
                          const Text("Map value:"),
                          SelectValue(
                              store: store,
                              valueName: "map_value",
                              type: "map"),
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
  SelectValue(
      {@required this.valueName, @required this.store, @required this.type});
  final KvStore store;
  final String valueName;
  final String type;

  @override
  Widget build(BuildContext context) {
    dynamic value;
    switch (type) {
      case "string":
        value = store.selectSync<String>(valueName);
        break;
      case "integer":
        value = store.selectSync<int>(valueName);
        break;
      case "double":
        value = store.selectSync<double>(valueName);
        break;
      case "list":
        value = store.selectSync<List<String>>(valueName);
        break;
      case "map":
        value = store.selectSync<Map<String, String>>(valueName);
        break;
    }
    final dynamic valueType = value.runtimeType;
    return Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Text("$valueType: $value"));
  }
}
