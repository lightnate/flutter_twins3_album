import MobileCoreServices

enum FLTImagePickerMIMEType: Int {
    case FLTImagePickerMIMETypePNG = 0
    case FLTImagePickerMIMETypeJPEG
    case FLTImagePickerMIMETypeGIF
    case FLTImagePickerMIMETypeOther
}

class PhotoAssetUtil {
    
    static let kFLTImagePickerDefaultSuffix = ".jpg";
    static let kFLTImagePickerMIMETypeDefault: FLTImagePickerMIMEType = .FLTImagePickerMIMETypeJPEG;
    
    class func saveImageWithOriginalImageData(data: Data?,
                                              image: UIImage,
                                              maxWdith: Double,
                                              maxHeight: Double,
                                              imageQuality: Double)
    {
//        NSString *suffix = kFLTImagePickerDefaultSuffix;
//          FLTImagePickerMIMEType type = kFLTImagePickerMIMETypeDefault;
//          NSDictionary *metaData = nil;
//          // Getting the image type from the original image data if necessary.
//          if (originalImageData) {
//            type = [FLTImagePickerMetaDataUtil getImageMIMETypeFromImageData:originalImageData];
//            suffix =
//                [FLTImagePickerMetaDataUtil imageTypeSuffixFromType:type] ?: kFLTImagePickerDefaultSuffix;
//            metaData = [FLTImagePickerMetaDataUtil getMetaDataFromImageData:originalImageData];
//          }
//          if (type == FLTImagePickerMIMETypeGIF) {
//            GIFInfo *gifInfo = [FLTImagePickerImageUtil scaledGIFImage:originalImageData
//                                                              maxWidth:maxWidth
//                                                             maxHeight:maxHeight];
//
//            return [self saveImageWithMetaData:metaData gifInfo:gifInfo suffix:suffix];
//          } else {
//            return [self saveImageWithMetaData:metaData
//                                         image:image
//                                        suffix:suffix
//                                          type:type
//                                  imageQuality:imageQuality];
//          }
        
        var suffix = kFLTImagePickerDefaultSuffix
        var type = kFLTImagePickerMIMETypeDefault
        var metaData = [String: Any]()
        if data != nil {
            type = FLTImagePickerMetaDataUtil.getImageMIMETypeFromImageData(data: data!)
            suffix = FLTImagePickerMetaDataUtil.imageTypeSuffixFromType(type: type)
            metaData = FLTImagePickerMetaDataUtil.getMetaDataFromImageData(data: data!) ?? [String: Any]()
        }
    }
    
    class func createFile(data: Data?, suffix: String) -> String? {
        if data != nil {
            let tmpPath = temporaryFilePath(suffix: suffix)
            let fileManager = FileManager.default
            let ok = fileManager.createFile(atPath: tmpPath, contents: data, attributes: nil)
            if ok {
                return tmpPath
            } else {
                return nil
            }
        }
        return nil
    }
    
    class func temporaryFilePath(suffix: String) -> String {
        let guid = ProcessInfo.processInfo.globallyUniqueString
        let tmpFile = "twins3_album_\(guid)\(suffix)"
        let tmpDirectory = NSTemporaryDirectory()
        let tmpPath = tmpDirectory.appending(tmpFile)
        return tmpPath;
    }
}

class FLTImagePickerMetaDataUtil {
    static let kFirstByteJPEG: UInt8 = 0xFF;
    static let kFirstBytePNG: UInt8 = 0x89;
    static let kFirstByteGIF: UInt8 = 0x47;
    
    class func getImageMIMETypeFromImageData(data: Data) -> FLTImagePickerMIMEType {
        let firstByte = data.first
        if firstByte != nil {
            switch firstByte {
            case kFirstByteJPEG:
                return .FLTImagePickerMIMETypeJPEG
            case kFirstBytePNG:
                return .FLTImagePickerMIMETypePNG
            case kFirstByteGIF:
                return .FLTImagePickerMIMETypeGIF
            default:
                return .FLTImagePickerMIMETypeOther
            }
        } else {
            return .FLTImagePickerMIMETypeOther
        }
    }
    
    class func imageTypeSuffixFromType(type: FLTImagePickerMIMEType) -> String {
        switch type {
        case .FLTImagePickerMIMETypeJPEG:
            return ".jpg"
        case .FLTImagePickerMIMETypePNG:
            return ".png"
        case .FLTImagePickerMIMETypeGIF:
            return ".gif"
        default:
            return ""
        }
    }
    
    class func getMetaDataFromImageData(data: Data) -> Dictionary<String, Any>? {
        let source = CGImageSourceCreateWithData(data as CFData, nil)
        if source != nil {
            let metadata = CGImageSourceCopyPropertiesAtIndex(source!, 0, nil)
            return metadata as? Dictionary<String, Any>
        } else {
            return nil
        }
        
    }
}
