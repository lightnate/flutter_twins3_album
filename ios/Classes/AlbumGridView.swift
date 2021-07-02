import Flutter
import UIKit
import Photos
import PhotosUI

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
        return AlbumGridView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class AlbumGridView: NSObject, FlutterPlatformView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver {
    
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
    let gridRowCount: CGFloat = 3 // 网格每行数量

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        // 初始化
        _gridView = UICollectionView(frame: CGRect.zero, collectionViewLayout: _layout)
        
        super.init()
        
        setAlbumData()
        setGridView()
        createNativeView(view: _view)
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
        // 注册cell
        _gridView.register(AlbumGridCellView.self, forCellWithReuseIdentifier: _gridCellReuseIdentifier)
        
        // 设置cell横向间距
        _layout.minimumInteritemSpacing = cellGap
        // 设置cell纵向间距
        _layout.minimumLineSpacing = cellGap
        // 设置cell尺寸
        let sideLength = (_width - ((gridRowCount - 1) * cellGap)) / gridRowCount
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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = allPhotos.object(at: indexPath.item)
        // Dequeue a GridViewCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: _gridCellReuseIdentifier, for: indexPath) as? AlbumGridCellView
            else { fatalError("Unexpected cell in collection view") }
        
        // Add a badge to the cell if the PHAsset represents a Live Photo.
        if #available(iOS 9.1, *) {
            if asset.mediaSubtypes.contains(.photoLive) {
                cell.livePhotoBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
            }
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath)
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

class AlbumGridCellView: UICollectionViewCell {
    
    var imageView: UIImageView!
    var livePhotoBadgeImageView: UIImageView!
    var representedAssetIdentifier: String!
    var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: frame.size))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        livePhotoBadgeImageView = UIImageView(frame: CGRect(x: 40, y: 0, width: 10, height: 10))
        addSubview(imageView)
//        addSubview(livePhotoBadgeImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    var livePhotoBadgeImage: UIImage! {
        didSet {
            livePhotoBadgeImageView.image = livePhotoBadgeImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        livePhotoBadgeImageView.image = nil
    }
    
}
