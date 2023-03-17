// To parse this JSON data, do
//
//     final deviceData = deviceDataFromJson(jsonString);

import 'dart:convert';

DeviceData deviceDataFromJson(String str) =>
    DeviceData.fromJson(json.decode(str));

String deviceDataToJson(DeviceData data) => json.encode(data.toJson());

class DeviceData {
  DeviceData({
    required this.success,
    required this.message,
    required this.data,
  });

  bool success;
  String message;
  Data data;

  factory DeviceData.fromJson(Map<String, dynamic> json) => DeviceData(
        success: json["success"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
      };
}

class Data {
  Data({
    required this.authorized,
    required this.branchId,
  });

  bool authorized;
  String branchId;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        authorized: json["authorized"],
        branchId: json["branch_id"],
      );

  Map<String, dynamic> toJson() => {
        "authorized": authorized,
        "branch_id": branchId,
      };
}
