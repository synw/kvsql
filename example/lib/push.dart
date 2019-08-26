import 'package:flutter/material.dart';
import 'conf.dart';

class _PushPageState extends State<PushPage> {
  int maxSquares = 240;
  int currentSquares = 0;
  bool ready = false;
  bool running = false;

  @override
  void initState() {
    getInitialData().then((int s) => setState(() {
          currentSquares = s;
          ready = true;
        }));
    super.initState();
  }

  Future<int> getInitialData() async {
    int n = await store.select<int>("squares");
    n ??= 0;
    print("Value $n");
    return n;
  }

  Future<void> buildSquares() async {
    // draw
    while (currentSquares != maxSquares) {
      if (!running) return;
      await Future<dynamic>.delayed(Duration(milliseconds: 50));
      store.push("squares", currentSquares);
      setState(() => currentSquares++);
    }
    // reset if full
    if (currentSquares == maxSquares) {
      setState(() => currentSquares = 0);
      store.push("squares", 0);
      buildSquares();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Squares")),
      body: ready
          ? Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: <Widget>[
                  !running
                      ? RaisedButton(
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.play_arrow, color: Colors.green),
                              const Text("Build squares"),
                            ],
                          ),
                          onPressed: () {
                            setState(() => running = true);
                            buildSquares();
                          },
                        )
                      : RaisedButton(
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.stop, color: Colors.red),
                              const Text("Stop"),
                            ],
                          ),
                          onPressed: () => setState(() => running = false),
                        ),
                  Expanded(
                      child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 30),
                          itemCount: currentSquares,
                          itemBuilder: (BuildContext context, int index) {
                            return Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Container(
                                  width: 10.0,
                                  height: 10.0,
                                  decoration: BoxDecoration(color: Colors.blue),
                                  child: const Text(""),
                                ));
                          }))
                ],
              ))
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class PushPage extends StatefulWidget {
  @override
  _PushPageState createState() => _PushPageState();
}
