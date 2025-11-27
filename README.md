# Setup & Run Instructions

I have automatically organized the project structure for you.

## Prerequisites
- **Flutter SDK** installed and in your PATH.
- **Android Studio** or **VS Code** with Flutter extensions (optional but recommended).
- A connected device (Android/iOS) or Emulator/Simulator.

## How to Run
1. **Open Terminal** in this directory:
   ```bash
   cd /Users/feboyfierlyan/Documents/coding/project/ToDoList
   ```

2. **Get Dependencies** (should be automatic, but good to verify):
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

## Troubleshooting
- If you see "No connected devices", launch a simulator or connect your phone.
- If you see CocoaPods errors on Mac (for iOS), run:
  ```bash
  cd ios
  pod install
  cd ..
  ```
