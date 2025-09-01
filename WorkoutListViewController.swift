import UIKit

class WorkoutListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var workouts: [SavedWorkout] = []
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Antrenmanlarım"
        workouts = WorkoutStorage.loadWorkouts()
        setupUI()
    }
    
    private func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let workout = workouts[indexPath.row]
        cell.textLabel?.text = workout.name
        cell.detailTextLabel?.text = "Egzersiz sayısı: \(workout.exercises.count)"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let workout = workouts[indexPath.row]
        let sessionVC = WorkoutSessionViewController(workout: workout)
        sessionVC.modalPresentationStyle = .fullScreen
        present(sessionVC, animated: true)
    }
} 