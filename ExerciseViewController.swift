import UIKit
import AVFoundation
import MediaPipeTasksVision
import SVProgressHUD

class ExerciseViewController: UIViewController {
    
    // MARK: - Properties
    
    var selectedExercise: Exercise?
    var completionHandler: (() -> Void)?
    private var captureSession: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var poseLandmarker: PoseLandmarker?
    private var lastPoseTimestamp: TimeInterval = 0
    
    private var repCount = 0
    private var currentStage = "Down"
    private var progressPercentage: Float = 0.0
    
    private var isReady: Bool = false
    private var countdownTimer: Timer?
    private var countdownSeconds: Int = 5
    
    // MARK: - UI Elements
    
    private let repCountLabel: UILabel = {
        let label = UILabel()
        label.text = "TEKRAR: 0"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stageLabel: UILabel = {
        let label = UILabel()
        label.text = "DURUM: Aşağı"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressBarBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressBarFill: UIView = {
        let view = UIView()
        view.backgroundColor = .green
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "MediaPipe modeli yükleniyor..."
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let debugButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Kamera Testi", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0.7
        return button
    }()
    
    private var progressBarHeightConstraint: NSLayoutConstraint?
    
    private let countdownOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let countdownLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let phoneAdviceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let finishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Bitir", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showCountdownOverlay()
        // Show loading state while we set up MediaPipe
        showLoading(true, message: "Kamera ve model hazırlanıyor...")
        // First, check for camera permission
        checkCameraPermissionsAndSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCaptureSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopCaptureSession()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        title = selectedExercise?.name ?? "Egzersiz"
        view.backgroundColor = .black
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        
        // Replik sayısı etiketi
        repCountLabel.text = "TEKRAR: 0"
        
        // Durum etiketi
        stageLabel.text = "DURUM: Aşağı"
        
        // Yükleme etiketi
        loadingLabel.text = "MediaPipe modeli yükleniyor..."
        
        // Add UI elements to view hierarchy
        view.addSubview(overlayView)
        view.addSubview(progressBarBackground)
        progressBarBackground.addSubview(progressBarFill)
        view.addSubview(repCountLabel)
        view.addSubview(stageLabel)
        
        // Add loading view
        view.addSubview(loadingView)
        loadingView.addSubview(loadingLabel)
        
        // Add debug button
        view.addSubview(debugButton)
        
        // Add countdown overlay
        view.addSubview(countdownOverlay)
        countdownOverlay.addSubview(countdownLabel)
        countdownOverlay.addSubview(phoneAdviceLabel)
        
        // Add finish button
        view.addSubview(finishButton)
        
        // Configure layout constraints
        NSLayoutConstraint.activate([
            // Overlay view for drawing landmarks
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Rep count label at the top
            repCountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            repCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            repCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Stage label below rep count
            stageLabel.topAnchor.constraint(equalTo: repCountLabel.bottomAnchor, constant: 10),
            stageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Progress bar background on the left side
            progressBarBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressBarBackground.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressBarBackground.widthAnchor.constraint(equalToConstant: 30),
            progressBarBackground.heightAnchor.constraint(equalToConstant: 300),
            
            // Progress bar fill (starts at bottom)
            progressBarFill.leadingAnchor.constraint(equalTo: progressBarBackground.leadingAnchor),
            progressBarFill.trailingAnchor.constraint(equalTo: progressBarBackground.trailingAnchor),
            progressBarFill.bottomAnchor.constraint(equalTo: progressBarBackground.bottomAnchor),
            progressBarFill.widthAnchor.constraint(equalTo: progressBarBackground.widthAnchor),
            
            // Loading view (covers the entire screen)
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading label centered in loading view
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
            
            // Debug button at the bottom right
            debugButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            debugButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            debugButton.widthAnchor.constraint(equalToConstant: 120),
            debugButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Countdown overlay
            countdownOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            countdownOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            countdownOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            countdownOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            countdownLabel.centerXAnchor.constraint(equalTo: countdownOverlay.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: countdownOverlay.centerYAnchor, constant: -40),
            phoneAdviceLabel.topAnchor.constraint(equalTo: countdownLabel.bottomAnchor, constant: 24),
            phoneAdviceLabel.leadingAnchor.constraint(equalTo: countdownOverlay.leadingAnchor, constant: 32),
            phoneAdviceLabel.trailingAnchor.constraint(equalTo: countdownOverlay.trailingAnchor, constant: -32),
            
            // Finish button
            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            finishButton.widthAnchor.constraint(equalToConstant: 180),
            finishButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // Create height constraint for progress bar fill (initially 0%)
        progressBarHeightConstraint = progressBarFill.heightAnchor.constraint(equalToConstant: 0)
        progressBarHeightConstraint?.isActive = true
        
        // Add action to debug button
        debugButton.addTarget(self, action: #selector(debugButtonTapped), for: .touchUpInside)
        
        // Add action to finish button
        finishButton.addTarget(self, action: #selector(finishTapped), for: .touchUpInside)
    }
    
    private func checkCameraPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Camera permission already granted, proceed with MediaPipe setup
            print("Kamera izni daha önce verilmiş. Kamera ve MediaPipe kuruluyor.")
            setupMediaPipeAndCamera()
            
        case .notDetermined:
            // The user has not yet been asked for camera access
            print("Kamera izni henüz istenmemiş. İzin isteniyor.")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        print("Kamera izni verildi. Kamera kuruluyor.")
                        self?.setupMediaPipeAndCamera()
                    } else {
                        print("Kamera izni reddedildi.")
                        self?.showLoading(false, message: "")
                        self?.showAlert(title: "Kamera İzni Gerekli", message: "Bu uygulama egzersiz takibi yapabilmek için kamera erişimine ihtiyaç duyar.")
                    }
                }
            }
            
        case .denied, .restricted:
            // The user has previously denied access, or access is restricted
            print("Kamera izni daha önce reddedilmiş veya kısıtlanmış.")
            showLoading(false, message: "")
            let alert = UIAlertController(
                title: "Kamera İzni Gerekli",
                message: "Bu uygulama kamera erişimi olmadan çalışamaz. Lütfen Ayarlar > Gizlilik > Kamera yolunu izleyerek TrainerAI için izin verin.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Ayarlar'ı Aç", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
            
            alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
            present(alert, animated: true)
            
        @unknown default:
            print("Kamera izni için bilinmeyen durum.")
            showLoading(false, message: "")
            showAlert(title: "Kamera Hatası", message: "Kamera erişim durumu belirlenemedi.")
        }
    }
    
    private func setupMediaPipeAndCamera() {
        // Ensure the pose model exists (downloads if needed)
        MediaPipeManager.shared.ensurePoseModelExists { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.setupMediaPipe()
                    
                    // Start camera after model is loaded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.setupCameraCapture()
                        self?.showLoading(false)
                    }
                } else {
                    self?.showLoading(false)
                    self?.showAlert(title: "Model Error", message: "Failed to load MediaPipe model. Please check your internet connection and try again.")
                }
            }
        }
    }
    
    private func setupMediaPipe() {
        guard let modelPath = MediaPipeManager.shared.getPoseModelPath() else {
            print("MediaPipe model not found.")
            showAlert(title: "Model Hatası", message: "MediaPipe modeli bulunamadı. Tekrar indirmeyi deneyin.")
            return
        }
        
        print("Setting up MediaPipe with model at: \(modelPath)")
        
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .video
        options.numPoses = 1
        
        do {
            poseLandmarker = try PoseLandmarker(options: options)
            print("PoseLandmarker initialized successfully")
        } catch {
            print("Failed to initialize pose landmarker: \(error)")
            SVProgressHUD.showError(withStatus: "Pose algılayıcı başlatılamadı")
            showAlert(title: "Model Hatası", message: "Pose algılayıcı başlatılamadı: \(error.localizedDescription)")
        }
    }
    
    private func setupCameraCapture() {
        print("Kamera kurulumu başlatılıyor...")
        
        // Reset any existing session
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
        
        captureSession = AVCaptureSession()
        
        // Use high resolution preset for better pose detection
        captureSession?.beginConfiguration()
        if captureSession?.canSetSessionPreset(.high) == true {
            captureSession?.sessionPreset = .high
        }
        
        // Try to get the front camera first, fall back to back camera if needed
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        )
        
        let devices = deviceDiscoverySession.devices
        print("Bulunan kamera cihazları: \(devices.count)")
        
        guard let camera = devices.first ?? AVCaptureDevice.default(for: .video) else {
            print("Kamera bulunamadı")
            DispatchQueue.main.async { [weak self] in
                self?.showLoading(false, message: "")
                self?.showAlert(title: "Kamera Hatası", message: "Cihazınızda kullanılabilir bir kamera bulunamadı.")
            }
            return
        }
        
        print("Kullanılacak kamera: \(camera.localizedName)")
        
        do {
            // Configure camera for better results
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                try camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.unlockForConfiguration()
            }
            
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
                print("Kamera girişi eklendi")
            } else {
                print("Kamera girişi eklenemedi")
                throw NSError(domain: "com.trainerai.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kamera girişi eklenemedi"])
            }
            
            // Setup video data output
            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput?.alwaysDiscardsLateVideoFrames = true
            videoDataOutput?.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            
            let videoQueue = DispatchQueue(label: "com.trainerai.videoQueue", qos: .userInteractive)
            videoDataOutput?.setSampleBufferDelegate(self, queue: videoQueue)
            
            if let videoDataOutput = videoDataOutput, captureSession?.canAddOutput(videoDataOutput) == true {
                captureSession?.addOutput(videoDataOutput)
                print("Video çıkışı eklendi")
                
                // Configure video connection
                if let connection = videoDataOutput.connection(with: .video) {
                    // Set video orientation for all iOS versions
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                    
                    // Enable video mirroring for front camera
                    if camera.position == .front && connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
            } else {
                print("Video çıkışı eklenemedi")
                throw NSError(domain: "com.trainerai.error", code: 2, userInfo: [NSLocalizedDescriptionKey: "Video çıkışı eklenemedi"])
            }
            
            captureSession?.commitConfiguration()
            
            // Setup preview layer on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Create and configure preview layer
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
                self.previewLayer?.videoGravity = .resizeAspectFill
                self.previewLayer?.frame = self.view.layer.bounds
                
                // Add preview layer to view
                if let previewLayer = self.previewLayer {
                    self.view.layer.insertSublayer(previewLayer, at: 0)
                    print("Preview layer ekrana eklendi")
                }
                
                // Start capture session
                self.startCaptureSession()
                
                // Hide loading overlay
                self.showLoading(false, message: "")
            }
            
        } catch {
            print("Kamera kurulum hatası: \(error.localizedDescription)")
            
            DispatchQueue.main.async { [weak self] in
                self?.showLoading(false, message: "")
                self?.showAlert(title: "Kamera Hatası", message: "Kamera kurulumu başarısız: \(error.localizedDescription)")
            }
        }
    }
    
    private func startCaptureSession() {
        // Check if already running
        guard let captureSession = captureSession, !captureSession.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("Kamera oturumu başlatılıyor...")
            captureSession.startRunning()
            
            DispatchQueue.main.async {
                print("Kamera oturumu çalışıyor: \(captureSession.isRunning)")
                if !captureSession.isRunning {
                    print("Kamera başlatılamadı!")
                }
            }
        }
    }
    
    private func stopCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    private func showLoading(_ show: Bool, message: String = "") {
        loadingView.isHidden = !show
        loadingLabel.text = message
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showCountdownOverlay() {
        isReady = false
        countdownSeconds = 5
        countdownOverlay.isHidden = false
        countdownLabel.text = "5"
        phoneAdviceLabel.text = selectedExercise?.phoneAdvice ?? "Telefonunuzu sabit bir yere, tüm vücudunuzun görüneceği şekilde yerleştirin."
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
    }
    
    @objc private func updateCountdown() {
        countdownSeconds -= 1
        if countdownSeconds > 0 {
            countdownLabel.text = "\(countdownSeconds)"
        } else {
            countdownTimer?.invalidate()
            countdownOverlay.isHidden = true
            isReady = true
        }
    }
    
    // MARK: - Pose Analysis
    
    private func processVideoFrame(pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) {
        guard let poseLandmarker = poseLandmarker else { return }
        if !isReady { return } // Wait for countdown to finish
        
        do {
            let mpImage = try MPImage(pixelBuffer: pixelBuffer)
            
            // Process the frame with MediaPipe
            let poseResult = try poseLandmarker.detect(videoFrame: mpImage, timestampInMilliseconds: Int(timestamp * 1000))
            
            DispatchQueue.main.async { [weak self] in
                self?.handlePoseResults(poseResult, timestamp: timestamp)
                self?.drawPoseLandmarks(poseResult)
            }
        } catch {
            print("Error processing video frame: \(error)")
        }
    }
    
    private func handlePoseResults(_ poseResult: PoseLandmarkerResult, timestamp: TimeInterval) {
        guard !poseResult.landmarks.isEmpty else {
            return
        }
        
        let landmarks = poseResult.landmarks[0]
        
        switch selectedExercise?.name {
        case "Biceps Curl":
            analyzeBicepsCurl(landmarks: landmarks)
        case "Şınav":
            analyzePushup(landmarks: landmarks)
        case "Squat":
            analyzeSquat(landmarks: landmarks)
        case "Lunge":
            analyzeLunge(landmarks: landmarks)
        case "Plank":
            analyzePlank(landmarks: landmarks)
        case "Burpee":
            analyzeBurpee(landmarks: landmarks)
        case "Mountain Climber":
            analyzeMountainClimber(landmarks: landmarks)
        case "Glute Bridge":
            analyzeGluteBridge(landmarks: landmarks)
        case "Leg Raises":
            analyzeLegRaises(landmarks: landmarks)
        default:
            break
        }
    }
    
    private func analyzeBicepsCurl(landmarks: [NormalizedLandmark]) {
        guard landmarks.count >= 16,
              landmarks.indices.contains(11),
              landmarks.indices.contains(13),
              landmarks.indices.contains(15) else {
            return
        }
        
        let leftShoulder = landmarks[11]
        let leftElbow = landmarks[13]
        let leftWrist = landmarks[15]
        
        let angle = calculateAngle(
            a: CGPoint(x: CGFloat(leftShoulder.x), y: CGFloat(leftShoulder.y)),
            b: CGPoint(x: CGFloat(leftElbow.x), y: CGFloat(leftElbow.y)),
            c: CGPoint(x: CGFloat(leftWrist.x), y: CGFloat(leftWrist.y))
        )
        
        updateProgressBar(angle: angle)
        countReps(angle: angle)
    }
    
    private func analyzePushup(landmarks: [NormalizedLandmark]) {
        guard landmarks.count >= 16,
              landmarks.indices.contains(11),
              landmarks.indices.contains(13),
              landmarks.indices.contains(15) else {
            return
        }
        
        let leftShoulder = landmarks[11]
        let leftElbow = landmarks[13]
        let leftWrist = landmarks[15]
        
        let angle = calculateAngle(
            a: CGPoint(x: CGFloat(leftShoulder.x), y: CGFloat(leftShoulder.y)),
            b: CGPoint(x: CGFloat(leftElbow.x), y: CGFloat(leftElbow.y)),
            c: CGPoint(x: CGFloat(leftWrist.x), y: CGFloat(leftWrist.y))
        )
        
        updateProgressBar(angle: angle)
        countReps(angle: angle)
    }
    
    private func analyzeSquat(landmarks: [NormalizedLandmark]) {
        guard landmarks.count >= 33,
              landmarks.indices.contains(23),
              landmarks.indices.contains(25),
              landmarks.indices.contains(27) else {
            return
        }
        
        let leftHip = landmarks[23]
        let leftKnee = landmarks[25]
        let leftAnkle = landmarks[27]
        
        let angle = calculateAngle(
            a: CGPoint(x: CGFloat(leftHip.x), y: CGFloat(leftHip.y)),
            b: CGPoint(x: CGFloat(leftKnee.x), y: CGFloat(leftKnee.y)),
            c: CGPoint(x: CGFloat(leftAnkle.x), y: CGFloat(leftAnkle.y))
        )
        
        updateProgressBar(angle: angle)
        countReps(angle: angle)
    }
    
    private func analyzeLunge(landmarks: [NormalizedLandmark]) {
        guard landmarks.count >= 33,
              landmarks.indices.contains(23),
              landmarks.indices.contains(25),
              landmarks.indices.contains(27) else {
            return
        }
        
        let leftHip = landmarks[23]
        let leftKnee = landmarks[25]
        let leftAnkle = landmarks[27]
        
        let angle = calculateAngle(
            a: CGPoint(x: CGFloat(leftHip.x), y: CGFloat(leftHip.y)),
            b: CGPoint(x: CGFloat(leftKnee.x), y: CGFloat(leftKnee.y)),
            c: CGPoint(x: CGFloat(leftAnkle.x), y: CGFloat(leftAnkle.y))
        )
        
        updateProgressBar(angle: angle)
        countReps(angle: angle)
    }
    
    private func analyzePlank(landmarks: [NormalizedLandmark]) {
        guard landmarks.count >= 33,
              landmarks.indices.contains(11),
              landmarks.indices.contains(23),
              landmarks.indices.contains(25) else {
            return
        }
        
        let leftShoulder = landmarks[11]
        let leftHip = landmarks[23]
        let leftKnee = landmarks[25]
        
        let angle = calculateAngle(
            a: CGPoint(x: CGFloat(leftShoulder.x), y: CGFloat(leftShoulder.y)),
            b: CGPoint(x: CGFloat(leftHip.x), y: CGFloat(leftHip.y)),
            c: CGPoint(x: CGFloat(leftKnee.x), y: CGFloat(leftKnee.y))
        )
        
        updateProgressBar(angle: angle)
        countReps(angle: angle)
    }
    
    private func analyzeBurpee(landmarks: [NormalizedLandmark]) {
        guard landmarks.count >= 33,
              landmarks.indices.contains(11),
              landmarks.indices.contains(23),
              landmarks.indices.contains(25) else {
            return
        }
        
        let leftShoulder = landmarks[11]
        let leftHip = landmarks[23]
        let leftKnee = landmarks[25]
        
        let angle = calculateAngle(
            a: CGPoint(x: CGFloat(leftShoulder.x), y: CGFloat(leftShoulder.y)),
            b: CGPoint(x: CGFloat(leftHip.x), y: CGFloat(leftHip.y)),
            c: CGPoint(x: CGFloat(leftKnee.x), y: CGFloat(leftKnee.y))
        )
        
        updateProgressBar(angle: angle)
        countReps(angle: angle)
    }
    
    private func analyzeMountainClimber(landmarks: [NormalizedLandmark]) {
        guard landmarks.count >= 33,
              landmarks.indices.contains(23),
              landmarks.indices.contains(25),
              landmarks.indices.contains(27) else {
            return
        }
        
        let leftHip = landmarks[23]
        let leftKnee = landmarks[25]
        let leftAnkle = landmarks[27]
        
        let angle = calculateAngle(
            a: CGPoint(x: CGFloat(leftHip.x), y: CGFloat(leftHip.y)),
            b: CGPoint(x: CGFloat(leftKnee.x), y: CGFloat(leftKnee.y)),
            c: CGPoint(x: CGFloat(leftAnkle.x), y: CGFloat(leftAnkle.y))
        )
        
        updateProgressBar(angle: angle)
        countReps(angle: angle)
    }
    
    private func analyzeGluteBridge(landmarks: [NormalizedLandmark]) {
        guard landmarks.count >= 33,
              landmarks.indices.contains(23),
              landmarks.indices.contains(25),
              landmarks.indices.contains(27) else {
            return
        }
        
        let leftHip = landmarks[23]
        let leftKnee = landmarks[25]
        let leftAnkle = landmarks[27]
        
        let angle = calculateAngle(
            a: CGPoint(x: CGFloat(leftHip.x), y: CGFloat(leftHip.y)),
            b: CGPoint(x: CGFloat(leftKnee.x), y: CGFloat(leftKnee.y)),
            c: CGPoint(x: CGFloat(leftAnkle.x), y: CGFloat(leftAnkle.y))
        )
        
        updateProgressBar(angle: angle)
        countReps(angle: angle)
    }
    
    private func analyzeLegRaises(landmarks: [NormalizedLandmark]) {
        guard landmarks.count >= 33,
              landmarks.indices.contains(23),
              landmarks.indices.contains(25),
              landmarks.indices.contains(27) else {
            return
        }
        
        let leftHip = landmarks[23]
        let leftKnee = landmarks[25]
        let leftAnkle = landmarks[27]
        
        let angle = calculateAngle(
            a: CGPoint(x: CGFloat(leftHip.x), y: CGFloat(leftHip.y)),
            b: CGPoint(x: CGFloat(leftKnee.x), y: CGFloat(leftKnee.y)),
            c: CGPoint(x: CGFloat(leftAnkle.x), y: CGFloat(leftAnkle.y))
        )
        
        updateProgressBar(angle: angle)
        countReps(angle: angle)
    }
    
    private func calculateAngle(a: CGPoint, b: CGPoint, c: CGPoint) -> Double {
        // Calculate vectors
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let cb = CGPoint(x: b.x - c.x, y: b.y - c.y)
        
        // Calculate dot product
        let dot = ab.x * cb.x + ab.y * cb.y
        
        // Calculate magnitudes
        let magAB = sqrt(ab.x * ab.x + ab.y * ab.y)
        let magCB = sqrt(cb.x * cb.x + cb.y * cb.y)
        
        // Calculate angle in radians and convert to degrees
        let angleRadians = acos(dot / (magAB * magCB))
        let angleDegrees = angleRadians * 180.0 / .pi
        
        return angleDegrees
    }
    
    private func countReps(angle: Double) {
        switch selectedExercise?.name {
        case "Biceps Curl":
        if angle > 160 {
            if currentStage != "Down" {
                currentStage = "Down"
                stageLabel.text = "DURUM: Aşağı"
            }
        }
        if angle < 30 && currentStage == "Down" {
            repCount += 1
            currentStage = "Up"
            stageLabel.text = "DURUM: Yukarı"
                updateRepCount()
            }
            
        case "Şınav":
            if angle > 160 {
                if currentStage != "Down" {
                    currentStage = "Down"
                    stageLabel.text = "DURUM: Aşağı"
                }
            }
            if angle < 90 && currentStage == "Down" {
                repCount += 1
                currentStage = "Up"
                stageLabel.text = "DURUM: Yukarı"
                updateRepCount()
            }
            
        case "Squat":
            if angle > 160 {
                if currentStage != "Down" {
                    currentStage = "Down"
                    stageLabel.text = "DURUM: Aşağı"
                }
            }
            if angle < 90 && currentStage == "Down" {
                repCount += 1
                currentStage = "Up"
                stageLabel.text = "DURUM: Yukarı"
                updateRepCount()
            }
            
        case "Lunge":
            if angle > 160 {
                if currentStage != "Down" {
                    currentStage = "Down"
                    stageLabel.text = "DURUM: Aşağı"
                }
            }
            if angle < 90 && currentStage == "Down" {
                repCount += 1
                currentStage = "Up"
                stageLabel.text = "DURUM: Yukarı"
                updateRepCount()
            }
            
        case "Plank":
            if angle > 160 {
                if currentStage != "Down" {
                    currentStage = "Down"
                    stageLabel.text = "DURUM: Aşağı"
                }
            }
            if angle < 90 && currentStage == "Down" {
                repCount += 1
                currentStage = "Up"
                stageLabel.text = "DURUM: Yukarı"
                updateRepCount()
            }
            
        case "Burpee":
            if angle > 160 {
                if currentStage != "Down" {
                    currentStage = "Down"
                    stageLabel.text = "DURUM: Aşağı"
                }
            }
            if angle < 90 && currentStage == "Down" {
                repCount += 1
                currentStage = "Up"
                stageLabel.text = "DURUM: Yukarı"
                updateRepCount()
            }
            
        case "Mountain Climber":
            if angle > 160 {
                if currentStage != "Down" {
                    currentStage = "Down"
                    stageLabel.text = "DURUM: Aşağı"
                }
            }
            if angle < 90 && currentStage == "Down" {
                repCount += 1
                currentStage = "Up"
                stageLabel.text = "DURUM: Yukarı"
                updateRepCount()
            }
            
        case "Glute Bridge":
            if angle > 160 {
                if currentStage != "Down" {
                    currentStage = "Down"
                    stageLabel.text = "DURUM: Aşağı"
                }
            }
            if angle < 90 && currentStage == "Down" {
                repCount += 1
                currentStage = "Up"
                stageLabel.text = "DURUM: Yukarı"
                updateRepCount()
            }
            
        case "Leg Raises":
            if angle > 160 {
                if currentStage != "Down" {
                    currentStage = "Down"
                    stageLabel.text = "DURUM: Aşağı"
                }
            }
            if angle < 90 && currentStage == "Down" {
                repCount += 1
                currentStage = "Up"
                stageLabel.text = "DURUM: Yukarı"
                updateRepCount()
            }
            
        default:
            break
        }
        
        // Her egzersiz için tekrar hedefi kontrolü:
        let targetReps = (self.parent as? WorkoutSessionViewController)?.workout.exercises.first(where: { $0.exercise.name == selectedExercise?.name })?.reps ?? 10
        if repCount >= targetReps {
            finishButton.isHidden = false
        }
    }
    
    private func updateRepCount() {
            repCountLabel.text = "TEKRAR: \(repCount)"
            
            // Flash the rep count label to provide visual feedback
            UIView.animate(withDuration: 0.2, animations: {
                self.repCountLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.repCountLabel.transform = .identity
                }
            })
    }
    
    private func updateProgressBar(angle: Double) {
        var progress: Float = 0
        
        switch selectedExercise?.name {
        case "Biceps Curl":
        // Map angle from 0-180 to progress percentage (inverted, since smaller angle = more progress)
            progress = max(0, min(1, 1 - (Float(angle) / 180.0)))
            
        case "Şınav":
            // For pushups, we want to track the downward movement
            progress = max(0, min(1, Float(angle) / 180.0))
            
        case "Squat":
            // For squats, we want to track the downward movement
            progress = max(0, min(1, Float(angle) / 180.0))
            
        case "Lunge":
            // For lunges, we want to track the downward movement
            progress = max(0, min(1, Float(angle) / 180.0))
            
        case "Plank":
            // For planks, we want to maintain a straight line
            progress = max(0, min(1, 1 - abs(Float(angle) - 180.0) / 180.0))
            
        case "Burpee":
            // For burpees, we want to track the downward movement
            progress = max(0, min(1, Float(angle) / 180.0))
            
        case "Mountain Climber":
            // For mountain climbers, we want to track the leg movement
            progress = max(0, min(1, Float(angle) / 180.0))
            
        case "Glute Bridge":
            // For glute bridges, we want to track the upward movement
            progress = max(0, min(1, 1 - (Float(angle) / 180.0)))
            
        case "Leg Raises":
            // For leg raises, we want to track the upward movement
            progress = max(0, min(1, 1 - (Float(angle) / 180.0)))
            
        default:
            progress = 0
        }
        
        progressPercentage = progress
        
        // Update progress bar height
        if let constraint = progressBarHeightConstraint, let backgroundHeight = progressBarBackground.constraints.first(where: { $0.firstAttribute == .height })?.constant {
            constraint.constant = CGFloat(progressPercentage) * backgroundHeight
            UIView.animate(withDuration: 0.1) {
                self.view.layoutIfNeeded()
            }
            
            // Change color based on progress
            if progressPercentage < 0.3 {
                progressBarFill.backgroundColor = .red
            } else if progressPercentage < 0.7 {
                progressBarFill.backgroundColor = .orange
            } else {
                progressBarFill.backgroundColor = .green
            }
        }
    }
    
    private func drawPoseLandmarks(_ poseResult: PoseLandmarkerResult) {
        // Clear previous drawings
        overlayView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        guard !poseResult.landmarks.isEmpty else {
            return
        }
        
        let landmarks = poseResult.landmarks[0]
        let overlayBounds = overlayView.bounds
        
        // Define colors for different body parts
        let jointColor = UIColor.green.cgColor
        let leftArmColor = UIColor.red.cgColor
        let rightArmColor = UIColor.blue.cgColor
        let bodyColor = UIColor.yellow.cgColor
        
        // Draw landmarks as circles
        for (_, landmark) in landmarks.enumerated() {
            let normalizedX = CGFloat(landmark.x)
            let normalizedY = CGFloat(landmark.y)
            
            let pointX = normalizedX * overlayBounds.width
            let pointY = normalizedY * overlayBounds.height
            
            let circleLayer = CAShapeLayer()
            let circlePath = UIBezierPath(arcCenter: CGPoint(x: pointX, y: pointY),
                                         radius: 4,
                                         startAngle: 0,
                                         endAngle: 2 * .pi,
                                         clockwise: true)
            
            circleLayer.path = circlePath.cgPath
            circleLayer.fillColor = jointColor
            
            overlayView.layer.addSublayer(circleLayer)
        }
        
        // Draw connections between landmarks
        
        // Left arm (shoulder - elbow - wrist)
        if landmarks.count >= 16 {
            drawConnection(from: landmarks[11], to: landmarks[13], in: overlayBounds, color: leftArmColor)
            drawConnection(from: landmarks[13], to: landmarks[15], in: overlayBounds, color: leftArmColor)
            
            // Right arm (shoulder - elbow - wrist)
            drawConnection(from: landmarks[12], to: landmarks[14], in: overlayBounds, color: rightArmColor)
            drawConnection(from: landmarks[14], to: landmarks[16], in: overlayBounds, color: rightArmColor)
            
            // Shoulders
            drawConnection(from: landmarks[11], to: landmarks[12], in: overlayBounds, color: bodyColor)
        }
    }
    
    private func drawConnection(from startLandmark: NormalizedLandmark, to endLandmark: NormalizedLandmark, in bounds: CGRect, color: CGColor) {
        let startX = CGFloat(startLandmark.x) * bounds.width
        let startY = CGFloat(startLandmark.y) * bounds.height
        let endX = CGFloat(endLandmark.x) * bounds.width
        let endY = CGFloat(endLandmark.y) * bounds.height
        
        let lineLayer = CAShapeLayer()
        let linePath = UIBezierPath()
        
        linePath.move(to: CGPoint(x: startX, y: startY))
        linePath.addLine(to: CGPoint(x: endX, y: endY))
        
        lineLayer.path = linePath.cgPath
        lineLayer.strokeColor = color
        lineLayer.lineWidth = 3
        lineLayer.fillColor = nil
        
        overlayView.layer.addSublayer(lineLayer)
    }
    
    @objc private func debugButtonTapped() {
        let camerasAvailable = checkAvailableCameras()
        showCameraInfo()
    }
    
    private func checkAvailableCameras() -> Bool {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        let devices = discoverySession.devices
        var devicesInfo = "Bulunan kameralar:\n"
        
        if devices.isEmpty {
            devicesInfo += "Kamera bulunamadı"
        } else {
            for (index, device) in devices.enumerated() {
                devicesInfo += "[\(index+1)] \(device.localizedName) (\(device.position == .front ? "Ön" : "Arka"))\n"
            }
        }
        
        print(devicesInfo)
        return !devices.isEmpty
    }
    
    private func showCameraInfo() {
        var info = "Kamera Bilgileri:\n"
        info += "Kamera izin durumu: \(AVCaptureDevice.authorizationStatus(for: .video))\n"
        info += "Kamera oturumu oluşturuldu: \(captureSession != nil)\n"
        info += "Kamera oturumu çalışıyor: \(captureSession?.isRunning == true)\n"
        info += "Video çıkışı oluşturuldu: \(videoDataOutput != nil)\n"
        info += "Preview layer oluşturuldu: \(previewLayer != nil)\n"
        info += "Pose detector oluşturuldu: \(poseLandmarker != nil)\n"
        
        if let modelPath = MediaPipeManager.shared.getPoseModelPath() {
            info += "Model Dosyası: \(modelPath)\n"
            info += "Model mevcut: \(FileManager.default.fileExists(atPath: modelPath))\n"
            
            if FileManager.default.fileExists(atPath: modelPath),
               let attributes = try? FileManager.default.attributesOfItem(atPath: modelPath),
               let size = attributes[.size] as? Int {
                info += "Model boyutu: \(size) bytes\n"
            }
        } else {
            info += "Model bulunamadı\n"
        }
        
        print(info)
        
        let alert = UIAlertController(title: "Kamera Durum Bilgisi", message: info, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        alert.addAction(UIAlertAction(title: "Kamerayı Yeniden Başlat", style: .destructive) { [weak self] _ in
            self?.restartCamera()
        })
        present(alert, animated: true)
    }
    
    private func restartCamera() {
        // Stop and clean up existing session
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
        
        captureSession = nil
        videoDataOutput = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        
        // Show loading state
        showLoading(true, message: "Kamera yeniden başlatılıyor...")
        
        // Wait a moment and try again
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.setupCameraCapture()
        }
    }
    
    @objc private func finishTapped() {
        dismiss(animated: true) {
            self.completionHandler?()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ExerciseViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { 
            print("Could not get pixel buffer from sample buffer")
            return 
        }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        
        // Process frames at appropriate intervals for performance (15-30 FPS)
        if timestamp - lastPoseTimestamp > 0.03 { // ~30 FPS
            lastPoseTimestamp = timestamp
            
            // Debug camera is working
            if poseLandmarker == nil {
                print("Kamera çalışıyor, poseLandmarker nil")
                DispatchQueue.main.async { [weak self] in
                    self?.showLoading(false, message: "")
                }
            }
            
            processVideoFrame(pixelBuffer: pixelBuffer, timestamp: timestamp)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Frame dropped")
    }
} 