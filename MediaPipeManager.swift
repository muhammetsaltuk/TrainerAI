import Foundation
import SVProgressHUD

class MediaPipeManager {
    
    static let shared = MediaPipeManager()
    
    private init() {}
    
    // MARK: - Model Paths
    
    // Local path for pose model
    private let poseModelName = "pose_landmarker.task"
    
    // MARK: - Public Methods
    
    /// Ensures that the pose model exists locally, downloads it if needed
    func ensurePoseModelExists(completion: @escaping (Bool) -> Void) {
        // Check if model already exists
        let localPath = getLocalModelPath(for: poseModelName)
        
        if FileManager.default.fileExists(atPath: localPath) {
            print("Pose model already exists locally at path: \(localPath)")
            completion(true)
            return
        }
        
        print("Pose model not found locally, attempting to download...")
        
        // If not, download it
        downloadPoseModel { success in
            if success {
                print("Model downloaded successfully")
            } else {
                print("Model download failed")
            }
            completion(success)
        }
    }
    
    /// Returns the path to the pose model
    func getPoseModelPath() -> String? {
        let localPath = getLocalModelPath(for: poseModelName)
        
        if FileManager.default.fileExists(atPath: localPath) {
            return localPath
        }
        
        print("Pose model not found at path: \(localPath)")
        return nil
    }
    
    // MARK: - Private Methods
    
    private func getLocalModelPath(for modelName: String) -> String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelUrl = documentsDirectory.appendingPathComponent(modelName)
        let path = modelUrl.path
        print("Local model path: \(path)")
        return path
    }
    
    private func downloadPoseModel(completion: @escaping (Bool) -> Void) {
        // Display progress indicator
        DispatchQueue.main.async {
            SVProgressHUD.show(withStatus: "Model indiriliyor...")
        }
        
        // Try with the lite model first, it's smaller and loads faster
        let modelUrls = [
            "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task",
            "https://storage.googleapis.com/mediapipe-assets/pose_landmarker_lite.task"
        ]
        
        downloadModelWithFallback(urls: modelUrls, currentIndex: 0, completion: completion)
    }
    
    private func downloadModelWithFallback(urls: [String], currentIndex: Int, completion: @escaping (Bool) -> Void) {
        guard currentIndex < urls.count else {
            print("Tüm indirme adresleri denendi ve başarısız oldu")
            DispatchQueue.main.async {
                SVProgressHUD.showError(withStatus: "Model indirilemedi")
            }
            completion(false)
            return
        }
        
        let modelUrlString = urls[currentIndex]
        print("Model indirme deneniyor: \(modelUrlString)")
        
        guard let modelUrl = URL(string: modelUrlString) else {
            print("Geçersiz model URL: \(modelUrlString)")
            downloadModelWithFallback(urls: urls, currentIndex: currentIndex + 1, completion: completion)
            return
        }
        
        let destinationPath = getLocalModelPath(for: poseModelName)
        let destinationUrl = URL(fileURLWithPath: destinationPath)
        
        // Create a URLSession download task with better timeout settings
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        
        let session = URLSession(configuration: config)
        
        let downloadTask = session.downloadTask(with: modelUrl) { tempFileUrl, response, error in
            if let error = error {
                print("İndirme hatası: \(error.localizedDescription)")
                // Try the next URL
                self.downloadModelWithFallback(urls: urls, currentIndex: currentIndex + 1, completion: completion)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("İndirme yanıt kodu: \(httpResponse.statusCode)")
                
                if !(200...299).contains(httpResponse.statusCode) {
                    print("Sunucu hata kodu döndü: \(httpResponse.statusCode)")
                    // Try the next URL
                    self.downloadModelWithFallback(urls: urls, currentIndex: currentIndex + 1, completion: completion)
                    return
                }
            }
            
            guard let tempFileUrl = tempFileUrl else {
                print("İndirme başarısız: Geçici dosya URL'si yok")
                // Try the next URL
                self.downloadModelWithFallback(urls: urls, currentIndex: currentIndex + 1, completion: completion)
                return
            }
            
            print("Model geçici dosyaya indirildi: \(tempFileUrl.path)")
            
            // Move the file to the destination
            do {
                // Create directories if needed
                try FileManager.default.createDirectory(at: destinationUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
                
                // If a file already exists at the destination, remove it
                if FileManager.default.fileExists(atPath: destinationPath) {
                    try FileManager.default.removeItem(at: destinationUrl)
                }
                
                // Move the downloaded file to the destination
                try FileManager.default.moveItem(at: tempFileUrl, to: destinationUrl)
                
                print("Model indirme başarılı: \(destinationPath)")
                print("İndirme sonrası dosya varlığı: \(FileManager.default.fileExists(atPath: destinationPath))")
                
                if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: destinationPath),
                   let fileSize = fileAttributes[.size] as? NSNumber {
                    print("Dosya boyutu: \(fileSize.intValue) bytes")
                    if fileSize.intValue < 1000 { // File is too small, probably not valid
                        print("Dosya çok küçük, geçerli bir model olmayabilir")
                        try? FileManager.default.removeItem(at: destinationUrl)
                        self.downloadModelWithFallback(urls: urls, currentIndex: currentIndex + 1, completion: completion)
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                }
                completion(true)
            } catch {
                print("İndirilen dosyayı kaydetme hatası: \(error.localizedDescription)")
                // Try the next URL
                self.downloadModelWithFallback(urls: urls, currentIndex: currentIndex + 1, completion: completion)
            }
        }
        
        // Start the download
        downloadTask.resume()
    }
} 