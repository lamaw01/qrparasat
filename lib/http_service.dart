import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'data_logs.dart';
import 'device_authorized.dart';

class HttpService {
  static const String _serverUrl = 'http://uc-1.dnsalias.net:55083';

  static Future<DataLogs> insertLog(
      String id, String address, String latlng, String deviceId) async {
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
              "device_id": deviceId
            }))
        .timeout(const Duration(seconds: 5));
    log('${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return dataLogsFromJson(response.body);
    } else if (response.statusCode > 200) {
      throw Exception(response.statusCode);
    } else {
      throw Exception(response.body);
    }
  }

  static Future<DeviceAuthorized> checkDeviceAuthorized(String id) async {
    var response = await http
        .post(Uri.parse('$_serverUrl/check_device.php'),
            headers: <String, String>{
              'Accept': '*/*',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(<String, dynamic>{"device_id": id}))
        .timeout(const Duration(seconds: 5));
    log('${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return deviceAuthorizedFromJson(response.body);
    } else if (response.statusCode > 200) {
      throw Exception(response.statusCode);
    } else {
      throw Exception(response.body);
    }
  }

  static Future<void> insertDeviceLog(String id, String logTime) async {
    var response = await http
        .post(Uri.parse('$_serverUrl/insert_device_log.php'),
            headers: <String, String>{
              'Accept': '*/*',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(
                <String, dynamic>{"device_id": id, "log_time": logTime}))
        .timeout(const Duration(seconds: 5));
    log('${response.statusCode} ${response.body}');
  }
}
