# TrainerAI - iOS Fitness Tracking App 📱💪


## 🇹🇷 Türkçe

### 📖 Proje Hakkında

TrainerAI, kullanıcıların egzersiz yaparken doğru formda olup olmadığını gerçek zamanlı olarak analiz eden, tekrar sayan ve antrenmanlarını kaydeden bir iOS uygulamasıdır. MediaPipe BlazePose teknolojisi kullanılarak 33 vücut noktası tespit edilir ve egzersiz formu analiz edilir.

### ✨ Özellikler

- 🎯 **Gerçek Zamanlı Form Analizi**: MediaPipe ile vücut pozisyonu takibi
- 🔢 **Otomatik Tekrar Sayımı**: Her egzersiz için özel algoritmalar
- 📱 **Kullanıcı Dostu Arayüz**: Sezgisel ve modern tasarım
- 💾 **Antrenman Kaydetme**: CoreData ile veri saklama
- 🏋️ **Çoklu Egzersiz Desteği**: 9 farklı egzersiz türü
- 📊 **İlerleme Takibi**: Görsel geri bildirimler ve ilerleme çubuğu

### 🏃‍♂️ Desteklenen Egzersizler

- Biceps Curl (Biceps Kıvırma)
- Şınav (Push-up)
- Squat (Çömelme)
- Lunge (Hamle)
- Plank
- Burpee
- Mountain Climber
- Glute Bridge (Kalça Köprüsü)
- Leg Raises (Bacak Kaldırma)

### 🛠️ Kullanılan Teknolojiler

- **Swift 5.0+** - iOS uygulama geliştirme
- **UIKit** - Kullanıcı arayüzü
- **MediaPipe BlazePose** - Vücut noktası takibi
- **CoreData** - Veri saklama
- **AVFoundation** - Kamera ve video işleme
- **MVVM Mimarisi** - Temiz ve sürdürülebilir kod yapısı

### 📱 Sistem Gereksinimleri

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+
- iPhone/iPad (kamera gerekli)

### 🚀 Kurulum

1. Projeyi klonlayın:
```bash
git clone https://github.com/kullaniciadi/TrainerAI.git
cd TrainerAI
```

2. Xcode'da projeyi açın:
```bash
open TrainerAI.xcworkspace
```

3. Gerekli bağımlılıkları yükleyin:
```bash
pod install
```

4. Projeyi çalıştırın (⌘+R)

### 📁 Proje Yapısı

```
TrainerAI/
├── Controllers/          # View Controllers
│   ├── ExerciseViewController.swift
│   ├── WorkoutSessionViewController.swift
│   └── WorkoutBuilderViewController.swift
├── Models/              # Data Models
│   ├── Exercise.swift
│   └── WorkoutExercise.swift
├── Managers/            # Utility Classes
│   ├── MediaPipeManager.swift
│   └── PoseAnalyzer.swift
├── Views/               # Custom Views
└── Resources/           # Assets and Resources
```

### 🔧 Kullanım

1. **Antrenman Oluşturma**: Ana ekrandan "Antrenman Oluştur" butonuna tıklayın
2. **Egzersiz Seçimi**: İstediğiniz egzersizleri, set ve tekrar sayılarını belirleyin
3. **Antrenman Başlatma**: Oluşturulan antrenmanı başlatın
4. **Form Takibi**: Kamerayı sabit bir yere yerleştirin ve egzersizi yapın
5. **Sonuçları Görme**: Tekrar sayısı ve form analizi sonuçlarını takip edin

### 🎯 Teknik Detaylar

- **MVVM Mimarisi**: Model-View-ViewModel pattern kullanılarak temiz kod yapısı
- **MediaPipe Entegrasyonu**: Gerçek zamanlı vücut noktası tespiti
- **Açı Hesaplama**: Vücut noktalarından matematiksel açı hesaplaması
- **CoreData**: Yerel veritabanı ile veri saklama
- **Kamera Optimizasyonu**: Yüksek performanslı video işleme


---

## 🇺🇸 English

### 📖 About the Project

TrainerAI is an iOS application that analyzes users' exercise form in real-time, counts repetitions, and saves their workouts. Using MediaPipe BlazePose technology, it detects 33 body points and analyzes exercise form.

### ✨ Features

- 🎯 **Real-time Form Analysis**: Body position tracking with MediaPipe
- 🔢 **Automatic Rep Counting**: Special algorithms for each exercise
- 📱 **User-friendly Interface**: Intuitive and modern design
- 💾 **Workout Saving**: Data storage with CoreData
- 🏋️ **Multiple Exercise Support**: 9 different exercise types
- 📊 **Progress Tracking**: Visual feedback and progress bars

### 🏃‍♂️ Supported Exercises

- Biceps Curl
- Push-up
- Squat
- Lunge
- Plank
- Burpee
- Mountain Climber
- Glute Bridge
- Leg Raises

### 🛠️ Technologies Used

- **Swift 5.0+** - iOS app development
- **UIKit** - User interface
- **MediaPipe BlazePose** - Body point tracking
- **CoreData** - Data storage
- **AVFoundation** - Camera and video processing
- **MVVM Architecture** - Clean and maintainable code structure

### 📱 System Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+
- iPhone/iPad (camera required)

### 🚀 Installation

1. Clone the project:
```bash
git clone https://github.com/username/TrainerAI.git
cd TrainerAI
```

2. Open the project in Xcode:
```bash
open TrainerAI.xcworkspace
```

3. Install required dependencies:
```bash
pod install
```

4. Run the project (⌘+R)

### 📁 Project Structure

```
TrainerAI/
├── Controllers/          # View Controllers
│   ├── ExerciseViewController.swift
│   ├── WorkoutSessionViewController.swift
│   └── WorkoutBuilderViewController.swift
├── Models/              # Data Models
│   ├── Exercise.swift
│   └── WorkoutExercise.swift
├── Managers/            # Utility Classes
│   ├── MediaPipeManager.swift
│   └── PoseAnalyzer.swift
├── Views/               # Custom Views
└── Resources/           # Assets and Resources
```

### 🔧 Usage

1. **Create Workout**: Click "Create Workout" button from main screen
2. **Exercise Selection**: Choose desired exercises, sets and rep counts
3. **Start Workout**: Begin the created workout
4. **Form Tracking**: Place camera in a fixed position and perform exercises
5. **View Results**: Track rep count and form analysis results

### 🎯 Technical Details

- **MVVM Architecture**: Clean code structure using Model-View-ViewModel pattern
- **MediaPipe Integration**: Real-time body point detection
- **Angle Calculation**: Mathematical angle calculation from body points
- **CoreData**: Local database for data storage
- **Camera Optimization**: High-performance video processing
