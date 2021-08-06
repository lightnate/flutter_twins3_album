import Photos
import PhotosUI

class Constants {
    static let kAlbumNames: [String] = [
        "Recents", // 最近项目
        "Favorites", // 个人收藏
//        "Videos", // 视频
        "Selfies", // 自拍
        "Live Photos", // 实况照片
        "Portrait", // 人像
        "Long Exposure", // 长曝光
        "Panoramas", // 全景照片
//        "Time-lapse", // 延时摄影
        "Slo-mo", // 慢动作
        "Bursts", // 连拍快照
        "Screenshots", // 截屏
        "Animated", // 动图

//        "Hidden", // 已隐藏
//        "Recently Deleted", // 最近删除
//        "Recently Added", // 最近添加
//        "Unable to Upload", // 母鸡
    ]
    
    static let kAlbumNameToCHN:Dictionary<String, String> = [
        "Panoramas" : "全景照片" ,
        "Videos" : "视频" ,
        "Favorites" : "个人收藏" ,
        "Time-lapse" : "延时摄影" ,
        "Hidden" : "已隐藏" ,
        "Recently Deleted" : "最近删除" ,
        "Recents" : "最近项目" ,
        "Bursts" : "连拍快照" ,
        "Slo-mo" : "慢动作" ,
        "Recently Added" : "最近添加" ,
        "Selfies" : "自拍" ,
        "Screenshots" : "截屏" ,
        "Portrait" : "人像" ,
        "Live Photos" : "实况照片" ,
        "Animated" : "动图" ,
        "Long Exposure" : "长曝光" ,
        "Unable to Upload" : "母鸡" ,
    ]
    
    /**
     获取所有相册
     */
    class func getAllCollections() -> [PHAssetCollection] {
        var _allCollections: [PHAssetCollection] = []
        
        // 获取相册信息
        let _smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        let _userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        
        _smartAlbums.enumerateObjects { (collection, index, _) in
            // 筛选需要的智能相册
            // 筛选有图片的相册
            let fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
            let name = collection.localizedTitle ?? ""
            if fetchResult.count > 0 && kAlbumNames.contains(name) {
                _allCollections.append(collection)
            }
        }
        
        _userCollections.enumerateObjects { (collection, index, _) in
            let fetchResult = PHAsset.fetchAssets(in: collection as! PHAssetCollection, options: nil)
            if fetchResult.count > 0 {
                _allCollections.append(collection as! PHAssetCollection)
            }
            
        }
        
        // 按照kAlbumNames 顺序排序
        for (sort, albumName) in kAlbumNames.enumerated() {
            for (index, collection) in _allCollections.enumerated() {
                let name = collection.localizedTitle ?? ""
                if albumName == name {
                    if sort + 1 < _allCollections.count {
                        let r = _allCollections.remove(at: index)
                        _allCollections.insert(r, at: sort)
                    } else {
                        
                    }
                    break
                }
            }
        }

        return _allCollections
    }
    
    static let kSelectedIcon = Data(base64Encoded: "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")
    
}
