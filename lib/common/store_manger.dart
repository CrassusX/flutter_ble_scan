import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StoreManger {
  // 静态变量指向自身
  static final StoreManger _instance = StoreManger._();
  // 私有构造器
  StoreManger._();
  // // 方案1：静态方法获得实例变量
  static StoreManger getInstance() => _instance;
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void save(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? get(String key) {
    return  _prefs.getString(key);
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> setJson(String key, Object value) async {
    return await _prefs.setString(key, jsonEncode(value));
  }

  /// put object list.
  Future<bool>? putObjectList(String key, List<Object> list) {
    List<String>? dataList = list.map((value) {
      return json.encode(value);
    }).toList();
    return _prefs.setStringList(key, dataList);
  }

  // 获取对象list
  List<Map>? getObjectList(String key) {
    List<String>? dataLis = _prefs.getStringList(key);
    return dataLis?.map((value) {
      Map dataMap = json.decode(value);
      return dataMap;
    }).toList();
  }
}
