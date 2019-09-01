import 'package:flutter/material.dart';
import 'package:kvsql/kvsql.dart';
import 'package:provider/provider.dart';
import 'conf.dart';
import 'map.dart';
import 'list.dart';
import 'push.dart';
import 'in_memory.dart';
import 'state/store.dart';
import 'state/page.dart';

final routes = {
  '/': (BuildContext context) => Home(),
  '/simple_list': (BuildContext context) => SimpleList(),
  '/simple_map': (BuildContext context) => SimpleMap(),
  '/push': (BuildContext context) => PushPage(),
  '/in_memory': (BuildContext context) => InMemoryPage(),
  '/state': (BuildContext context) => StatePage(),
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
                    const Padding(padding: EdgeInsets.only(bottom: 15.0)),
                    RaisedButton(
                        child: const Text("Persistant state"),
                        onPressed: () =>
                            Navigator.of(context).pushNamed("/state")),
                  ]))
            : w = const Center(child: CircularProgressIndicator()));
    return w;
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

/// provider is for the state management example
void main() => runApp(ChangeNotifierProvider<AppState>(
      builder: (context) => AppState(),
      child: MyApp(),
    ));

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
