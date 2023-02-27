import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'data.dart';

class HttpService {
  static const String _serverUrl = 'http://uc-1.dnsalias.net:55083';

  static Future<Data> postLog(String id) async {
    var response = await http
        .post(Uri.parse('$_serverUrl/insert_log.php'),
            headers: <String, String>{
              'Accept': '*/*',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(<String, dynamic>{"employee_id": id}))
        .timeout(const Duration(seconds: 4));
    log(response.body);
    if (response.statusCode == 200) {
      return dataFromJson(response.body);
    } else {
      throw Exception(json.decode(response.body));
    }
  }
}
