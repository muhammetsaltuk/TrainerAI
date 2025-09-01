import UIKit

struct WorkoutExercise: Codable {
    let exercise: Exercise
    let sets: Int
    let reps: Int
}

struct SavedWorkout: Codable {
    let name: String
    let exercises: [WorkoutExercise]
}

class WorkoutBuilderViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    private var workout: [WorkoutExercise] = []
    private let exercises = [
        Exercise(name: "Biceps Curl", icon: "dumbbell.fill"),
        Exercise(name: "Şınav", icon: "figure.strengthtraining.traditional"),
        Exercise(name: "Squat", icon: "figure.strengthtraining.functional"),
        Exercise(name: "Lunge", icon: "figure.step.training"),
        Exercise(name: "Plank", icon: "figure.core.training"),
        Exercise(name: "Burpee", icon: "figure.run"),
        Exercise(name: "Mountain Climber", icon: "figure.run"),
        Exercise(name: "Glute Bridge", icon: "figure.yoga"),
        Exercise(name: "Leg Raises", icon: "figure.core.training")
    ]
    private var selectedExerciseIndex = 0
    private var selectedSets = 3
    private var selectedReps = 10
    
    private let tableView = UITableView()
    private let addButton = UIButton(type: .system)
    private let pickerView = UIPickerView()
    private let setsStepper = UIStepper()
    private let repsStepper = UIStepper()
    private let setsLabel = UILabel()
    private let repsLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Antrenman Oluştur"
        setupUI()
    }
    
    private func setupUI() {
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerView)
        
        setsLabel.text = "Set: 3"
        setsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(setsLabel)
        setsStepper.minimumValue = 1
        setsStepper.maximumValue = 10
        setsStepper.value = 3
        setsStepper.translatesAutoresizingMaskIntoConstraints = false
        setsStepper.addTarget(self, action: #selector(setsChanged), for: .valueChanged)
        view.addSubview(setsStepper)
        
        repsLabel.text = "Tekrar: 10"
        repsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(repsLabel)
        repsStepper.minimumValue = 1
        repsStepper.maximumValue = 50
        repsStepper.value = 10
        repsStepper.translatesAutoresizingMaskIntoConstraints = false
        repsStepper.addTarget(self, action: #selector(repsChanged), for: .valueChanged)
        view.addSubview(repsStepper)
        
        addButton.setTitle("Ekle", for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 10
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addExercise), for: .touchUpInside)
        view.addSubview(addButton)
        
        saveButton.setTitle("Kaydet", for: .normal)
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveWorkout), for: .touchUpInside)
        view.addSubview(saveButton)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            pickerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            pickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            setsLabel.topAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 16),
            setsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            setsStepper.centerYAnchor.constraint(equalTo: setsLabel.centerYAnchor),
            setsStepper.leadingAnchor.constraint(equalTo: setsLabel.trailingAnchor, constant: 8),
            
            repsLabel.topAnchor.constraint(equalTo: setsLabel.bottomAnchor, constant: 16),
            repsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            repsStepper.centerYAnchor.constraint(equalTo: repsLabel.centerYAnchor),
            repsStepper.leadingAnchor.constraint(equalTo: repsLabel.trailingAnchor, constant: 8),
            
            addButton.topAnchor.constraint(equalTo: repsLabel.bottomAnchor, constant: 24),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 120),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            
            saveButton.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 16),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 120),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func setsChanged() {
        selectedSets = Int(setsStepper.value)
        setsLabel.text = "Set: \(selectedSets)"
    }
    
    @objc private func repsChanged() {
        selectedReps = Int(repsStepper.value)
        repsLabel.text = "Tekrar: \(selectedReps)"
    }
    
    @objc private func addExercise() {
        let exercise = exercises[selectedExerciseIndex]
        let workoutExercise = WorkoutExercise(exercise: exercise, sets: selectedSets, reps: selectedReps)
        workout.append(workoutExercise)
        tableView.reloadData()
    }
    
    @objc private func saveWorkout() {
        guard !workout.isEmpty else { return }
        let alert = UIAlertController(title: "Antrenman İsmi", message: "Antrenmanınıza bir isim verin:", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Örn: Pazartesi Full Body"
        }
        alert.addAction(UIAlertAction(title: "Kaydet", style: .default) { [weak self] _ in
            guard let self = self, let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let savedWorkout = SavedWorkout(name: name, exercises: self.workout)
            var saved = WorkoutStorage.loadWorkouts()
            saved.append(savedWorkout)
            WorkoutStorage.saveWorkouts(saved)
            self.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workout.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let item = workout[indexPath.row]
        cell.textLabel?.text = item.exercise.name
        cell.detailTextLabel?.text = "Set: \(item.sets)  Tekrar: \(item.reps)"
        cell.imageView?.image = UIImage(systemName: item.exercise.icon)
        return cell
    }
    
    // MARK: - PickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { exercises.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return exercises[row].name
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedExerciseIndex = row
    }
}

class WorkoutStorage {
    static let key = "saved_workouts"
    static func saveWorkouts(_ workouts: [SavedWorkout]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(workouts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    static func loadWorkouts() -> [SavedWorkout] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([SavedWorkout].self, from: data)) ?? []
    }
} 