import 'dart:async';
import 'dart:developer';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';

import '../model/log_model.dart';
import '../model/qr_model.dart';
import '../service/http_service.dart';
import '../service/position_service.dart';
import '../widget/dialogs.dart';

class QrPageData with ChangeNotifier {
  Position? _positon;
  // ignore: prefer_final_fields
  var _isAppDoneInit = false;
  bool get isAppDoneInit => _isAppDoneInit;
  var _latlng = "";
  String get latlng => _latlng;
  var _address = "";
  String get address => _address;
  var _deviceId = "";
  String get deviceId => _deviceId;
  var _branchId = "";
  String get branchId => _branchId;
  var _isDeviceAuthorized = false;
  bool get isDeviceAuthorized => _isDeviceAuthorized;
  var _hasCheckDeviceAuthorized = false;
  bool get hasCheckDeviceAuthorized => _hasCheckDeviceAuthorized;
  var _hasSendDeviceLog = false;
  bool get hasSendDeviceLog => _hasSendDeviceLog;
  var previousLogs = ValueNotifier(<Data>[]);
  final scrollController = ScrollController();
  // ignore: prefer_final_fields
  var _hasInternet = ValueNotifier(false);
  ValueNotifier<bool> get hasInternet => _hasInternet;
  // ignore: prefer_final_fields
  var _isLogging = ValueNotifier(false);
  ValueNotifier<bool> get isLogging => _isLogging;
  final _deviceTimestamp =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  String get deviceTimestamp => _deviceTimestamp;
  final _currentTimeDisplay =
      ValueNotifier<String>(DateFormat.jms().format(DateTime.now()));
  ValueNotifier<String> get currentTimeDisplay => _currentTimeDisplay;
  final _internetChecker = InternetConnectionChecker.createInstance(
    checkTimeout: const Duration(seconds: 5),
    checkInterval: const Duration(seconds: 5),
  );
  InternetConnectionChecker get internetChecker => _internetChecker;
  // ignore: prefer_final_fields
  var _errorList = <String>[];
  List<String> get errorList => _errorList;

  void addError(String error) {
    _errorList = [..._errorList, error];
  }

  void changeStateLoading() {
    _isLogging.value = !_isLogging.value;
  }

  final _deviceInfo = DeviceInfoPlugin();

  void internetStatus(InternetConnectionStatus status) async {
    if (status == InternetConnectionStatus.connected) {
      hasInternet.value = true;
    } else {
      hasInternet.value = false;
    }
    if (!hasCheckDeviceAuthorized) {
      await checkDeviceAuthorized();
    }
    if (!hasSendDeviceLog) {
      await insertDeviceLog();
    }
    log("hasInternet ${hasInternet.value}");
  }

  void printData() {
    log("_address $_address _latlng $_latlng _deviceId $_deviceId _branchId $_branchId");
  }

  Future<void> init() async {
    if (_isAppDoneInit) {
      return;
    }
    await initDeviceInfo();
    await initPosition();
    await initTranslateLatLng();
    await checkDeviceAuthorized();
    await insertDeviceLog();
    printData();
    _isAppDoneInit = false;
  }

  Future<void> initDeviceInfo() async {
    try {
      await _deviceInfo.androidInfo.then((result) {
        _deviceId = "${result.brand}:${result.product}:${result.id}";
      });
      log(_deviceId);
    } catch (e) {
      log('$e');
      _errorList.add('initDeviceInfo $e');
    }
  }

  Future<void> initPosition() async {
    try {
      await PositionService.getPosition().then((result) {
        _positon = result;
        _latlng = "${result.latitude} ${result.longitude}";
      });
      log("latlng $_latlng");
    } catch (e) {
      log('$e');
      _errorList.add('initPosition $e');
    }
  }

  Future<void> initTranslateLatLng() async {
    try {
      await placemarkFromCoordinates(_positon!.latitude, _positon!.longitude)
          .then((result) {
        _address =
            "${result.first.subAdministrativeArea} ${result.first.locality} ${result.first.thoroughfare} ${result.first.street}";
      });
      log(_address);
    } catch (e) {
      log('$e');
      _errorList.add('initTranslateLatLng $e');
    }
  }

  Future<void> checkDeviceAuthorized() async {
    try {
      await HttpService.checkDeviceAuthorized(_deviceId).then((result) {
        if (result.success) {
          _isDeviceAuthorized = result.data.authorized;
          _branchId = result.data.branchId;
          _hasCheckDeviceAuthorized = true;
        }
      });
    } catch (e) {
      log('$e');
      _errorList.add('checkDeviceAuthorized $e');
    }
  }

  Future<void> insertDeviceLog() async {
    try {
      await HttpService.insertDeviceLog(
              _deviceId, _deviceTimestamp, _address, _latlng)
          .then((_) {
        _hasSendDeviceLog = true;
      });
    } catch (e) {
      log('$e');
      _errorList.add('insertDeviceLog $e');
    }
  }

  Future<void> insertLog(String id, BuildContext context) async {
    try {
      changeStateLoading();
      await Future.delayed(const Duration(milliseconds: 500));
      QrModel qrData = qrModelFromJson(id);
      await HttpService.insertLog(
              qrData.id, address, latlng, deviceId, branchId)
          .then((result) {
        if (result.success) {
          Dialogs.showMyToast("${result.data.name}", context,
              logType: "${result.data.logType}");
          if (result.data.logType != "ALREADY IN") {
            result.data.timestamp = DateFormat.jm().format(DateTime.now());
            previousLogs.value = <Data>[...previousLogs.value, result.data];
            scrollController.animateTo(
                scrollController.position.minScrollExtent,
                duration: const Duration(seconds: 1),
                curve: Curves.bounceInOut);
            if (previousLogs.value.length > 20) {
              previousLogs.value.removeAt(0);
            }
          }
        } else if (result.message == "Invalid id") {
          Dialogs.showMyToast(result.message, context, error: true);
        } else if (result.message == "User not in branch") {
          Dialogs.showMyToast(result.message, context, error: true);
        } else {
          Dialogs.showMyToast("Unkown Error", context, error: true);
          _errorList.add('insertLog ${result.message}');
        }
      });
    } on FormatException catch (e) {
      log('$e');
      Dialogs.showMyToast('Invalid QR Code', context, error: true);
      _errorList.add('insertLog $e');
    } on TimeoutException catch (e) {
      log('$e');
      Dialogs.showMyToast('Request Timeout', context, error: true);
      _errorList.add('insertLog $e');
    } on Exception catch (e) {
      log('$e');
      Dialogs.showMyToast('$e', context, error: true);
      _errorList.add('insertLog $e');
    } finally {
      changeStateLoading();
    }
  }
}
