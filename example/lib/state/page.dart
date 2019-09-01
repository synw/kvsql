import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store.dart';

class _StatePageState extends State<StatePage> {
  bool ready = false;

  @override
  void initState() {
    stateStore.onReady.then((dynamic _) {
      setState(() => ready = true);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Persistant state")),
      body: Center(
          child: ready
              ? (state.value == null)
                  ? const Text("1", textScaleFactor: 1.5)
                  : Text("Value: ${state.value}", textScaleFactor: 1.5)
              : const CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.edit),
        onPressed: () => state.updateValue(),
      ),
    );
  }
}

class StatePage extends StatefulWidget {
  @override
  _StatePageState createState() => _StatePageState();
}
