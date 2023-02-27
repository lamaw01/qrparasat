import 'dart:convert';

Data dataFromJson(String str) => Data.fromJson(json.decode(str));

String dataToJson(Data data) => json.encode(data.toJson());

class Data {
  Data({
    required this.data,
    required this.success,
  });

  String data;
  bool success;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        data: json["data"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "data": data,
        "success": success,
      };
}
