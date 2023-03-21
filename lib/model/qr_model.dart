// To parse this JSON data, do
//
//     final QrModel = QrModelFromJson(jsonString);

import 'dart:convert';

QrModel qrModelFromJson(String str) => QrModel.fromJson(json.decode(str));

String qrModelToJson(QrModel data) => json.encode(data.toJson());

class QrModel {
  QrModel({
    required this.name,
    required this.id,
  });

  String name;
  String id;

  factory QrModel.fromJson(Map<String, dynamic> json) => QrModel(
        name: json["name"],
        id: json["id"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "id": id,
      };
}
