import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

import '../model/log_model.dart';
import '../model/qr_model.dart';
import '../service/http_service.dart';
import '../service/position_service.dart';

class QrPageData with ChangeNotifier {
  Position? _positon;

  final _deviceInfo = DeviceInfoPlugin();

  // bool if uploading qr scan
  final _isLogging = ValueNotifier(false);
  ValueNotifier<bool> get isLogging => _isLogging;

  var _latlng = "";
  var _address = "";
  var _branchId = "";
  var _hasCheckDeviceAuthorized = false;
  var _hasSendDeviceLog = false;
  var _sixDigitCode = 000000;

  var _appVersion = "";
  String get appVersion => _appVersion;

  var _deviceId = "";
  String get deviceId => _deviceId;

  var _appVersionDatabase = "";
  String get appVersionDatabase => _appVersionDatabase;

  var _isDeviceAuthorized = false;
  bool get isDeviceAuthorized => _isDeviceAuthorized;

  var _hasVerifiedVersion = false;
  bool get hasVerifiedVersion => _hasVerifiedVersion;

  final _previousLogs = ValueNotifier(<Data>[]);
  ValueNotifier<List<Data>> get previousLogs => _previousLogs;

  final _errorList = <String>[];
  List<String> get errorList => _errorList;

  final _hasInternet = ValueNotifier(false);
  ValueNotifier<bool> get hasInternet => _hasInternet;

  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  final _scanMode = ValueNotifier(false);
  ValueNotifier<bool> get scanMode => _scanMode;

  void changeStateLoading(bool state) {
    _isLogging.value = state;
  }

  void scanModeState() {
    _scanMode.value = !_scanMode.value;
  }

  // listens to internet status
  void internetStatus({
    required InternetConnectionStatus status,
    required BuildContext context,
  }) async {
    if (status == InternetConnectionStatus.connected) {
      _hasInternet.value = true;
    } else {
      _hasInternet.value = false;
    }
    if (!_hasCheckDeviceAuthorized) {
      await checkDeviceAuthorized();
    }
    if (!_hasSendDeviceLog) {
      await insertDeviceLog();
    }
    // check if gotten an app version in database
    if (!_hasVerifiedVersion) {
      await getAppVersion().then((_) {
        showVersionAppDialog(context);
      });
    }
    debugPrint("hasInternet ${_hasInternet.value}");
  }

  // initialize all functions
  Future<String> init() async {
    await getDeviceInfo();
    await checkCode();
    await getPosition();
    await translateLatLng();
    if (_address != '') {
      await checkDeviceAuthorized();
      await insertDeviceLog();
    }
    return _address;
  }

  Future<void> checkVersion() async {
    await getPackageInfo();
    await getAppVersion();
  }

  // check location service
  Future<void> checkLocationService(BuildContext context) async {
    await Geolocator.isLocationServiceEnabled().then((result) async {
      if (!result) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location service disabled'),
              content: const Text(
                  'Please enable the location service. After enabling press Continue.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Settings'),
                  onPressed: () {
                    Geolocator.openLocationSettings();
                  },
                ),
                TextButton(
                  child: const Text('Continue'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  Future<void> showVersionAppDialog(BuildContext context) async {
    var intAppVersion = _appVersion.replaceAll(".", "").trim();
    var intAppVersionDatabase = _appVersionDatabase.replaceAll(".", "").trim();
    try {
      if (int.parse(intAppVersion) < int.parse(intAppVersionDatabase)) {
        Provider.of<MobileScannerController>(context, listen: false).dispose();
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('App Out of date'),
              content: Text(
                  'Current version $_appVersion is out of date. Please update to version $_appVersionDatabase.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Download new version'),
                  onPressed: () {
                    launchUrl(Uri.parse(HttpService.downloadLink),
                        mode: LaunchMode.externalApplication);
                  },
                ),
                TextButton(
                  child: const Text('Exit'),
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('showVersionAppDialog $e');
      _errorList.add('showVersionAppDialog $e');
    }
  }

  // get device version
  Future<void> getPackageInfo() async {
    try {
      await PackageInfo.fromPlatform().then((result) {
        _appVersion = result.version;
        debugPrint(_appVersion);
      });
    } catch (e) {
      debugPrint('$e');
      _errorList.add('initDeviceInfo $e');
    }
  }

  // get app version in database
  Future<void> getAppVersion() async {
    try {
      await HttpService.getAppVersion().then((result) {
        _appVersionDatabase = result.version;
        _hasVerifiedVersion = true;
      });
    } catch (e) {
      debugPrint('getAppVersion $e');
      _errorList.add('getAppVersion $e');
    }
  }

  // generate 6 digit code and store in sharedpref
  Future<void> generateCode() async {
    try {
      var random = Random();
      var generatedCode = random.nextInt(900000) + 100000;
      _sixDigitCode = generatedCode;
      debugPrint("$_sixDigitCode");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('code', _sixDigitCode);
      _deviceId = "$_deviceId:$_sixDigitCode";
    } catch (e) {
      debugPrint('$e');
      _errorList.add('initDeviceInfo $e');
    }
  }

  // check if device has generate code
  Future<void> checkCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? code = prefs.getInt('code');
      if (code != null) {
        _sixDigitCode = code;
        _deviceId = "$_deviceId:$_sixDigitCode";
      } else {
        generateCode();
      }
    } catch (e) {
      debugPrint('$e');
      _errorList.add('initDeviceInfo $e');
    }
  }

  // get device info
  Future<void> getDeviceInfo() async {
    try {
      await _deviceInfo.androidInfo.then((result) {
        _deviceId = "${result.brand}:${result.product}:${result.id}";
      });
      debugPrint(_deviceId);
    } catch (e) {
      debugPrint('$e');
      _errorList.add('initDeviceInfo $e');
    }
  }

  // get lat lng of device
  Future<void> getPosition() async {
    try {
      await PositionService.getPosition().then((result) {
        _positon = result;
        _latlng = "${result.latitude} ${result.longitude}";
      });
      debugPrint("latlng $_latlng");
    } catch (e) {
      debugPrint('$e');
      _errorList.add('initPosition $e');
    }
  }

  // translate latlng to address
  Future<void> translateLatLng() async {
    try {
      await placemarkFromCoordinates(_positon!.latitude, _positon!.longitude)
          .then((result) {
        _address =
            "${result.first.subAdministrativeArea} ${result.first.locality} ${result.first.thoroughfare} ${result.first.street}";
      });
      debugPrint(_address);
    } catch (e) {
      debugPrint('$e');
      _errorList.add('initTranslateLatLng $e');
    }
  }

  // check if device is registered in database
  Future<void> checkDeviceAuthorized() async {
    try {
      await HttpService.checkDeviceAuthorized(deviceId: _deviceId)
          .then((result) {
        if (result.success) {
          _isDeviceAuthorized = result.data.authorized;
          _branchId = result.data.branchId;
          _hasCheckDeviceAuthorized = true;
        }
      });
    } catch (e) {
      debugPrint('$e');
      _errorList.add('checkDeviceAuthorized $e');
    }
  }

  // insert device log to database
  Future<void> insertDeviceLog() async {
    try {
      await HttpService.insertDeviceLog(
        id: _deviceId,
        logTime: _dateFormat.format(DateTime.now()),
        address: _address,
        latlng: _latlng,
        version: _appVersion,
      ).then((_) {
        _hasSendDeviceLog = true;
      });
    } catch (e) {
      debugPrint('$e');
      _errorList.add('insertDeviceLog $e');
    }
  }

  // insert employee qr scan log to database
  Future<LogReturn> insertLog({
    required String qrData,
    required BuildContext context,
  }) async {
    changeStateLoading(true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      var qrModel = qrModelFromJson(qrData);
      var result = await HttpService.insertLog(
        id: qrModel.id,
        address: _address,
        latlng: _latlng,
        deviceId: _deviceId,
        branchId: _branchId,
        app: 'sirius',
        version: _appVersion,
        deviceTimestamp: _dateFormat.format(DateTime.now()),
      );
      if (result.success) {
        return LogReturn(result: LogResult.success, model: result);
      } else if (result.message == "Invalid id") {
        return LogReturn(result: LogResult.invalidId);
      } else if (result.message == "User not in branch") {
        return LogReturn(result: LogResult.userNotInBranch);
      } else {
        _errorList.add('insertLog ${result.message}');
        return LogReturn(result: LogResult.unkownError);
      }
    } on FormatException catch (e) {
      debugPrint('$e');
      _errorList.add('insertLog $e');
      return LogReturn(result: LogResult.invalidQr);
    } on TimeoutException catch (e) {
      debugPrint('$e');
      _errorList.add('insertLog $e');
      return LogReturn(result: LogResult.requestTimeout);
    } on Exception catch (e) {
      debugPrint('$e');
      _errorList.add('insertLog $e');
      return LogReturn(result: LogResult.unkownError);
    } finally {
      changeStateLoading(false);
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  // Future<File> get _localFile async {
  //   final path = await _localPath;
  //   final file = File('$path/SNOVCORA.exf');
  //   if (await file.exists()) {
  //     file.create();
  //   }
  //   return File('$path/SNOVCORA.exf');
  // }

  Future<File> writeData(String data) async {
    final path = await _localPath;
    final file = File('$path/SNOVCORA.exf');
    // Write the file
    // return file.writeAsString(data);
    file.writeAsString('$data            ', mode: FileMode.append);
    return file;
  }

  Future<String> readData() async {
    final path = await _localPath;
    final file = File('$path/SNOVCORA.exf');
    // Read the file
    return file.readAsString();
  }
}

enum LogResult {
  success,
  invalidId,
  userNotInBranch,
  unkownError,
  invalidQr,
  requestTimeout,
}

class LogReturn {
  final Enum result;
  final LogModel? model;

  LogReturn({required this.result, this.model});
}
