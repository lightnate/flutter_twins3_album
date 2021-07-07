class AlbumGridCellView: UICollectionViewCell {
    
    var imageView: UIImageView!
    var representedAssetIdentifier: String!
    var isChose = false
    private var coverView: UIView?
    private var selectedLabel: UILabel?
    
    let radius: CGFloat = 12
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: frame.size))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    var textLabel: String! {
        didSet {
            if textLabel != nil {
                coverView?.removeFromSuperview()
                selectedLabel?.removeFromSuperview()

                coverView = UIView(frame: CGRect(origin: CGPoint.zero, size: frame.size))
                coverView?.backgroundColor = .primary_99
                addSubview(coverView!)

                let diameter = radius * 2

                selectedLabel = UILabel(frame: CGRect(origin: CGPoint(x: frame.width - 6 - diameter, y: 6), size: CGSize(width: diameter, height: diameter)))
                selectedLabel?.layer.cornerRadius = radius
                selectedLabel?.clipsToBounds = true
                selectedLabel?.backgroundColor = .white
                selectedLabel?.textColor = .primary
                selectedLabel?.text = textLabel
                selectedLabel?.textAlignment = .center

                addSubview(selectedLabel!)
            } else {
                coverView?.removeFromSuperview()
                selectedLabel?.removeFromSuperview()
                coverView = nil
                selectedLabel = nil
            }

        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        isChose = false
    }
    
}
