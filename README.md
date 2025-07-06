# **SwiftRecorder: Professional Audio Recording & Transcription**

SwiftRecorder is a production-ready iOS audio recording application featuring intelligent 30-second segmentation, cloud-based transcription services, and comprehensive session management. Built with modern SwiftUI architecture and designed for scalable performance with thousands of recording sessions.

<p float="left">
  <img src="https://imgur.com/mbGY3Xo.jpg" width="200" style="margin-right: 10px;">
  <img src="https://imgur.com/h0y1ZId.jpg" width="200" style="margin-right: 10px;">
  <img src="https://imgur.com/bDiBuHk.jpg" width="200" style="margin-right: 10px;">
  <img src="https://imgur.com/XtQXnkI.jpg" width="200" style="margin-right: 10px;">
  <img src="https://imgur.com/BsWzmQp.jpg" width="200" style="margin-right: 10px;">
</p>

## 🚀 Core Features

### 🎵 Advanced Audio Recording
- **High-Quality Capture:** Optimized audio recording using M4A/AAC format.
- **Background Recording:** Continue recording seamlessly when the app enters the background.
- **Intelligent Interruption Handling:** Automatically pauses and resumes for phone calls, notifications, and other system audio events.
- **Multi-Route Support:** Works flawlessly with the built-in microphone, wired headphones, and Bluetooth devices.

### 🤖 Multi-Provider Transcription
- **Intelligent Segmentation:** Automatically splits long recordings into 30-second chunks for fast, reliable processing.
- **Apple Speech Recognition:** Provides free, on-device transcription for instant results, ultimate privacy, and offline capability.
- **OpenAI Whisper & Google STT:** Integrates with industry-leading cloud services for the highest accuracy.
- **Smart Fallback System:** Automatically switches to Apple's on-device service if a cloud provider fails consecutively (5+ times), ensuring you always get a transcription.

### ⚙️ Session & Performance Management
- **SwiftData Persistence:** Modern, type-safe data storage for all recording sessions and transcription segments.
- **Session Organization:** Chronological list of all recordings with duration, date, and processing status.
- **Memory & Storage Management:** Includes dedicated managers to monitor app performance, clean up orphaned files, and prevent excessive storage use.
- **Concurrent Processing:** Intelligently processes multiple audio segments in parallel with performance-aware throttling to keep the UI responsive.

## 🎯 Getting Started

### **Prerequisites**
- Xcode 15.0+
- Swift 5.9+
- An Apple Developer account (for running on a physical device)

### **Setup & Run**
1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/letsgobjones/SwiftRecorder.git
    ```
2.  **Open in Xcode:**
    Open the `SwiftRecorder.xcodeproj` file.
3.  **Build and Run:**
    Select your target device or simulator and press **Run** (⌘+R).

### **Permissions Required**
- **Microphone Access:** Required for audio recording.
- **Speech Recognition:** Required for using Apple's on-device transcription.

### **Usage Guide**
1.  **Grant Permissions:** On first launch, allow microphone and speech recognition access.
2.  **Start Recording:** Tap the large record button on the main screen.
3.  **Stop Recording:** Tap the stop button to end the session. Transcription will begin automatically.
4.  **Configure Cloud APIs (Optional):**
    - Navigate to the **Settings** screen.
    - Select a cloud provider and enter your API key to enable higher-accuracy transcriptions.

## 🏗️ Architecture & Design

This application is built using a modern, service-oriented architecture with SwiftUI and the MVVM pattern.

- **Platform:** Native iOS (Swift 5.9+, SwiftUI)
- **Architecture:** MVVM with `@Observable` for reactive UI updates.
- **Data Persistence:** SwiftData with a `ModelContainer` injected into the environment.
- **Navigation:** SwiftUI `NavigationStack`.
- **Dependency Management:** Services are injected into a central `AppManager` which is then passed into the SwiftUI environment.

### **Core Components**
- **`AppManager`**: The central coordinator that owns and manages all other services.
- **`RecordingManager`**: Handles the business logic of starting and stopping recording sessions.
- **`AudioService`**: A low-level service that directly manages `AVAudioEngine` for capturing and saving audio.
- **`ProcessingCoordinator`**: Manages the background transcription process, including audio segmentation and task coordination.
- **`TranscriptionService`**: A wrapper that routes transcription requests to the appropriate provider (Apple, Google, or OpenAI).
- **`APIKeyManager`**: Securely stores and retrieves API keys from the iOS Keychain.
- **`PerformanceManager` & `StorageManager`**: Utilities for monitoring app health and managing disk space.

## 🧪 Testing Suite

The project includes a robust testing framework with **25+ unit and UI tests** covering all major components.

### **Unit Tests (`SwiftRecorderTests/`)**
- **✅ Model Tests:** SwiftData relationships, computed properties, data integrity.
- **✅ Service Tests:** Transcription services, audio processing, API integrations.
- **✅ Manager Tests:** `AppManager` coordination, dependency injection, lifecycle management.
- **✅ ViewModel Tests:** `SettingsViewModel` state transitions and user interactions.

### **UI Tests (`SwiftRecorderUITests/`)**
- **✅ Navigation Tests:** Screen transitions and toolbar interactions.
- **✅ Recording Flow:** Start/stop recording, permission handling, and state updates.
- **✅ Session Management:** List display, detail views, and playback.
- **✅ Settings Interface:** API key management and validation.

### **Test Architecture**
- **Mock Services:** Uses mock implementations of services for isolated testing.
- **In-Memory Database:** Utilizes an in-memory `ModelContainer` for fast and isolated SwiftData tests.
- **Bundled Test Assets:** Includes a `sample_recording.m4a` file for realistic transcription and processing tests.

## 🛣️ Future Enhancements

The following features are planned for future releases to further enhance the user experience:
- **Card-Based Layout:** Transition from a standard list to modern, card-based UI for session items.
- **Advanced Animations:** Implement more dynamic animations for recording states and transitions.
- **Customizable Settings:** Add more user-facing settings, such as audio quality and storage management rules.
- **Search and Filtering:** Implement robust search functionality to find specific transcriptions.
- **iCloud Sync:** Add support for syncing recordings and sessions across a user's devices.
