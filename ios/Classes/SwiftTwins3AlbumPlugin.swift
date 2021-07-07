import Flutter
import UIKit

public class SwiftTwins3AlbumPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {

    // 注册相册view
    let factory = FLAlbumGridViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "twins3_album_view")
  }
}
