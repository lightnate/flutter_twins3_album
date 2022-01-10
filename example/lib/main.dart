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
      // Twins3AlbumChannel.getAlbumList().then((value) {
      //   print(value);
      // });

      Twins3AlbumChannel.setMethodCallHandler({
        PlatformMethodName.onSelectImage: (args) {
          print(args);
        },
        PlatformMethodName.onSelectAlbum: (args) {
          print(args);
          Twins3AlbumChannel.getAssetList(args);
        },
      });
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
            Container(
              width: double.maxFinite,
              height: 500,
              child: Twins3AlbumView(
                viewName: Twins3AlbumViewName.albumPreviewView,
              ),
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
