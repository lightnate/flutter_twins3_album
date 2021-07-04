import Flutter
import UIKit

public class SwiftTwins3AlbumPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    
    // 注册消息通道
    let channel = FlutterMethodChannel(name: "twins3_album", binaryMessenger: registrar.messenger())
    let instance = SwiftTwins3AlbumPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // 注册相册view
    let factory = FLAlbumGridViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "twins3_album_view")
    
    // 监听 flutter 方法调用
    channel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        
        guard call.method == "getAlbumList" else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        
        factory.getAlbumList(result: result)
    })
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
