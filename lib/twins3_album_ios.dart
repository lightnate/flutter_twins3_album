import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum Twins3AlbumViewName {
  gridView,
  assetView,
}

class Twins3AlbumView extends StatelessWidget {
  const Twins3AlbumView({
    Key key,
    this.maxCount = 9,
    this.viewName = Twins3AlbumViewName.gridView,
    this.assetLocalIdentifier,
  }) : super(key: key);

  final Twins3AlbumViewName viewName;

  /// 当viewName 为 assetView时，图片的唯一标志
  final String assetLocalIdentifier;

  /// 可选图片数量
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    final String viewType = 'twins3_album_view';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};
    creationParams['maxCount'] = maxCount;
    creationParams['viewName'] = viewName.toString();
    creationParams['assetLocalIdentifier'] = assetLocalIdentifier;

    // 平台检测
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      default:
        throw UnsupportedError("Unsupported platform view");
    }
  }
}
