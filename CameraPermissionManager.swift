import AVFoundation

class CameraPermissionManager {
    
    static let shared = CameraPermissionManager()
    
    private init() {}
    
    func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera
            completion(true)
            
        case .notDetermined:
            // The user has not yet been asked for camera access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            // The user has previously denied access, or access is restricted
            completion(false)
            
        @unknown default:
            // Future-proofing against future authorization status values
            completion(false)
        }
    }
} 