import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/log_model.dart';
import '../model/device_model.dart';

class HttpService {
  static const String _serverUrl = 'http://uc-1.dnsalias.net:55083';

  static Exception _httpExceptions(int code) {
    switch (code) {
      case 400:
        return Exception("$code Bad Request");
      case 401:
        return Exception("$code Unauthorized");
      case 403:
        return Exception("$code Forbidden");
      case 404:
        return Exception("$code Not Found");
      case 500:
        return Exception("$code Internal Server Error");
      case 502:
        return Exception("$code Bad Gateway");
      case 503:
        return Exception("$code Service Unavailable");
      case 504:
        return Exception("$code Gateway Timeout");
      default:
        return Exception("$code Unkown error");
    }
  }

  static Future<LogModel> insertLog(String id, String address, String latlng,
      String deviceId, String branchId) async {
    var response = await http
        .post(Uri.parse('$_serverUrl/insert_log.php'),
            headers: <String, String>{
              'Accept': '*/*',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(<String, dynamic>{
              "employee_id": id,
              "address": address,
              "latlng": latlng,
              "device_id": deviceId,
              "branch_id": branchId
            }))
        .timeout(const Duration(seconds: 5));
    debugPrint('insertLog ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return logModelFromJson(response.body);
    } else if (response.statusCode > 200) {
      throw _httpExceptions(response.statusCode);
    } else {
      throw Exception(response.body);
    }
  }

  static Future<DeviceModel> checkDeviceAuthorized(String id) async {
    var response = await http
        .post(Uri.parse('$_serverUrl/check_device.php'),
            headers: <String, String>{
              'Accept': '*/*',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(<String, dynamic>{"device_id": id}))
        .timeout(const Duration(seconds: 5));
    debugPrint('checkDeviceAuthorized ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return deviceModelFromJson(response.body);
    } else if (response.statusCode > 200) {
      throw _httpExceptions(response.statusCode);
    } else {
      throw Exception(response.body);
    }
  }

  static Future<void> insertDeviceLog(String id, String logTime, String address,
      String latlng, String version) async {
    var response = await http
        .post(Uri.parse('$_serverUrl/insert_device_log.php'),
            headers: <String, String>{
              'Accept': '*/*',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(<String, dynamic>{
              "device_id": id,
              "log_time": logTime,
              "address": address,
              "latlng": latlng,
              "version": version,
              "app_name": 'Sirius'
            }))
        .timeout(const Duration(seconds: 5));
    debugPrint('insertDeviceLog ${response.statusCode} ${response.body}');
  }
}
