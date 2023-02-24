import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

//port: 3306,
//host: '172.21.3.25',
//host: '172.21.2.183',

Future<bool> insertLog(String data) async {
  var settings = ConnectionSettings(
    host: '172.21.3.25',
    port: 80,
    user: 'autocctv',
    password: 'autocctv123',
    db: 'autocctv',
    timeout: const Duration(seconds: 10),
  );

  bool success = true;
  try {
    var conn = await MySqlConnection.connect(settings);
    debugPrint('db connect $conn');
    var result = await conn.query(
      'insert into qr_logs (data) values (?)',
      [data],
    );
    debugPrint('affected rows ${result.affectedRows}');
    conn.close();
  } catch (e) {
    debugPrint(e.toString());
    success = false;
  }
  return success;
}
