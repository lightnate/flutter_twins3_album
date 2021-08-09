class AlbumGridCellView: UICollectionViewCell {
    
    var imageView: UIImageView!
    var representedAssetIdentifier: String!
    var isChose = false
    private var selectedCoverView: UIView?
    private var selectedLabel: UILabel?
    private var unselectableCoverView: UIView?
    
    let radius: CGFloat = 12
    
    override init(frame: CGRect) {
        selectable = true
        
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
    
    var selectable: Bool {
        didSet {
            if selectable {
                unselectableCoverView?.removeFromSuperview()
                unselectableCoverView = nil
            } else {
                unselectableCoverView = UIView(frame: CGRect(origin: CGPoint.zero, size: frame.size))
                unselectableCoverView?.backgroundColor = .white_99
                addSubview(unselectableCoverView!)
            }
        }
    }
    
    var textLabel: String! {
        didSet {
            if textLabel != nil {
                selectedCoverView?.removeFromSuperview()
                selectedLabel?.removeFromSuperview()

                selectedCoverView = UIView(frame: CGRect(origin: CGPoint.zero, size: frame.size))
                selectedCoverView?.backgroundColor = .primary_99
                addSubview(selectedCoverView!)

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
                selectedCoverView?.removeFromSuperview()
                selectedLabel?.removeFromSuperview()
                selectedCoverView = nil
                selectedLabel = nil
            }

        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        isChose = false
        selectable = true
    }
    
}
