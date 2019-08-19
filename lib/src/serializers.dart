import 'dart:convert';

/// Encode a value to be stored as a string
List<String> encode(dynamic value) {
  String val;
  String typeStr;
  if (value == null) {
    val = null;
    typeStr = "unknown";
    return [val, typeStr];
  } else {
    if (value is String) {
      val = value.toString();
      typeStr = "string";
    } else if (value is int) {
      val = "${int.parse(value.toString())}";
      typeStr = "integer";
    } else if (value is double) {
      val = "${double.parse(value.toString())}";
      typeStr = "double";
    } else if (value is List) {
      /*val = value
          .reduce((dynamic curr, dynamic next) => "$curr,$next")
          .toString();*/
      val = value.join(",");
      typeStr = "list";
    } else if (value is Map) {
      val = json.encode(value);
      typeStr = "map";
    } else {
      val = "$val";
      typeStr = "unknown";
    }
  }
  return <String>[val, typeStr];
}

///Decode a database list string to it's type
List<T> decodeList<T>(dynamic value) {
  if (value == "NULL" || value == null) {
    return null;
  }
  final List dataList = value.toString().split(",");
  final typedList = <T>[];
  for (final val in dataList) {
    T v;
    try {
      v = decodeFromType<T>(val);
      typedList.add(v);
    } catch (e) {
      throw ("Value $v is of type ${v.runtimeType} and should be $T");
    }
  }
  if (typedList.isEmpty) {
    return null;
  }
  return typedList;
}

/// Decode a database map string to it's type
Map<K, V> decodeMap<K, V>(dynamic value) {
  if (value == "NULL" || value == null) {
    return null;
  }
  final dataMap = json.decode(value.toString()) as Map;
  // check map types
  final typedMap = <K, V>{};
  for (final k in dataMap.keys) {
    if (!(k is K)) {
      throw ("The key $k is of type ${k.runtimeType} and should be $V");
    }
    if (!(dataMap[k] is V)) {
      throw ("The value $k is of type ${dataMap[k].runtimeType} " +
          "and should be $V");
    }
    typedMap[k as K] = dataMap[k] as V;
  }
  return typedMap;
}

/// Decode a database value to it's type
T decodeFromTypeStr<T>(dynamic value, String typeStr) {
  if (value == "NULL" || value == null) {
    return null;
  }
  dynamic val;
  switch (typeStr) {
    case "string":
      try {
        val = _decodeString(value);
      } catch (e) {
        rethrow;
      }
      break;
    case "integer":
      try {
        val = _decodeInt(value);
      } catch (e) {
        rethrow;
      }
      break;
    case "double":
      try {
        val = _decodeDouble(value);
      } catch (e) {
        rethrow;
      }
      break;
    case "list":
      try {
        val = _decodeList(value);
      } catch (e) {
        rethrow;
      }
      break;
    case "map":
      try {
        val = _decodeMap(value);
      } catch (e) {
        rethrow;
      }
      break;
    default:
      throw ("Type string $typeStr not known for value $value");
  }
  T endVal;
  if (T != dynamic) {
    if (!(val is T)) {
      throw ("Value is of type ${val.runtimeType} and should be $T");
    }
  }
  endVal = val as T;
  return endVal;
}

/// Decode a database value to it's type
T decodeFromType<T>(dynamic value) {
  if (value == "NULL" || value == null) {
    return null;
  }
  T endVal;
  switch (T) {
    case String:
      try {
        endVal = _decodeString(value) as T;
      } catch (e) {
        rethrow;
      }
      break;
    case int:
      try {
        endVal = _decodeInt(value) as T;
      } catch (e) {
        rethrow;
      }
      break;
    case double:
      try {
        endVal = _decodeDouble(value) as T;
      } catch (e) {
        rethrow;
      }
      break;
    case List:
      try {
        endVal = _decodeList(value) as T;
      } catch (e) {
        rethrow;
      }
      break;
    case Map:
      try {
        endVal = _decodeMap(value) as T;
      } catch (e) {
        rethrow;
      }
      break;
    default:
      throw ("Type $T is unknown for value $value");
  }
  return endVal;
}

String _decodeString(dynamic value) {
  return "$value";
}

int _decodeInt(dynamic value) {
  int val;
  try {
    val = int.parse(value.toString());
  } catch (e) {
    throw ("Can not parse integer $value");
  }
  return val;
}

double _decodeDouble(dynamic value) {
  double val;
  try {
    val = double.parse(value.toString());
  } catch (e) {
    throw ("Can not parse integer $value");
  }
  return val;
}

List<dynamic> _decodeList(dynamic value) {
  var val = <dynamic>[];
  try {
    val = value.toString().split(",");
  } catch (e) {
    throw ("Can not decode list $value");
  }
  return val;
}

Map<dynamic, dynamic> _decodeMap(dynamic value) {
  var val = <dynamic, dynamic>{};
  try {
    val = json.decode(value.toString()) as Map;
  } catch (e) {
    throw ("Can not decode list $value");
  }
  return val;
}
