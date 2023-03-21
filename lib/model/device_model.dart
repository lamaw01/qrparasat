// To parse this JSON data, do
//
//     final DeviceModel = DeviceModelFromJson(jsonString);

import 'dart:convert';

DeviceModel deviceModelFromJson(String str) =>
    DeviceModel.fromJson(json.decode(str));

String deviceModelToJson(DeviceModel data) => json.encode(data.toJson());

class DeviceModel {
  DeviceModel({
    required this.success,
    required this.message,
    required this.data,
  });

  bool success;
  String message;
  Data data;

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
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
