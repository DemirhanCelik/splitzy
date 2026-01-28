# Splitzy 🧾

A beautiful iOS app for item-level bill splitting, built with SwiftUI, SwiftData, and Firebase.

![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue) ![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 📸 **AI Receipt Scanning** - Scan receipts with camera, powered by Gemini AI
- 👥 **Smart Splitting** - Assign items to individuals or split among groups
- 💰 **Accurate Math** - Penny-perfect calculations with fair rounding
- 🔄 **Offline First** - Works without internet, syncs when online
- 🔐 **Guest Mode** - Use without signing in, upgrade later

## Getting Started

### Prerequisites

- Xcode 15+
- iOS 17+ device or simulator
- Firebase project (for backend features)
- Gemini API key (for receipt scanning)

### 1. Clone & Open

```bash
git clone https://github.com/yourusername/Splitzy.git
cd Splitzy
open Splitzy.xcodeproj
```

### 2. Configure Firebase

1. Create a project at [Firebase Console](https://console.firebase.google.com)
2. Download `GoogleService-Info.plist` from your project settings
3. Add it to the `Splitzy/` folder in Xcode

### 3. Configure Gemini API (for Receipt Scanning)

1. Get an API key from [Google AI Studio](https://aistudio.google.com/apikey)
2. Create `Splitzy/Secrets.plist`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
   <plist version="1.0">
   <dict>
       <key>GEMINI_API_KEY</key>
       <string>YOUR_API_KEY_HERE</string>
   </dict>
   </plist>
   ```
3. Add it to Xcode (File → Add Files)

### 4. Enable Sign in with Apple

1. In Xcode: Select target → Signing & Capabilities
2. Click `+ Capability` → Add "Sign in with Apple"

### 5. Deploy Backend (Optional)

```bash
cd Backend
npm install -g firebase-tools
firebase login
firebase deploy
```

## Project Structure

```
Splitzy/
├── Models/          # SwiftData models (Bill, Item, Participant)
├── Views/           # SwiftUI views
│   ├── Home/        # Bill list
│   ├── Editor/      # Bill creation & editing
│   ├── Onboarding/  # Intro screens
│   └── Settings/    # User preferences
├── Services/        # Core logic
│   ├── AuthManager  # Firebase Auth
│   ├── ShareService # Bill sharing
│   └── ReceiptScannerService # AI OCR
└── ViewModels/      # App state
Backend/
├── functions/       # Cloud Functions
├── firestore.rules  # Security rules
└── public/          # Web viewer
```

## Architecture

- **Local-First**: SwiftData for offline capability
- **Integer Math**: All money stored as cents to avoid floating point errors
- **Fair Rounding**: Remainders distributed to participants with largest fractional shares

## Running Tests

```bash
# In Xcode: Cmd + U
# Or via command line:
xcodebuild test -scheme Splitzy -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Backend powered by [Firebase](https://firebase.google.com)
- Receipt scanning by [Gemini AI](https://ai.google.dev)
