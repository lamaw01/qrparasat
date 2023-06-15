import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  var _appVersion = "";
  String get appVersion => _appVersion;

  var _deviceId = "";
  String get deviceId => _deviceId;

  var _isDeviceAuthorized = false;
  bool get isDeviceAuthorized => _isDeviceAuthorized;

  final _previousLogs = ValueNotifier(<Data>[]);
  ValueNotifier<List<Data>> get previousLogs => _previousLogs;

  final _errorList = <String>[];
  List<String> get errorList => _errorList;

  final _hasInternet = ValueNotifier(false);
  ValueNotifier<bool> get hasInternet => _hasInternet;

  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  void changeStateLoading(bool state) {
    _isLogging.value = state;
  }

  // listens to internet status
  void internetStatus(InternetConnectionStatus status) async {
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
    debugPrint("hasInternet ${_hasInternet.value}");
  }

  // initialize all functions
  Future<void> init() async {
    await getPackageInfo();
    await getDeviceInfo();
    await getPosition();
    await translateLatLng();
    await checkDeviceAuthorized();
    await insertDeviceLog();
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
