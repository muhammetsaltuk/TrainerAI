//
//  ViewController.swift
//  TrainerAI
//
//  Created by Muhammet Saltuk ÖZDEMİR on 28.04.2025.
//

import UIKit

class ViewController: UIViewController {
    
    private let glitchLabel: GlitchLabel = {
        let label = GlitchLabel()
        label.text = "Mergen"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "TrainerAI"
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let workoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Antrenman Oluştur", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let myWorkoutsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Antrenmanlarım", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let exerciseCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        glitchLabel.startGlitchAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        glitchLabel.stopAnimation()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = nil // Remove navigation bar title
        
        view.addSubview(glitchLabel)
        view.addSubview(titleLabel)
        view.addSubview(workoutButton)
        view.addSubview(myWorkoutsButton)
        view.addSubview(exerciseCollectionView)
        
        NSLayoutConstraint.activate([
            glitchLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            glitchLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: glitchLabel.bottomAnchor, constant: 24),
            
            workoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            workoutButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            workoutButton.widthAnchor.constraint(equalToConstant: 200),
            workoutButton.heightAnchor.constraint(equalToConstant: 44),
            
            myWorkoutsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            myWorkoutsButton.topAnchor.constraint(equalTo: workoutButton.bottomAnchor, constant: 12),
            myWorkoutsButton.widthAnchor.constraint(equalToConstant: 200),
            myWorkoutsButton.heightAnchor.constraint(equalToConstant: 44),
            
            exerciseCollectionView.topAnchor.constraint(equalTo: myWorkoutsButton.bottomAnchor, constant: 24),
            exerciseCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            exerciseCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            exerciseCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        workoutButton.addTarget(self, action: #selector(workoutButtonTapped), for: .touchUpInside)
        myWorkoutsButton.addTarget(self, action: #selector(myWorkoutsButtonTapped), for: .touchUpInside)
        exerciseCollectionView.delegate = self
        exerciseCollectionView.dataSource = self
        exerciseCollectionView.register(ExerciseCell.self, forCellWithReuseIdentifier: "ExerciseCell")
    }
    
    @objc private func workoutButtonTapped() {
        let builderVC = WorkoutBuilderViewController()
        builderVC.modalPresentationStyle = .formSheet
        present(builderVC, animated: true)
    }
    
    @objc private func myWorkoutsButtonTapped() {
        let listVC = WorkoutListViewController()
        listVC.modalPresentationStyle = .formSheet
        present(listVC, animated: true)
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return exercises.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExerciseCell", for: indexPath) as! ExerciseCell
        let exercise = exercises[indexPath.item]
        cell.configure(with: exercise)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 20) / 2
        return CGSize(width: width, height: 120)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let exercise = exercises[indexPath.item]
        let message = "\(exercise.description)\n\nTelefon Konumlandırma: \(exercise.phoneAdvice)"
        let alert = UIAlertController(title: exercise.name, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Başla", style: .default) { _ in
            let exerciseVC = ExerciseViewController()
            exerciseVC.selectedExercise = exercise
            self.navigationController?.pushViewController(exerciseVC, animated: true)
        })
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }
}

class ExerciseCell: UICollectionViewCell {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 12
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }
    
    func configure(with exercise: Exercise) {
        nameLabel.text = exercise.name
        iconImageView.image = UIImage(systemName: exercise.icon)
    }
}

struct Exercise: Codable {
    let name: String
    let icon: String
    var description: String {
        switch name {
        case "Biceps Curl":
            return "Dik durun, bir kolunuzu büküp düzleştirerek biceps kasınızı çalıştırın. Kolunuz vücudunuzun yanında olmalı."
        case "Şınav":
            return "Eller omuz genişliğinde, vücut düz bir çizgi halinde yere paralel, dirsekleri bükerek göğsünüzü yere yaklaştırın ve tekrar yukarı itin."
        case "Squat":
            return "Ayaklar omuz genişliğinde açık, sırt dik, kalçanızı geriye doğru itin ve dizlerinizi 90 dereceye kadar bükün."
        case "Lunge":
            return "Bir bacağınızı öne atarak dizinizi 90 derece bükün, arka diz yere yaklaşmalı. Sonra başlangıç pozisyonuna dönün."
        case "Plank":
            return "Dirsekler ve ayak parmakları üzerinde, vücut düz bir çizgi halinde sabit durun."
        case "Burpee":
            return "Ayakta başlayın, çömelip ellerinizi yere koyun, ayaklarınızı geriye atıp şınav pozisyonuna geçin, tekrar öne çekip zıplayın."
        case "Mountain Climber":
            return "Şınav pozisyonunda, dizlerinizi sırayla göğsünüze doğru hızlıca çekin."
        case "Glute Bridge":
            return "Sırt üstü yatın, dizler bükülü, ayaklar yerde. Kalçanızı yukarı kaldırıp indirin."
        case "Leg Raises":
            return "Sırt üstü yatın, bacaklarınızı düz tutup yavaşça yukarı kaldırıp indirin."
        default:
            return "Bu hareket için açıklama bulunamadı."
        }
    }
    var phoneAdvice: String {
        switch name {
        case "Biceps Curl":
            return "Telefonu vücudunuzun yanına, kolunuzun hareketini net görecek şekilde yerleştirin. Üst vücut ve kolunuz kadrajda olmalı."
        case "Şınav":
            return "Telefonu yere paralel şekilde, vücudunuzun yanına veya çapraz önüne koyun. Tüm vücudunuz kadrajda olmalı."
        case "Squat":
            return "Telefonu karşıdan, tüm vücudunuzun (baş, gövde, bacaklar) görüneceği şekilde yerleştirin."
        case "Lunge":
            return "Telefonu yandan veya çaprazdan, öne ve arkaya adımınızı görecek şekilde yerleştirin."
        case "Plank":
            return "Telefonu yandan, vücudunuzun düz çizgi olup olmadığını görecek şekilde yerleştirin."
        case "Burpee":
            return "Telefonu karşıdan, tüm vücudunuzun hareketini görecek şekilde yerleştirin."
        case "Mountain Climber":
            return "Telefonu yandan, bacak hareketlerinizi net görecek şekilde yerleştirin."
        case "Glute Bridge":
            return "Telefonu yandan, kalça ve bacak hareketinizi görecek şekilde yerleştirin."
        case "Leg Raises":
            return "Telefonu yandan, bacaklarınızın yukarı-aşağı hareketini görecek şekilde yerleştirin."
        default:
            return "Telefonunuzu sabit bir yere, tüm vücudunuzun görüneceği şekilde yerleştirin."
        }
    }
}

