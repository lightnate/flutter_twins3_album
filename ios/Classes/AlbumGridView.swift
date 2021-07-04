import Flutter
import UIKit
import Photos
import PhotosUI

class FLAlbumGridViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var albumGridView: AlbumGridView!

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        
        albumGridView = AlbumGridView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
        return albumGridView
    }
    
    /** 添加此函数才能接受到 args 参数 */
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
    
    func getAlbumList(result: FlutterResult) {
        if albumGridView != nil {
            albumGridView.getAlbumList(result: result)
        } else {
            print("GG")
        }
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class AlbumGridView: NSObject, FlutterPlatformView, FlutterStreamHandler, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver {
    
    var eventChan: FlutterEventChannel!
    var eventSink: FlutterEventSink?
    
    var _view: UIView = UIView()
    var _layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    var _gridView: UICollectionView
    
    let _width = UIScreen.main.bounds.size.width //获取屏幕宽
    let _gridCellReuseIdentifier = "AlbumGridCellView"
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    
    // MARK: Properties
    var allPhotos: PHFetchResult<PHAsset>!
    var smartAlbums: PHFetchResult<PHAssetCollection>!
    var userCollections: PHFetchResult<PHCollection>!
    let sectionLocalizedTitles = ["", NSLocalizedString("Smart Albums", comment: ""), NSLocalizedString("Albums", comment: "")]
    
    let cellGap: CGFloat = 1 // cell 间距
    let gridColCount: CGFloat = 3 // 网格每行数量
    
    var selectedPhotoIndexPathList: [IndexPath] = []
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        // 初始化view
        _gridView = UICollectionView(frame: CGRect.zero, collectionViewLayout: _layout)
        
        super.init()
        
        // 初始化事件通道
        eventChan = FlutterEventChannel(name: "twins3_album_event", binaryMessenger: messenger!)
        eventChan.setStreamHandler(self)
        
        setAlbumData()
        setGridView()
        createNativeView(view: _view)
        
        print(args)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func view() -> UIView {
        return _view
    }
    
    func setAlbumData() {

        // 获取相册信息
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        PHPhotoLibrary.shared().register(self)
    }
    
    func setGridView() {
        // 设置collectview代理和数据源
        _gridView.delegate = self
        _gridView.dataSource = self
        
        // 设置collectview允许多选
        _gridView.allowsMultipleSelection = true
        
        _gridView.backgroundColor = .white
        
        // 注册cell
        _gridView.register(AlbumGridCellView.self, forCellWithReuseIdentifier: _gridCellReuseIdentifier)
        
        // 设置cell横向间距
        _layout.minimumInteritemSpacing = cellGap
        // 设置cell纵向间距
        _layout.minimumLineSpacing = cellGap
        // 设置cell尺寸
        let sideLength = (_width - ((gridColCount - 1) * cellGap)) / gridColCount
        _layout.itemSize = CGSize(width: sideLength, height: sideLength)
        // 设置缩略图尺寸
        let scale = UIScreen.main.scale
        let cellSize = _layout.itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
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
    
    // MARK: PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
    }
    
    // MARK: UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allPhotos.count;
    }
    
    // 渲染cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = allPhotos.object(at: indexPath.item)
        // Dequeue a GridViewCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: _gridCellReuseIdentifier, for: indexPath) as? AlbumGridCellView
            else { fatalError("Unexpected cell in collection view") }
        
        // 滚动时重新设置是否选择，防止顺序错乱
        if cell.isSelected && selectedPhotoIndexPathList.contains(indexPath) {
            cell.textLabel = "\(selectedPhotoIndexPathList.firstIndex(of: indexPath)! + 1)"
        } else {
            cell.textLabel = nil
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFit, options: nil, resultHandler: { image, _ in
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
        let cell = collectionView.cellForItem(at: indexPath) as! AlbumGridCellView
        // 保存选中的图片索引
        selectedPhotoIndexPathList.append(indexPath)
        // 设置选中顺序
        cell.textLabel = "\(selectedPhotoIndexPathList.endIndex)"
        
        eventSink?("???")
    }
    
    // 取消选中cell，isSelected会设置为false
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! AlbumGridCellView
        let idx = selectedPhotoIndexPathList.firstIndex(of: indexPath)!
        // 移除选中的图片索引
        selectedPhotoIndexPathList.remove(at: idx)
        cell.textLabel = nil

        // 重新设置其他选中图片的选中顺序
        for (index, item) in selectedPhotoIndexPathList.enumerated() {
            let c = collectionView.cellForItem(at: item) as! AlbumGridCellView
            c.textLabel = "\(index + 1)"
        }
    }
    
    // MARK: UIScrollView

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    // MARK: Asset Caching
    
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    /// - Tag: UpdateAssets
    fileprivate func updateCachedAssets() {
        
        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: _gridView.contentOffset, size: _gridView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > _view.bounds.height / 3 else { return }
        
        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in _gridView.indexPathsForElements(in: rect) }
            .map { indexPath in allPhotos.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in _gridView.indexPathsForElements(in: rect) }
            .map { indexPath in allPhotos.object(at: indexPath.item) }
        
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFit, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFit, options: nil)
        // Store the computed rectangle for future comparison.
        previousPreheatRect = preheatRect
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
    
    func getAlbumList(result: FlutterResult) {
        var list: [String] = []
        smartAlbums.enumerateObjects { (collection, int, _) in
            list.append(collection.localizedTitle ?? "")
        }
        result(list)
    }
    
    // MARK: FlutterStreamHandler
    
    /** flutter 端开启监听回调 */
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        debugPrint("onlisten")
        self.eventSink = events
        return nil
    }
    
    /** flutter 端取消监听回调 */
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        debugPrint("oncancel")
        return nil
    }
}
