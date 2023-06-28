// To parse this JSON data, do
//
//     final siriusVersionModel = siriusVersionModelFromJson(jsonString);

import 'dart:convert';

SiriusVersionModel siriusVersionModelFromJson(String str) =>
    SiriusVersionModel.fromJson(json.decode(str));

String siriusVersionModelToJson(SiriusVersionModel data) =>
    json.encode(data.toJson());

class SiriusVersionModel {
  String siriusVersion;
  DateTime siriusUpdated;

  SiriusVersionModel({
    required this.siriusVersion,
    required this.siriusUpdated,
  });

  factory SiriusVersionModel.fromJson(Map<String, dynamic> json) =>
      SiriusVersionModel(
        siriusVersion: json["sirius_version"],
        siriusUpdated: DateTime.parse(json["sirius_updated"]),
      );

  Map<String, dynamic> toJson() => {
        "sirius_version": siriusVersion,
        "sirius_updated": siriusUpdated.toIso8601String(),
      };
}
