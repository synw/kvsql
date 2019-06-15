import 'package:flutter/material.dart';
import 'package:kvsql/kvsql.dart';
import 'conf.dart';
import 'simple.dart';
import 'push.dart';

final routes = {
  '/': (BuildContext context) => Home(),
  '/simple': (BuildContext context) => Simple(),
  '/push': (BuildContext context) => PushPage(),
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
                        child: const Text("Simple"),
                        onPressed: () =>
                            Navigator.of(context).pushNamed("/simple")),
                    const Padding(padding: EdgeInsets.only(bottom: 15.0)),
                    RaisedButton(
                        child: const Text("Push"),
                        onPressed: () =>
                            Navigator.of(context).pushNamed("/push")),
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
