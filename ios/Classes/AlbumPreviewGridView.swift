import Photos

class AlbumPreviewGridView: NSObject, FlutterPlatformView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var _methodChan: FlutterMethodChannel!
    var _flutterResult: FlutterResult!
    
    var _args: Dictionary<String, Any>
    var _view: UIView = UIView()
    var _layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    var _gridView: UICollectionView
    
    let _width = UIScreen.main.bounds.size.width //获取屏幕宽
    let _gridCellReuseIdentifier = "AlbumPreviewGridCellView"
    
    var _allCollections: [PHAssetCollection] = []
    var _fetchOptions = PHFetchOptions()
    
    var _isFirstRender = false
    
    fileprivate let _imageManager = PHCachingImageManager()
    fileprivate var _thumbnailSize: CGSize!
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        // 初始化view
        _gridView = UICollectionView(frame: CGRect.zero, collectionViewLayout: _layout)
        _args = args as! Dictionary<String, Any>
        _fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        super.init()
        
        // 初始化方法通道
        _methodChan = FlutterMethodChannel(name: "AlbumPreviewGridView", binaryMessenger: messenger!)
        _methodChan.setMethodCallHandler(methodCallHandler)
        
        setGridView()
        setAlbumData()
        createNativeView(view: _view)
    }
    
    func view() -> UIView {
        return _view
    }
    
    func setAlbumData() {
        _allCollections = Constants.getAllCollections()
    }
    
    func setGridView() {
        // 设置collectview代理和数据源
        _gridView.delegate = self
        _gridView.dataSource = self
        
        // 设置collectview多选
        _gridView.allowsMultipleSelection = false
        
        _gridView.backgroundColor = .transparent
        
        // 注册cell
        _gridView.register(AlbumPreviewGridCellView.self, forCellWithReuseIdentifier: _gridCellReuseIdentifier)
        
        // 设置cell横向间距
        _layout.minimumInteritemSpacing = 1
        // 设置cell纵向间距
        _layout.minimumLineSpacing = 1
        // 设置cell尺寸
        _layout.itemSize = CGSize(width: _width, height: 106)
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
        _view.addConstraint(top)
        _view.addConstraint(bottom)
        _view.addConstraint(left)
        _view.addConstraint(right)
    }
    
    // MARK: UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _allCollections.count
    }
    
    // 渲染cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // 首次渲染默认选择第一个
        if !_isFirstRender && indexPath.item == 0 {
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
            _isFirstRender = true
        }
        
        let collection = _allCollections[indexPath.item]
        // Dequeue a GridViewCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: _gridCellReuseIdentifier, for: indexPath) as? AlbumPreviewGridCellView
            else { fatalError("Unexpected cell in collection view") }
        
        // 获取图片数据，按最新排序
        let fetchResult = PHAsset.fetchAssets(in: collection, options: _fetchOptions)
        
        cell.representedAssetIdentifier = collection.localIdentifier
        let name = Constants.kAlbumNameToCHN[collection.localizedTitle ?? ""]
        cell.albunName = name ?? collection.localizedTitle
        cell.assetCount = "\(fetchResult.count)"
        
        guard fetchResult.firstObject != nil else {
            return cell
        }
        
        // 显示第一张图片作为封面
        _imageManager.requestImage(for: fetchResult.firstObject!, targetSize: _thumbnailSize, contentMode: .aspectFit, options: nil, resultHandler: { image, _ in
            // UIKit may have recycled this cell by the handler's activation time.
            // Set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == collection.localIdentifier {
                cell.thumbnailImage = image
            }
        })
        
        return cell
    }
    
    // 选中cell，isSelected会设置为true
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let collection = _allCollections[indexPath.item]
        
        // 触发flutter回调
        var dict = Dictionary<String, Any>()
        dict["localIdentifier"] = collection.localIdentifier
        dict["name"] = collection.localizedTitle
        _methodChan.invokeMethod(FlutterMethodName.onSelectAlbum.rawValue, arguments: dict)
    }
    
    // 取消选中cell，isSelected会设置为false
//    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//    }
    
    // 设置按住高亮
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? AlbumPreviewGridCellView else {
            fatalError("Unexpected cell in collection view")
        }
        cell.backgroundColor = .b_60
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? AlbumPreviewGridCellView else {
            fatalError("Unexpected cell in collection view")
        }
        cell.backgroundColor = .transparent
    }
}

class AlbumPreviewGridCellView: UICollectionViewCell {
    
    var imageView: UIImageView!
    var representedAssetIdentifier: String!
    private var selectedIcon: UIImageView!
    private var albumNameLabel: UILabel!
    private var assetCountLabel: UILabel!
    
    let radius: CGFloat = 12
    let imgSize: CGFloat = 72
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        // 封面图
        imageView = UIImageView()
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addConstraint(NSLayoutConstraint(item: imageView!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier:1.0, constant: imgSize))
        imageView.addConstraint(NSLayoutConstraint(item: imageView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier:1.0, constant: imgSize))
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraint(NSLayoutConstraint(item: imageView!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier:1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: imageView!, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier:1.0, constant: 16))
        
        // 相册名称label
        albumNameLabel = UILabel()
        if #available(iOS 13.0, *) {
            albumNameLabel.textColor = .b20
        } else {
            albumNameLabel.textColor = .b_20
        }
        albumNameLabel.font = UIFont.boldSystemFont(ofSize: 17)
        addSubview(albumNameLabel)
        albumNameLabel.translatesAutoresizingMaskIntoConstraints = false

        self.addConstraint(NSLayoutConstraint(item: albumNameLabel!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier:1.0, constant: -8))
        self.addConstraint(NSLayoutConstraint(item: albumNameLabel!, attribute: .left, relatedBy: .equal, toItem: imageView, attribute: .right, multiplier:1.0, constant: 32))
        
        // 相册数量label
        assetCountLabel = UILabel()
        if #available(iOS 13.0, *) {
            assetCountLabel.textColor = .b60
        } else {
            assetCountLabel.textColor = .b_60
        }
        assetCountLabel.font = UIFont.boldSystemFont(ofSize: 13)
        addSubview(assetCountLabel)
        assetCountLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraint(NSLayoutConstraint(item: assetCountLabel!, attribute: .top, relatedBy: .equal, toItem: albumNameLabel, attribute: .bottom, multiplier:1.0, constant: 4))
        self.addConstraint(NSLayoutConstraint(item: assetCountLabel!, attribute: .left, relatedBy: .equal, toItem: albumNameLabel, attribute: .left, multiplier:1.0, constant: 0))

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    var albunName: String! {
        didSet {
            albumNameLabel.text = albunName
        }
    }
    
    var assetCount: String! {
        didSet {
            assetCountLabel.text = assetCount
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                selectedIcon?.removeFromSuperview()

                let diameter: CGFloat = 24

                selectedIcon = UIImageView()
                selectedIcon.contentMode = .scaleAspectFill
                selectedIcon.clipsToBounds = true
                selectedIcon?.image = UIImage(data: Constants.kSelectedIcon!)
                addSubview(selectedIcon!)
                
                selectedIcon.translatesAutoresizingMaskIntoConstraints = false
                selectedIcon.addConstraint(NSLayoutConstraint(item: selectedIcon!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier:1.0, constant: diameter))
                selectedIcon.addConstraint(NSLayoutConstraint(item: selectedIcon!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier:1.0, constant: diameter))
                self.addConstraint(NSLayoutConstraint(item: selectedIcon!, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier:1.0, constant: -16))
                self.addConstraint(NSLayoutConstraint(item: selectedIcon!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier:1.0, constant: 0))
            } else {
                selectedIcon?.removeFromSuperview()
                selectedIcon = nil
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        selectedIcon = nil
    }
    
}

extension AlbumPreviewGridView {
    // MARK: Flutter Method
    
    // 监听 flutter 方法调用
    func methodCallHandler(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if _flutterResult == nil {
            _flutterResult = result
        }
        
//        if call.method == "getAlbumList" {
//            getAlbumList()
//        } else if call.method == "getAssetList" {
//            getAssetList(args: call.arguments)
//        } else {
//            result(FlutterMethodNotImplemented)
//        }
        result(FlutterMethodNotImplemented)
    }
}
