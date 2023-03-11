import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'data_logs.dart';
import 'device_authorized.dart';

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
      throw _httpExceptions(response.statusCode);
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
      throw _httpExceptions(response.statusCode);
    } else {
      throw Exception(response.body);
    }
  }

  static Future<void> insertDeviceLog(
      String id, String logTime, String address, String latlng) async {
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
              "latlng": latlng
            }))
        .timeout(const Duration(seconds: 5));
    log('${response.statusCode} ${response.body}');
  }
}
