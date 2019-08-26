import 'dart:io';
import 'package:flutter/services.dart';

Directory directory;
const MethodChannel channel = MethodChannel('com.tekartik.sqflite');
final List<MethodCall> log = <MethodCall>[];
bool setupDone = false;

void setup() async {
  if (setupDone) {
    return;
  }
  directory = await Directory.systemTemp.createTemp();

  String response;
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    //print("METHOD CALL: $methodCall");
    log.add(methodCall);
    switch (methodCall.method) {
      case "getDatabasesPath":
        return directory.path;
        break;
      case "query":
        if (methodCall.arguments["sql"] ==
            'SELECT key,value,type FROM kvstore WHERE key="k"') {
          final res = <Map<String, dynamic>>[
            <String, dynamic>{"key": "k", "value": "v", "type": "string"}
          ];
          return res;
        } else if (methodCall.arguments["sql"] ==
            'SELECT key,value,type FROM kvstore WHERE key="k_int"') {
          final res = <Map<String, dynamic>>[
            <String, dynamic>{"key": "k", "value": "1", "type": "integer"}
          ];
          return res;
        } else if (methodCall.arguments["sql"] ==
            'SELECT key,value,type FROM kvstore WHERE key="k_double"') {
          final res = <Map<String, dynamic>>[
            <String, dynamic>{"key": "k", "value": "1.0", "type": "double"}
          ];
          return res;
        } else if (methodCall.arguments["sql"] ==
            'SELECT key,value,type FROM kvstore WHERE key="k_list"') {
          final res = <Map<String, dynamic>>[
            <String, dynamic>{"key": "k", "value": "1,2,3", "type": "list"}
          ];
          return res;
        } else if (methodCall.arguments["sql"] ==
            'SELECT key,value,type FROM kvstore WHERE key="k_map"') {
          final res = <Map<String, dynamic>>[
            <String, dynamic>{
              "key": "k",
              "value": '{"1":1,"2":2}',
              "type": "map"
            }
          ];
          return res;
        } else if (methodCall.arguments["sql"] == 'SELECT * FROM kvstore') {
          final res = <Map<String, dynamic>>[<String, dynamic>{}];
          return res;
        }
    }
    return response;
  });
}
