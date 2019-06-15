import 'dart:convert';

/// Encode a value to be stored as a string
List<String> encode(dynamic value) {
  assert(value != null);
  String val;
  String typeStr;
  if (value == null)
    val = null;
  else {
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
      val = value
          .reduce((dynamic curr, dynamic next) => "$curr,$next")
          .toString();
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

/// Decode a database string to it's type
dynamic decode(dynamic value, String typeStr) {
  assert(value != null);
  assert(typeStr != null);
  if (value == "NULL") return null;
  dynamic val;
  switch (typeStr) {
    case "string":
      try {
        val = value;
      } catch (e) {
        throw (e);
      }
      break;
    case "integer":
      try {
        val = int.parse(value.toString());
      } catch (e) {
        throw (e);
      }
      break;
    case "double":
      try {
        val = double.parse(value.toString());
      } catch (e) {
        throw (e);
      }
      break;
    case "list":
      try {
        val = value.split(",");
      } catch (e) {
        throw (e);
      }
      break;
    case "map":
      try {
        val = json.decode(value.toString());
      } catch (e) {
        throw (e);
      }
      break;
    default:
      val = "$value";
  }
  return val;
}
