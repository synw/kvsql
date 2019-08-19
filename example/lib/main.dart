import 'package:flutter/material.dart';
import 'package:kvsql/kvsql.dart';
import 'conf.dart';
import 'map.dart';
import 'list.dart';
import 'push.dart';
import 'in_memory.dart';

final routes = {
  '/': (BuildContext context) => Home(),
  '/simple_list': (BuildContext context) => SimpleList(),
  '/simple_map': (BuildContext context) => SimpleMap(),
  '/push': (BuildContext context) => PushPage(),
  '/in_memory': (BuildContext context) => InMemoryPage(),
};

class _HomeState extends State<Home> {
  bool ready = false;

  @override
  void initState() {
    store = KvStore(verbose: true);
    store.onReady.then((dynamic _) => setState(() => ready = true));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    w = Scaffold(
        body: ready
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                    RaisedButton(
                        child: const Text("Simple list"),
                        onPressed: () =>
                            Navigator.of(context).pushNamed("/simple_list")),
                    const Padding(padding: EdgeInsets.only(bottom: 15.0)),
                    RaisedButton(
                        child: const Text("Simple map"),
                        onPressed: () =>
                            Navigator.of(context).pushNamed("/simple_map")),
                    const Padding(padding: EdgeInsets.only(bottom: 15.0)),
                    RaisedButton(
                        child: const Text("Push"),
                        onPressed: () =>
                            Navigator.of(context).pushNamed("/push")),
                    const Padding(padding: EdgeInsets.only(bottom: 15.0)),
                    RaisedButton(
                        child: const Text("In memory"),
                        onPressed: () =>
                            Navigator.of(context).pushNamed("/in_memory")),
                  ]))
            : w = const Center(child: CircularProgressIndicator()));
    return w;
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kvsql example',
      routes: routes,
    );
  }
}
