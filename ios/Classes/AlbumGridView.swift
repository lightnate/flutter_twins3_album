import Flutter
import UIKit
import Photos
import PhotosUI

/** flutter端方法名称 */
enum FlutterMethodName: String {
    case onReady
    case onSelectImage
    case onSelectAlbum
}

class FLAlbumGridViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let _args = args as! Dictionary<String, Any>
        if _args["viewName"] is String {
            let viewName = _args["viewName"] as! String
            if viewName.contains("assetView") {
                return AssetImageView(frame: frame, viewIdentifier: viewId, arguments: args, binaryMessenger: messenger)
            } else if viewName.contains("albumPreviewView") {
                return AlbumPreviewGridView(frame: frame, viewIdentifier: viewId, arguments: args, binaryMessenger: messenger)
            }
        }
        
        return AlbumGridView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
    
    /** 添加此函数才能接受到 args 参数 */
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class AlbumGridView: NSObject, FlutterPlatformView, FlutterStreamHandler, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver {
    
    var _eventChan: FlutterEventChannel!
    var _eventSink: FlutterEventSink?
    
    var _methodChan: FlutterMethodChannel!
    
    var _flutterResult: FlutterResult!
    
    var _args: Dictionary<String, Any>
    var _view: UIView = UIView()
    var _layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    var _gridView: UICollectionView
    var _tipView = UILabel()
    
    let _width = UIScreen.main.bounds.size.width //获取屏幕宽
    let _gridCellReuseIdentifier = "AlbumGridCellView"
    
    fileprivate let _imageManager = PHCachingImageManager()
    fileprivate var _thumbnailSize: CGSize!
    fileprivate var _previousPreheatRect = CGRect.zero
    
    var _curAssetList: PHFetchResult<PHAsset>! // 当前显示的图片列表
    var _allCollections: [PHAssetCollection] = []
    var _fetchOptions = PHFetchOptions()
    
    let _cellGap: CGFloat = 1 // cell 间距
    let _gridColCount: CGFloat = 3 // 网格每行数量
    
    var _selectedAssetIdentifierList: [String] = []
    var _maxCount = 9 // 可选照片数量
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        // 初始化view
        _gridView = UICollectionView(frame: CGRect.zero, collectionViewLayout: _layout)
        _fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // 获取可选图片数量值
        _args = args as! Dictionary<String, Any>
        if _args["maxCount"] is Int {
            let maxCount = _args["maxCount"] as! Int
            _maxCount = maxCount
        }
        
        super.init()
        
        // 初始化方法通道
        _methodChan = FlutterMethodChannel(name: "AlbumGridView", binaryMessenger: messenger!)
        _methodChan.setMethodCallHandler(methodCallHandler)
        
        // 初始化事件通道
        _eventChan = FlutterEventChannel(name: "twins3_album_event", binaryMessenger: messenger!)
        _eventChan.setStreamHandler(self)
        
        checkPhotoAuthorization {
            DispatchQueue.main.async {
                self.setAlbumData()
                self.setGridView()
                self.createNativeView(view: self._view)
                
                self._methodChan.invokeMethod(FlutterMethodName.onReady.rawValue, arguments: nil)
            }
        } error: { (status) in
            // 无相册权限
            DispatchQueue.main.async {
                self.showTipView()
            }
        }
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func view() -> UIView {
        return _view
    }
    
    func setAlbumData() {
        // 注册监听器
        PHPhotoLibrary.shared().register(self)
        
        _allCollections = Constants.getAllCollections()
        
        guard let firstAlbum = _allCollections.first else {
            return
        }
        
        // 获取第一个相册下图片
        let photos = PHAsset.fetchAssets(in: firstAlbum, options: _fetchOptions)
        _curAssetList = photos
    }
    
    func setGridView() {
        // 设置collectview代理和数据源
        _gridView.delegate = self
        _gridView.dataSource = self
        
        // 设置collectview允许多选
        _gridView.allowsMultipleSelection = true
        
        _gridView.backgroundColor = .transparent
        
        // 注册cell
        _gridView.register(AlbumGridCellView.self, forCellWithReuseIdentifier: _gridCellReuseIdentifier)
        
        // 设置cell横向间距
        _layout.minimumInteritemSpacing = _cellGap
        // 设置cell纵向间距
        _layout.minimumLineSpacing = _cellGap
        // 设置cell尺寸
        let sideLength = (_width - ((_gridColCount - 1) * _cellGap)) / _gridColCount
        _layout.itemSize = CGSize(width: sideLength, height: sideLength)
        // 设置缩略图尺寸
        let scale = UIScreen.main.scale
        let cellSize = _layout.itemSize
        _thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    }
    
    func createNativeView(view _view: UIView){
        _view.addSubview(_gridView)
        
        // 设置约束
        _gridView.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: _gridView, attribute: .top, relatedBy: .equal, toItem: _view, attribute: .top, multiplier:1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: _gridView, attribute: .bottom, relatedBy: .equal, toItem: _view, attribute: .bottom, multiplier:1.0, constant: 0)
        let left = NSLayoutConstraint(item: _gridView, attribute: .left, relatedBy: .equal, toItem: _view, attribute: .left, multiplier:1.0, constant: 0)
        let right = NSLayoutConstraint(item: _gridView, attribute: .right, relatedBy: .equal, toItem: _view, attribute:.right, multiplier:1.0, constant: 0)
        _gridView.superview?.addConstraint(top)
        _gridView.superview?.addConstraint(bottom)
        _gridView.superview?.addConstraint(left)
        _gridView.superview?.addConstraint(right)
    }
    
    func showTipView() {
        
        let infoDictionary = Bundle.main.infoDictionary!
        let appDisplayName = infoDictionary["CFBundleDisplayName"] ?? "" //程序名称
        _tipView.text = "无法访问相册，请在设置->隐私->照片中，允许\(appDisplayName)访问手机相册。"
        _tipView.numberOfLines = 0
        _tipView.textAlignment = .center
        _tipView.font = UIFont.boldSystemFont(ofSize: 17)
        if #available(iOS 13.0, *) {
            _tipView.textColor = .b20
        } else {
            _tipView.textColor = .b_20
        }
        _view.addSubview(_tipView)
        
        // 设置约束
        _tipView.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: _tipView, attribute: .top, relatedBy: .equal, toItem: _view, attribute: .top, multiplier:1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: _tipView, attribute: .bottom, relatedBy: .equal, toItem: _view, attribute: .bottom, multiplier:1.0, constant: 0)
        let left = NSLayoutConstraint(item: _tipView, attribute: .left, relatedBy: .equal, toItem: _view, attribute: .left, multiplier:1.0, constant: 32)
        let right = NSLayoutConstraint(item: _tipView, attribute: .right, relatedBy: .equal, toItem: _view, attribute:.right, multiplier:1.0, constant: -32)
        _tipView.superview?.addConstraint(top)
        _tipView.superview?.addConstraint(bottom)
        _tipView.superview?.addConstraint(left)
        _tipView.superview?.addConstraint(right)
    }
    
    // MARK: PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        debugPrint("photoLibraryDidChange")
    }
    
    // MARK: UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _curAssetList?.count ?? 0;
    }
    
    // 渲染cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = _curAssetList.object(at: indexPath.item)
        // Dequeue a GridViewCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: _gridCellReuseIdentifier, for: indexPath) as? AlbumGridCellView
            else { fatalError("Unexpected cell in collection view") }
        
        // 滚动时重新设置是否选择，防止顺序错乱
        if _selectedAssetIdentifierList.contains(asset.localIdentifier) {
            cell.textLabel = "\(_selectedAssetIdentifierList.firstIndex(of: asset.localIdentifier)! + 1)"
            cell.isChose = true
        } else {
            cell.textLabel = nil
            cell.isChose = false
            
            // 达到最大可选数量时，设置未被选中图片的不可选图层
            if _selectedAssetIdentifierList.count == _maxCount {
                cell.selectable = false
            }
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.representedAssetIdentifier = asset.localIdentifier
        _imageManager.requestImage(for: asset, targetSize: _thumbnailSize, contentMode: .aspectFit, options: nil, resultHandler: { image, _ in
            // UIKit may have recycled this cell by the handler's activation time.
            // Set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        })
        
        return cell
    }
    
    // 选中cell，isSelected会设置为true
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect(collectionView: collectionView, indexPath: indexPath)
    }
    
    // 取消选中cell，isSelected会设置为false
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        onSelect(collectionView: collectionView, indexPath: indexPath)
    }
    
    func onSelect(collectionView: UICollectionView, indexPath: IndexPath) {
        let asset = _curAssetList.object(at: indexPath.item)
        guard let cell = collectionView.cellForItem(at: indexPath) as? AlbumGridCellView
            else { fatalError("Unexpected cell in collection view") }
        
        if cell.isChose {
            let idx = _selectedAssetIdentifierList.firstIndex(of: asset.localIdentifier)!
            // 移除选中的图片索引
            _selectedAssetIdentifierList.remove(at: idx)
            cell.textLabel = nil
            cell.isChose = false

            // 重新设置其他选中图片的选中顺序
            for (index, identifier) in _selectedAssetIdentifierList.enumerated() {
                for (_, item) in collectionView.visibleCells.enumerated() {
                    let c = item as! AlbumGridCellView
                    if c.representedAssetIdentifier == identifier {
                        c.textLabel = "\(index + 1)"
                    }
                }
            }
            
        } else {
            // 不超过可选图片数量
            if _selectedAssetIdentifierList.count < _maxCount {
                // 保存选中的图片索引
                _selectedAssetIdentifierList.append(asset.localIdentifier)
                // 设置选中顺序
                cell.textLabel = "\(_selectedAssetIdentifierList.endIndex)"
                cell.isChose = true
            }
        }
        
        // 当前选择数量等于可选数量时，设置不可选图层
        for c in _gridView.visibleCells {
            let cell = c as! AlbumGridCellView
            if _selectedAssetIdentifierList.count == _maxCount && !cell.isChose && cell.selectable {
                cell.selectable = false
            }
            if _selectedAssetIdentifierList.count < _maxCount && !cell.selectable {
                cell.selectable = true
            }
        }
        
        // 触发flutter回调
        _methodChan.invokeMethod(FlutterMethodName.onSelectImage.rawValue, arguments: _selectedAssetIdentifierList)
    }
    
    // MARK: UIScrollView

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    // MARK: Asset Caching
    
    fileprivate func resetCachedAssets() {
        _imageManager.stopCachingImagesForAllAssets()
        _previousPreheatRect = .zero
    }
    /// - Tag: UpdateAssets
    fileprivate func updateCachedAssets() {
        
        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: _gridView.contentOffset, size: _gridView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - _previousPreheatRect.midY)
        guard delta > _view.bounds.height / 3 else { return }
        
        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(_previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in _gridView.indexPathsForElements(in: rect) }
            .map { indexPath in _curAssetList.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in _gridView.indexPathsForElements(in: rect) }
            .map { indexPath in _curAssetList.object(at: indexPath.item) }
        
        
        // Update the assets the PHCachingImageManager is caching.
        _imageManager.startCachingImages(for: addedAssets,
                                        targetSize: _thumbnailSize, contentMode: .aspectFit, options: nil)
        _imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: _thumbnailSize, contentMode: .aspectFit, options: nil)
        // Store the computed rectangle for future comparison.
        _previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}

extension AlbumGridView {
    // MARK: Flutter Method
    
    // 监听 flutter 方法调用
    func methodCallHandler(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if _flutterResult == nil {
            _flutterResult = result
        }
        
        if call.method == "getFirstAlbumInfo" {
            getFirstAlbumInfo()
        } else if call.method == "getAssetList" {
            getAssetList(args: call.arguments)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    /** 切换显示的相册 */
    func getAssetList(args: Any?) {
        guard args != nil, let localIdentifier = args else {
            return
        }
        
        if localIdentifier is String {
            let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier as! String], options: nil)
            
            guard let firstObj = fetchResult.firstObject else {
                return
            }
            
            let photos = PHAsset.fetchAssets(in: firstObj, options: _fetchOptions)
            _curAssetList = photos
            _gridView.reloadData()
        }
    }
    
    /** 获取第一个相册信息 */
    func getFirstAlbumInfo() {
        guard let collection = _allCollections.first else {
            _flutterResult(nil)
            return
        }

        var dict = Dictionary<String, Any>()
        dict["localIdentifier"] = collection.localIdentifier
        dict["name"] = collection.localizedTitle
        _flutterResult(dict)
    }
    
    // MARK: FlutterStreamHandler
    
    /** flutter 端开启监听回调 */
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        debugPrint("onlisten")
        self._eventSink = events
        return nil
    }
    
    /** flutter 端取消监听回调 */
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        debugPrint("oncancel")
        return nil
    }
}
