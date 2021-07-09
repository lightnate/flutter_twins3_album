import Photos

class AssetImageView: NSObject, FlutterPlatformView {
    
    var _args: Dictionary<String, Any>
    var _view: UIView = UIView()
    var _imageView = UIImageView()
    
    fileprivate let _imageManager = PHCachingImageManager()
    fileprivate var _thumbnailSize: CGSize!
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _args = args as! Dictionary<String, Any>
        super.init()
        
        createNativeView(view: _view)
    }
    
    func view() -> UIView {
        return _view
    }
    
    func createNativeView(view _view: UIView){
        _view.addSubview(_imageView)
        
        _imageView.contentMode = .scaleAspectFill
        _imageView.backgroundColor = .transparent
        // 设置约束
        _imageView.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: _imageView, attribute: .top, relatedBy: .equal, toItem: _view, attribute: .top, multiplier:1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: _imageView, attribute: .bottom, relatedBy: .equal, toItem: _view, attribute: .bottom, multiplier:1.0, constant: 0)
        let left = NSLayoutConstraint(item: _imageView, attribute: .left, relatedBy: .equal, toItem: _view, attribute: .left, multiplier:1.0, constant: 0)
        let right = NSLayoutConstraint(item: _imageView, attribute: .right, relatedBy: .equal, toItem: _view, attribute:.right, multiplier:1.0, constant: 0)
        _imageView.superview?.addConstraint(top)
        _imageView.superview?.addConstraint(bottom)
        _imageView.superview?.addConstraint(left)
        _imageView.superview?.addConstraint(right)
        
        // 设置缩略图尺寸
        let scale = UIScreen.main.scale
        let cellSize = 72
        _thumbnailSize = CGSize(width: 72 * scale, height: 72 * scale)
        
        if _args["assetLocalIdentifier"] is String {
            let assetLocalIdentifier = _args["assetLocalIdentifier"] as! String
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetLocalIdentifier], options: nil)
            
            guard let asset = fetchResult.firstObject else {
                return
            }
            _imageManager.requestImage(for: asset, targetSize: _thumbnailSize, contentMode: .aspectFit, options: nil) { (image, _) in
                self._imageView.image = image
            }
        }
    }
}
