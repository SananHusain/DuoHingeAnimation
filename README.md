# iPhone Duo Hinge Motion & 3D Folding Animation

A native **SwiftUI iOS application** and interactive web prototype recreating Apple's iPhone Duo-style 3D physical folding screen animation and real-time gyroscope-based leading-to-trailing tilt motion blur physics.

---

## 🌟 Key Features

### 1. Progressive Leading-to-Trailing Column Wave Blur
- **Dynamic Inertia Physics**: When tilting the physical device or rotating the angle, the screen content experiences a smooth, continuous column-by-column wave animation (Columns 0 → 1 → 2 → 3).
- **Directional Motion Blur & Scale**: As the phone tilts left or right, trailing columns lag behind with proportional inertia offsets, scale elevation, and realistic motion blur trails.
- **Hardware Gyro Integration**: Utilizes Apple's `CoreMotion` (`CMMotionManager`) to capture device roll, pitch, and angular velocity at 60fps on physical iPhones.
- **Horizontal Motion Restriction**: Restricts Y-axis displacement for a clean, stable horizontal tilt experience.

### 2. Pixel-Perfect iOS Homescreen Reconstruction
- **Top Status Bar**: Aligned clean header display (`1:45`, signal bars, Wi-Fi, battery level).
- **Widgets Row**:
  - **Weather Widget** (Columns 0–1): Deep blue gradient displaying `New Delhi`, `32°`, `Mostly Cloudy`, `H:32° L:27°` + `Weather` label.
  - **Calendar Widget** (Columns 2–3): Dark grey card displaying `FRIDAY`, large `11`, `No Events Today` + `Calendar` label.
- **4x4 App Grid**: FaceTime, Calendar (`Fri 11`), Photos (rainbow flower), Camera (metallic lens), Mail, Notes (yellow header), Reminders (3 colored dots & lines), Clock, TV (` tv`), Games (rocket launcher), App Store, Maps, Health, Wallet, Settings (with notification badge **2**), and SumDemo.
- **Floating Search Pill**: Translucent glass pill (`🔍 Search`) floating between the app grid and dock.
- **Glassmorphic Bottom Dock**: Frosted glass shelf containing Phone (badge **18**), Safari, Messages (badge **32**), and Music with dynamic background glass blur.

### 3. Physical 3D Folding Animation
- **Hinge Rotation Architecture**: Divides the screen into left and right display panels anchored at a central vertical hinge.
- **1:1 Finger Gesture Tracking**: Dragging across the display rotates the right panel in 3D space (`rotation3DEffect` with 3D perspective) from 0° (Closed) to 180° (Fully Open Dual Display).
- **Physical Spring Momentum**: Releasing the gesture snaps open or closed with spring dampening physics.

---

## 📁 Repository Structure

```text
DuoHingeAnimation/
├── Duo animation/
│   ├── ContentView.swift             # Native SwiftUI App (CoreMotion Gyro & 3D Hinge Physics)
│   ├── Duo_animationApp.swift        # App Entry Point
│   └── Assets.xcassets/              # App Assets & Screenshot Textures
├── index.html                        # Web Application Prototype
├── style.css                         # Web Glassmorphism & 3D Transform Styles
├── app.js                            # Web Gyroscope & 3D Folding Engine
├── wallpaper.jpg                     # High-Resolution iOS Wallpaper Asset
├── README.md                         # Project Documentation
└── .gitignore                        # Git Ignore Configurations
```

---

## 🚀 Getting Started

### Native iOS App (SwiftUI)
1. Open `Duo animation.xcodeproj` in **Xcode**.
2. Select your target device (Physical iPhone or Simulator).
3. Build and Run (`Cmd + R`).
4. Tilt your physical iPhone left or right to experience the hardware gyro wave motion blur.

### Web Application Prototype
1. Open terminal in the project directory.
2. Start a local HTTP dev server:
   ```bash
   python3 -m http.server 8080
   ```
3. Open `http://localhost:8080` in your web browser.

---

## 📄 License

Distributed under the MIT License.