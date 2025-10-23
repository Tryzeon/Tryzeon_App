# Tryzeon App


## Getting Started

### 1. Install Flutter

Download and install Flutter from the official website:
- Visit [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- Follow the installation instructions for your operating system
- Verify installation by running:
  ```bash
  flutter doctor
  ```

### 2. Install Dependencies

Navigate to the project directory and install dependencies:
```bash
flutter pub get
```

### 3. Open Simulator/Emulator

**For iOS (macOS only):**
```bash
open -a Simulator
```

**For Android:**
- Open Android Studio
- Go to Tools > Device Manager
- Start your preferred Android Virtual Device (AVD)

### 4. Run the Application

Run the app on your connected device:
```bash
flutter run --release
```

Run the app on your simulator:
```bash
flutter run
```

To run on a specific device:
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

## File Storage Location

### Avatars: 
`[avatars_bucket]/${userId}/avator/${timestamp}.jpg` 

### Wardrobe: 
`[wardrobe_bucket]/${userId}/wardrobe/${categoryCode}/${timestamp}.jpg`


## TODO, Bugs:
1. 現在的個人設定-基本資料-更改姓名方式不會被正確更改，因為 metadata['name'] 欄位每次使用第三方登入都會被覆蓋，所以只是拿來 Demo 設定欄位的。