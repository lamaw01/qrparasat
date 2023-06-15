import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/log_model.dart';
import '../model/device_model.dart';

class HttpService {
  static const String _serverUrl = 'http://uc-1.dnsalias.net:55083/dtr_api';

  static Future<LogModel> insertLog({
    required String id,
    required String address,
    required String latlng,
    required String deviceId,
    required String branchId,
  }) async {
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
    debugPrint('insertLog ${response.body}');
    return logModelFromJson(response.body);
  }

  static Future<DeviceModel> checkDeviceAuthorized(
      {required String deviceId}) async {
    var response = await http
        .post(Uri.parse('$_serverUrl/check_device.php'),
            headers: <String, String>{
              'Accept': '*/*',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(<String, dynamic>{"device_id": deviceId}))
        .timeout(const Duration(seconds: 5));
    debugPrint('checkDeviceAuthorized ${response.body}');
    return deviceModelFromJson(response.body);
  }

  static Future<void> insertDeviceLog({
    required String id,
    required String logTime,
    required String address,
    required String latlng,
    required String version,
  }) async {
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
    debugPrint('insertDeviceLog ${response.body}');
  }
}
