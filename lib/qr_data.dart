// To parse this JSON data, do
//
//     final qrData = qrDataFromJson(jsonString);

import 'dart:convert';

QrData qrDataFromJson(String str) => QrData.fromJson(json.decode(str));

String qrDataToJson(QrData data) => json.encode(data.toJson());

class QrData {
  QrData({
    required this.name,
    required this.id,
  });

  String name;
  String id;

  factory QrData.fromJson(Map<String, dynamic> json) => QrData(
        name: json["name"],
        id: json["id"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "id": id,
      };
}
