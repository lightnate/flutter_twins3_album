import 'dart:async';

import 'package:flutter/services.dart';

// 原生事件枚举
enum PlatformMethodName {
  /// 选择图片
  onSelectImage,

  /// 选择相册
  onSelectAlbum,
}

/// 字符串转枚举
T stringToEnum<T>(List<T> enumList, String name) {
  T result;
  for (var i = 0; i < enumList.length; i++) {
    if (enumList[i].toString().contains(name)) {
      result = enumList[i];
      break;
    }
  }
  return result;
}

/// 相册信息model
class AlbumInfoModel {
  AlbumInfoModel(
    this.localIdentifier,
    this.name,
  );

  final String localIdentifier;
  final String name;

  static AlbumInfoModel fromJson(dynamic json) {
    return AlbumInfoModel(
      json['localIdentifier'] as String,
      json['name'] as String,
    );
  }
}

class Twins3AlbumChannel {
  static const _methodChanAlbumGridView = const MethodChannel('AlbumGridView');
  static const _methodChanAlbumPreviewGridView =
      const MethodChannel('AlbumPreviewGridView');
  static const _eventChan = const EventChannel('twins3_album_event');

  static StreamSubscription<dynamic> _stream;

  /// 获取相册列表名称
  static Future<AlbumInfoModel> getFirstAlbumInfo() async {
    AlbumInfoModel albumInfo;
    try {
      final result =
          await _methodChanAlbumGridView.invokeMethod('getFirstAlbumInfo');
      if (result != null) {
        albumInfo = AlbumInfoModel.fromJson(result);
      }
    } on PlatformException catch (e) {}
    return albumInfo;
  }

  /// 根据相册 localIdentifier 显示相册图片
  static Future<void> getAssetList(String localIdentifier) async {
    try {
      await _methodChanAlbumGridView.invokeMethod(
          'getAssetList', localIdentifier);
    } on PlatformException catch (e) {}
  }

  /// 监听原生方法
  static void setMethodCallHandler(Map<PlatformMethodName, Function> handler) {
    _methodChanAlbumGridView.setMethodCallHandler((call) async {
      final name = stringToEnum<PlatformMethodName>(
          PlatformMethodName.values, call.method);
      if (name != null) {
        if (handler.containsKey(name)) {
          handler[name](call.arguments);
        }
      }
    });
    _methodChanAlbumPreviewGridView.setMethodCallHandler((call) async {
      final name = stringToEnum<PlatformMethodName>(
          PlatformMethodName.values, call.method);
      if (name != null) {
        if (handler.containsKey(name)) {
          handler[name](call.arguments);
        }
      }
    });
  }

  static void startEventListener(void Function(dynamic) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    _stream = _eventChan.receiveBroadcastStream().listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
  }

  static void cancelEventListner() {
    if (_stream != null) {
      _stream.cancel();
      _stream = null;
    }
  }
}
