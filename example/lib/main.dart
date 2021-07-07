import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:twins3_album/twins3_album.dart';
import 'package:twins3_album/twins3_album_channel.dart';
import 'package:twins3_album/twins3_album_ios.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _url = "";

  @override
  void initState() {
    super.initState();
    // initPlatformState();

    var timer = Timer(Duration(seconds: 1), () {
      Twins3AlbumChannel.getAlbumList().then((value) {
        print(value);
      });

      Twins3AlbumChannel.setMethodCallHandler({
        PlatformMethodName.onSelectImage: (args) {
          if (args is String) {
            final file = File(args);
            file.exists().then((value) => print(value));
            setState(() {
              _url = args;
            });
          }
        }
      });
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Twins3Album.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
            child: Column(
          children: [
            Image.file(
              File(_url),
              width: 100,
              height: 100,
            ),
            Expanded(
              child: Twins3AlbumView(),
            )
          ],
        )),
      ),
    );
  }
}
