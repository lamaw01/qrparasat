// To parse this JSON data, do
//
//     final data = dataFromJson(jsonString);

import 'dart:convert';

Data dataFromJson(String str) => Data.fromJson(json.decode(str));

String dataToJson(Data data) => json.encode(data.toJson());

class Data {
  Data({
    required this.name,
    required this.logType,
    required this.success,
  });

  String name;
  String logType;
  bool success;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        name: json["name"],
        logType: json["log_type"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "log_type": logType,
        "success": success,
      };
}
