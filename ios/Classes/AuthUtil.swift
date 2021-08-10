import Photos

func checkPhotoAuthorization(authorized: @escaping () -> Void, error: @escaping (_ status: PHAuthorizationStatus) -> Void) {
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
    case .notDetermined:
        PHPhotoLibrary.requestAuthorization { (status) in
            if #available(iOS 14, *) {
                if status == .authorized || status == .limited {
                    authorized()
                } else {
                    error(status)
                }
            } else {
                if status == .authorized {
                    authorized()
                } else {
                    error(status)
                }
            }
            
        }
    case .authorized, .limited:
        authorized()
    case .denied, .restricted:
        error(status)
    default:
        error(status)
    }
}
