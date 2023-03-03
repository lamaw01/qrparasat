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
    required this.authorized,
    required this.success,
  });

  bool authorized;
  bool success;

  factory DeviceAuthorized.fromJson(Map<String, dynamic> json) =>
      DeviceAuthorized(
        authorized: json["authorized"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "authorized": authorized,
        "success": success,
      };
}
