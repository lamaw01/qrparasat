// To parse this JSON data, do
//
//     final dataLogs = dataLogsFromJson(jsonString);

import 'dart:convert';

DataLogs dataLogsFromJson(String str) => DataLogs.fromJson(json.decode(str));

String dataLogsToJson(DataLogs data) => json.encode(data.toJson());

class DataLogs {
  DataLogs({
    required this.success,
    required this.message,
    required this.data,
  });

  bool success;
  String message;
  Data data;

  factory DataLogs.fromJson(Map<String, dynamic> json) => DataLogs(
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
  });

  String? name;
  String? logType;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        name: json["name"],
        logType: json["log_type"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "log_type": logType,
      };
}
