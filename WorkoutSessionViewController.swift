import UIKit

class WorkoutSessionViewController: UIViewController {
    let workout: SavedWorkout
    private var currentExerciseIndex = 0
    private var currentSet = 1
    
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private var isTracking = false
    
    init(workout: SavedWorkout) {
        self.workout = workout
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        showCurrentExercise()
        setupExitButton()
    }
    
    private func setupUI() {
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        detailLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailLabel)
        
        nextButton.setTitle("Başla", for: .normal)
        nextButton.backgroundColor = .systemGreen
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 12
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        view.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            detailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            detailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            nextButton.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 40),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 180),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupExitButton() {
        let exitButton = UIButton(type: .system)
        exitButton.setTitle("Çık", for: .normal)
        exitButton.setTitleColor(.systemRed, for: .normal)
        exitButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
        view.addSubview(exitButton)
        NSLayoutConstraint.activate([
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            exitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func showCurrentExercise() {
        guard currentExerciseIndex < workout.exercises.count else {
            titleLabel.text = "Tebrikler!"
            detailLabel.text = "Antrenmanı tamamladınız."
            nextButton.setTitle("Kapat", for: .normal)
            return
        }
        let item = workout.exercises[currentExerciseIndex]
        titleLabel.text = item.exercise.name
        detailLabel.text = "Set: \(currentSet)/\(item.sets)\nTekrar: \(item.reps)"
        nextButton.setTitle(currentSet == 1 ? "Başla" : "Sonraki Set", for: .normal)
        isTracking = false
    }
    
    @objc private func nextTapped() {
        guard currentExerciseIndex < workout.exercises.count else {
            dismiss(animated: true)
            return
        }
        if !isTracking {
            // Kamera ile takip başlat
            let item = workout.exercises[currentExerciseIndex]
            let exerciseVC = ExerciseViewController()
            exerciseVC.selectedExercise = item.exercise
            exerciseVC.modalPresentationStyle = .fullScreen
            exerciseVC.completionHandler = { [weak self] in
                self?.setCompleted()
            }
            isTracking = true
            present(exerciseVC, animated: true)
        } else {
            setCompleted()
        }
    }
    
    @objc private func exitTapped() {
        let alert = UIAlertController(title: "Antrenmandan Çık", message: "Antrenmandan çıkmak istediğinize emin misiniz?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive) { _ in
            self.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel))
        present(alert, animated: true)
    }
    
    private func setCompleted() {
        let item = workout.exercises[currentExerciseIndex]
        if currentSet < item.sets {
            currentSet += 1
        } else {
            currentExerciseIndex += 1
            currentSet = 1
        }
        showCurrentExercise()
    }
} 