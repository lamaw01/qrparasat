// To parse this JSON data, do
//
//     final deviceAuthorized = deviceAuthorizedFromJson(jsonString);

import 'dart:convert';

DeviceAuthorized deviceAuthorizedFromJson(String str) =>
    DeviceAuthorized.fromJson(json.decode(str));

String deviceAuthorizedToJson(DeviceAuthorized data) =>
    json.encode(data.toJson());

class DeviceAuthorized {
  DeviceAuthorized({
    required this.success,
    required this.message,
    required this.data,
  });

  bool success;
  String message;
  Data data;

  factory DeviceAuthorized.fromJson(Map<String, dynamic> json) =>
      DeviceAuthorized(
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
  });

  bool? authorized;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        authorized: json["authorized"],
      );

  Map<String, dynamic> toJson() => {
        "authorized": authorized,
      };
}
