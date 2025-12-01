# Clean-Flow iOS Application

A comprehensive SwiftUI iOS application for hospitals to track, verify, and audit all cleaning cycles with real-time monitoring and compliance reporting.

## Overview

Clean-Flow is a hospital-grade cleaning management system that provides:
- **QR/NFC Scanning** for area verification
- **Protocol Management** with step-by-step checklists
- **Real-time Auditing** with compliance scoring
- **Personnel Management** with activity tracking
- **Dashboard Analytics** with live updates
- **Export Capabilities** for regulatory compliance

## Features

### Authentication
- Firebase Auth integration
- Email/password login & registration
- Password reset functionality
- Role-based access control

### QR/NFC Scanner
- AVFoundation QR code scanning
- Core NFC tag reading
- Real-time validation
- Haptic feedback

### Protocol Management
- Custom cleaning protocols
- Step-by-step checklists
- Equipment & chemical requirements
- Progress tracking

### Real-time Dashboard
- Live compliance metrics
- Today's cleaning cycles
- Staff activity monitoring
- Audit countdown timers

### Audit System
- Timeline-style audit cards
- Exception tracking
- Compliance scoring
- CSV/PDF export

### Personnel Management
- Staff role management
- Activity statistics
- Performance metrics
- User profiles

### Settings
- Profile management
- Dark/Light mode toggle
- Notification preferences
- App version info

## UI Design

### Theme
- **Background**: Deep Navy (#060A19)
- **Accent**: Neon Aqua (#2BCBFF)
- **Secondary**: Purple (#8A4DFF)
- **Cards**: Glassmorphism with blur effects

### Components
- Rounded cards (16-20px radius)
- Soft drop shadows
- Smooth transitions
- iOS-style neon progress bars
- SF Symbols icons

## Architecture

### Project Structure
```
CleanFlowApp/
├── Sources/
│   ├── App/
│   │   └── CleanFlowApp.swift
│   ├── Views/
│   │   ├── Auth/
│   │   ├── Dashboard/
│   │   ├── Protocols/
│   │   ├── Audits/
│   │   ├── Personnel/
│   │   ├── Settings/
│   │   ├── Scanner/
│   │   └── Workflows/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── CleaningProtocol.swift
│   │   ├── CleaningRun.swift
│   │   ├── Room.swift
│   │   └── Audit.swift
│   ├── Services/
│   │   ├── AuthService.swift
│   │   ├── FirestoreRepository.swift
│   │   └── ScannerService.swift
│   └── Managers/
│       ├── AppState.swift
│       ├── QRManager.swift
│       └── NFCManager.swift
├── Resources/
│   ├── Info.plist
│   └── GoogleService-Info.plist
└── Assets.xcassets/
    ├── AppIcon.appiconset/
    └── CleanFlowLogo.imageset/
```

### Data Models

#### Firestore Schema
```swift
runs/{id} {
   userId: String
   protocolId: String
   roomId: String
   stepsCompleted: [String]
   completedAt: Date
   exceptions: [CleaningException]
}

users/{id} {
   name: String
   email: String
   role: UserRole
   department: String
   isActive: Bool
}

protocols/{id} {
   name: String
   description: String
   steps: [CleaningStep]
   areaType: AreaType
   priority: Priority
}

audits/{id} {
   auditorId: String
   roomId: String
   complianceScore: Double
   status: AuditStatus
   hasExceptions: Bool
}
```

## Technical Implementation

### Dependencies
- **SwiftUI** for UI framework
- **Firebase/Auth** for authentication
- **Firebase/Firestore** for database
- **AVFoundation** for QR scanning
- **CoreNFC** for NFC reading
- **Combine** for reactive programming

### Key Services
- **AuthService**: User authentication & session management
- **FirestoreRepository**: Database operations with async/await
- **QRManager**: Camera handling & QR code processing
- **NFCManager**: NFC tag reading & validation
- **ScannerService**: Unified scanning interface

### State Management
- **AppState**: Global application state
- **Environment Objects**: Dependency injection
- **ObservableObject**: Reactive UI updates
- **@Published**: Property observation

## Testing

### Unit Tests
- AuthService authentication flows
- FirestoreRepository CRUD operations
- QR/NFC validation logic

### UI Tests
- Scanner launch and functionality
- Dashboard rendering
- Protocol workflow completion

## Build & Run

### Prerequisites
- Xcode 15.0+
- iOS 16.0+
- Firebase project setup
- Physical device for NFC testing

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd Clean-Flow-app.v1
   ```

2. **Firebase Configuration**
   - Create Firebase project
   - Enable Authentication (Email/Password)
   - Set up Firestore database
   - Download `GoogleService-Info.plist`
   - Place in `Resources/` folder

3. **Xcode Setup**
   - Open `CleanFlowApp.xcodeproj`
   - Select your development team
   - Update bundle identifier
   - Enable NFC capability (if needed)

4. **Build & Run**
   ```bash
   # Build from command line
   xcodebuild -project CleanFlowApp.xcodeproj -scheme CleanFlowApp build
   
   # Or run in Xcode
   # Product → Run (Cmd+R)
   ```

### Configuration

#### Firebase Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /runs/{runId} {
      allow read, write: if request.auth != null;
    }
    
    match /protocols/{protocolId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        resource.data.role in ['admin', 'supervisor'];
    }
    
    match /audits/{auditId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### App Capabilities
- **Camera**: QR code scanning
- **NFC Reading**: Tag verification
- **Background Updates**: Real-time sync
- **Notifications**: Audit alerts

## Device Support

### iOS Requirements
- **Minimum iOS**: 16.0
- **Recommended**: iOS 17.0+
- **Devices**: iPhone, iPad
- **Architecture**: Universal (arm64)

### Permissions Required
- Camera Access (QR scanning)
- NFC Reading (tag verification)
- Network Access (Firebase)
- Notifications (alerts)

## Security

### Authentication
- Firebase Auth with email/password
- Session management
- Password reset functionality
- Role-based access control

### Data Protection
- Firestore security rules
- Encrypted data transmission
- Local data caching
- User privacy compliance

## Analytics & Monitoring

### Firebase Analytics
- User engagement tracking
- Feature usage metrics
- Performance monitoring
- Crash reporting

### Custom Events
- Protocol completions
- Scan success rates
- Compliance scores
- User activities

## Deployment

### App Store Submission
1. **Build Archive**: Product → Archive
2. **Validate**: Check for issues
3. **Upload**: App Store Connect
4. **Metadata**: Screenshots & descriptions
5. **Submit**: Review process

### Enterprise Distribution
1. **Build**: Enterprise certificate
2. **Package**: IPA file
3. **Distribute**: MDM or manual
4. **Install**: Over-the-air updates

## Contributing

### Development Workflow
1. **Feature Branch**: `git checkout -b feature/new-feature`
2. **Development**: Implement with tests
3. **Review**: Pull request process
4. **Merge**: Main branch integration
5. **Release**: Tag and deploy

### Code Style
- SwiftUI for all UI
- Async/await for Firebase
- Dependency injection pattern
- Minimal object spacing
- Modular architecture

## Support

### Documentation
- **User Guide**: Feature walkthroughs
- **Admin Guide**: Configuration instructions
- **API Reference**: Service documentation
- **Troubleshooting**: Common issues

### Contact
- **Issues**: GitHub repository
- **Support**: Development team
- **Training**: Onboarding sessions

## License

© 2024 Clean-Flow Hospital Solutions
All rights reserved.

---

**Clean-Flow** - Streamlining hospital cleaning management with modern mobile technology.
