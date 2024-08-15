import 'dart:convert';

class DeviceInfo {
  final String? result;
  final Data? data;
  final bool? flag;
  final String? code;
  final String? message;

  DeviceInfo(
      {required this.result, this.data, this.flag, this.code, this.message});

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      result: json['result'],
      data: Data.fromJson(json['data']),
      flag: json['flag'],
      code: json['code'],
      message: json['message'],
    );
  }
}

class Data {
  final String? id;
  final String? deviceNo;
  final String? baseId;
  final String? baseName;
  final String? serverId;
  final String? macAddress;

  Data({
    this.id,
    this.deviceNo,
    this.baseId,
    this.baseName,
    this.serverId,
    this.macAddress,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: json['id'],
      deviceNo: json['deviceNo'],
      baseId: json['baseId'],
      baseName: json['baseName'],
      serverId: json['serverId'],
      macAddress: json['macAddress'],
    );
  }

  String? get getMacAddrss =>
      formatMacAddress(macAddress ?? '', withColon: true);

  String formatMacAddress(String macAddress, {bool withColon = true}) {
    if (macAddress.length != 12) {
      return macAddress; // 不是标准的 MAC 地址格式，直接返回原始值
    }

    if (withColon) {
      return '${macAddress.substring(0, 2)}:${macAddress.substring(2, 4)}:${macAddress.substring(4, 6)}:${macAddress.substring(6, 8)}:${macAddress.substring(8, 10)}:${macAddress.substring(10, 12)}';
    } else {
      return '${macAddress.substring(0, 2)}${macAddress.substring(2, 4)}${macAddress.substring(4, 6)}${macAddress.substring(6, 8)}${macAddress.substring(8, 10)}${macAddress.substring(10, 12)}';
    }
  }
}

class WifiInfoParams {
  Map wifi;
  String password;
  bool isRemember;

  WifiInfoParams({this.wifi = const {}, this.password = '', this.isRemember = true});

  factory WifiInfoParams.fromJson(Map<String, dynamic> json) {
    return WifiInfoParams(
      wifi: json['wifi'],
      password: json['password'],
      isRemember: json['isRemember'],
    );
  }

  Map<String, dynamic> get toGetMap {
    return {
      'wifi': wifi,
      'password': password,
      'isRemember': isRemember,
    };
  }

  static String encode(WifiInfoParams item) => jsonEncode(item.toGetMap);

  static WifiInfoParams decode(String? storeKey) {
    if (storeKey == null) {
      return WifiInfoParams();
    }
    final map = jsonDecode(storeKey);
    return WifiInfoParams.fromJson(map);
  }
}
