import 'dart:async';

import 'package:flutter/services.dart';

enum PlatformMethodName { onSelectImage }

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

class AlbumModel {
  AlbumModel(
    this.title,
    this.count,
    this.firstImgUri,
    this.localIdentifier,
    this.firstAssetLocalIdentifier,
  );

  final String title;
  final int count;
  final String firstImgUri;
  final String localIdentifier;
  final String firstAssetLocalIdentifier;

  static AlbumModel fromJson(dynamic json) {
    return AlbumModel(
      json['title'] as String,
      json['count'] as int,
      json['firstImgUri'] as String,
      json['localIdentifier'] as String,
      json['firstAssetLocalIdentifier'] as String,
    );
  }
}

class Twins3AlbumChannel {
  static const _methodChan = const MethodChannel('twins3_album');
  static const _eventChan = const EventChannel('twins3_album_event');

  static StreamSubscription<dynamic> _stream;

  /// 获取相册列表名称
  static Future<List<AlbumModel>> getAlbumList() async {
    List<AlbumModel> albumList = [];
    try {
      final list =
          await _methodChan.invokeMethod<List<dynamic>>('getAlbumList');
      if (list != null) {
        albumList = list.map(AlbumModel.fromJson).toList();
      }
    } on PlatformException catch (e) {}
    return albumList;
  }

  /// 根据相册 localIdentifier 显示相册图片
  static Future<void> getAssetList(String localIdentifier) async {
    try {
      await _methodChan.invokeMethod('getAssetList', localIdentifier);
    } on PlatformException catch (e) {}
  }

  /// 监听原生方法
  static void setMethodCallHandler(Map<PlatformMethodName, Function> handler) {
    _methodChan.setMethodCallHandler((call) async {
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
