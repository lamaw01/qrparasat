// To parse this JSON data, do
//
//     final versionModel = versionModelFromJson(jsonString);

import 'dart:convert';

VersionModel versionModelFromJson(String str) =>
    VersionModel.fromJson(json.decode(str));

String versionModelToJson(VersionModel data) => json.encode(data.toJson());

class VersionModel {
  int id;
  String name;
  String version;
  DateTime updated;

  VersionModel({
    required this.id,
    required this.name,
    required this.version,
    required this.updated,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) => VersionModel(
        id: json["id"],
        name: json["name"],
        version: json["version"],
        updated: DateTime.parse(json["updated"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "version": version,
        "updated": updated.toIso8601String(),
      };
}
