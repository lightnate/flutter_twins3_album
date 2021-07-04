import 'dart:async';

import 'package:flutter/services.dart';

class MyChannel {
  static const _methodChan = const MethodChannel('twins3_album');
  static const _eventChan = const EventChannel('twins3_album_event');

  static StreamSubscription<dynamic> _stream;

  static Future<List<dynamic>> getAlbumList() async {
    List<dynamic> list;
    try {
      list = await _methodChan.invokeMethod('getAlbumList');
    } on PlatformException catch (e) {
      list = [];
    }

    return list;
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
