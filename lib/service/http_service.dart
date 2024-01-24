import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../model/log_model.dart';
import '../model/device_model.dart';
import '../model/version_model.dart';

class HttpService {
  static const String serverUrl = 'http://103.62.153.74:53000/dtr_api';
  static const String appDownloadLink =
      'http://103.62.153.74:53000/download/sirius.apk';

  static const String downloadLink =
      'http://103.62.153.74:53000/download/orion.html';

  static Future<LogModel> insertLog({
    required String id,
    required String address,
    required String latlng,
    required String deviceId,
    required String branchId,
    required String app,
    required String version,
    required String deviceTimestamp,
  }) async {
    final day = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
    var response = await http
        .post(Uri.parse('$serverUrl/insert_log.php'),
            headers: <String, String>{
              'Accept': '*/*',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(<String, dynamic>{
              "employee_id": id,
              "address": address,
              "latlng": latlng,
              "device_id": deviceId,
              "branch_id": branchId,
              "app": app,
              "version": version,
              "selfie_timestamp": deviceTimestamp,
              "day": day,
            }))
        .timeout(const Duration(seconds: 10));
    debugPrint('insertLog ${response.body}');
    return logModelFromJson(response.body);
  }

  static Future<DeviceModel> checkDeviceAuthorized(
      {required String deviceId}) async {
    var response = await http
        .post(Uri.parse('$serverUrl/check_device.php'),
            headers: <String, String>{
              'Accept': '*/*',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(<String, dynamic>{"device_id": deviceId}))
        .timeout(const Duration(seconds: 10));
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
        .post(Uri.parse('$serverUrl/insert_device_log.php'),
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
              "app_name": 'sirius'
            }))
        .timeout(const Duration(seconds: 10));
    debugPrint('insertDeviceLog ${response.body}');
  }

  static Future<VersionModel> getAppVersion() async {
    var response = await http.get(
      Uri.parse('$serverUrl/get_app_version.php'),
      headers: <String, String>{
        'Accept': '*/*',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    ).timeout(const Duration(seconds: 10));
    debugPrint('getAppVersion ${response.body}');
    return versionModelFromJson(response.body);
  }
}
