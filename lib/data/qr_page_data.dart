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
import '../widget/app_dialogs.dart';

class QrPageData with ChangeNotifier {
  Position? _positon;
  final _deviceInfo = DeviceInfoPlugin();
  // bool if app done initializing
  var _isAppDoneInit = false;
  bool get isAppDoneInit => _isAppDoneInit;
  // bool if uploading qr scan
  final _isLogging = ValueNotifier(false);
  ValueNotifier<bool> get isLogging => _isLogging;
  var _latlng = "";
  var _address = "";
  var _deviceId = "";
  String get deviceId => _deviceId;
  var _branchId = "";
  var _isDeviceAuthorized = false;
  bool get isDeviceAuthorized => _isDeviceAuthorized;
  var _hasCheckDeviceAuthorized = false;
  var _hasSendDeviceLog = false;
  var previousLogs = ValueNotifier(<Data>[]);
  final scrollController = ScrollController();
  final _hasInternet = ValueNotifier(false);
  ValueNotifier<bool> get hasInternet => _hasInternet;
  var _errorList = <String>[];
  List<String> get errorList => _errorList;
  // timestamp of opening device
  final _deviceLogtime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  var _appVersion = "0.0.0";
  String get appVersion => _appVersion;

  void addError(String error) {
    _errorList = [..._errorList, error];
  }

  void changeStateLoading() {
    _isLogging.value = !_isLogging.value;
  }

  Future<void> doneInit() async {
    _isAppDoneInit = true;
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
    if (_isAppDoneInit) {
      return;
    }
    await initDeviceInfo();
    await initPackageInfo();
    await initPosition();
    await initTranslateLatLng();
    await checkDeviceAuthorized();
    await insertDeviceLog();
  }

  // get device version
  Future<void> initPackageInfo() async {
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
  Future<void> initDeviceInfo() async {
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
  Future<void> initPosition() async {
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
  Future<void> initTranslateLatLng() async {
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
      await HttpService.checkDeviceAuthorized(_deviceId).then((result) {
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
              _deviceId, _deviceLogtime, _address, _latlng, _appVersion)
          .then((_) {
        _hasSendDeviceLog = true;
      });
    } catch (e) {
      debugPrint('$e');
      _errorList.add('insertDeviceLog $e');
    }
  }

  // insert employee qr scan log to database
  Future<void> insertLog(String id, BuildContext context) async {
    try {
      changeStateLoading();
      await Future.delayed(const Duration(milliseconds: 500));
      QrModel qrData = qrModelFromJson(id);
      await HttpService.insertLog(
              qrData.id, _address, _latlng, deviceId, _branchId)
          .then((result) {
        if (result.success) {
          AppDialogs.showMyToast("${result.data.name}", context,
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
          AppDialogs.showMyToast(result.message, context, error: true);
        } else if (result.message == "User not in branch") {
          AppDialogs.showMyToast(result.message, context, error: true);
        } else {
          AppDialogs.showMyToast("Unkown Error", context, error: true);
          _errorList.add('insertLog ${result.message}');
        }
      });
      // previousLogs.value = <Data>[
      //   ...previousLogs.value,
      //   Data(
      //     name: 'janrey dumaog',
      //     logType: 'test',
      //     timestamp: DateFormat.jm().format(DateTime.now()),
      //   )
      // ];
      scrollController.animateTo(scrollController.position.minScrollExtent,
          duration: const Duration(seconds: 1), curve: Curves.bounceInOut);
      if (previousLogs.value.length > 20) {
        previousLogs.value.removeAt(0);
      }
    } on FormatException catch (e) {
      debugPrint('$e');
      AppDialogs.showMyToast('Invalid QR Code', context, error: true);
      _errorList.add('insertLog $e');
    } on TimeoutException catch (e) {
      debugPrint('$e');
      AppDialogs.showMyToast('Request Timeout', context, error: true);
      _errorList.add('insertLog $e');
    } on Exception catch (e) {
      debugPrint('$e');
      AppDialogs.showMyToast('$e', context, error: true);
      _errorList.add('insertLog $e');
    } finally {
      changeStateLoading();
    }
  }
}
