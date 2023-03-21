// To parse this JSON data, do
//
//     final LogModel = LogModelFromJson(jsonString);

import 'dart:convert';

LogModel logModelFromJson(String str) => LogModel.fromJson(json.decode(str));

String logModelToJson(LogModel data) => json.encode(data.toJson());

class LogModel {
  LogModel({
    required this.success,
    required this.message,
    required this.data,
  });

  bool success;
  String message;
  Data data;

  factory LogModel.fromJson(Map<String, dynamic> json) => LogModel(
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
    this.name,
    this.logType,
    this.timestamp,
  });

  String? name;
  String? logType;
  String? timestamp;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        name: json["name"],
        logType: json["log_type"],
        timestamp: json["timestamp"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "log_type": logType,
        "timestamp": timestamp,
      };
}
