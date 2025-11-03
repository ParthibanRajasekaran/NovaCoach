# NovaCoach

NovaCoach is a privacy-first OKR and well-being companion app for iOS 17+ built with SwiftUI, MVVM, and Clean Architecture. The app keeps all data on-device with encrypted Core Data storage, integrates Google and Apple authentication (stubs for signing), offers a local wake-word assistant, and provides dedicated experiences for OKRs, 10:10s, personal reflections, and analytics.

## Features
- **OKR Dashboard** – define objectives and key results, visualise progress with glassmorphic cards, and link related action items.
- **10:10s** – capture one-on-one meetings with notes, optional recordings, automatic transcript storage, and reminder scheduling for assigned action items.
- **Personal Journal** – record daily focus plans, reflections, and mood with configurable notification cadences.
- **Analytics** – review on-device analytics including completion stats, action item distribution, and reflection streaks.
- **Voice Assistant** – local wake-word service (Porcupine ready) with speech-to-text and text-to-speech hooks that trigger key workflows without sending data to the cloud.

## Structure
The project is organised as a Swift Package so it can compile on CI without Xcode while still targeting iOS. Key directories:

- `Sources/NovaCoachApp/App` – SwiftUI entry point, dependency container, and root navigation.
- `Sources/NovaCoachApp/Core` – Core Data stack, encrypted keychain handling, notification, speech, and voice assistant services.
- `Sources/NovaCoachApp/Domain` – Entities and use cases implementing the Clean Architecture domain layer.
- `Sources/NovaCoachApp/Features` – MVVM view models and SwiftUI views for OKRs, 10:10s, personal logs, and analytics.
- `Sources/NovaCoachApp/Shared` – Shared components, theming, and helpers.
- `Tests/NovaCoachAppTests` – XCTest coverage for critical use cases.

## Running the project
1. Open the repository in Xcode 15+ and select *File → Add Packages…* to resolve dependencies (Quick, Nimble, SnapshotTesting).
2. Create an iOS 17+ target or use Xcode’s “New Project from Package” option to run the SwiftUI app on device or simulator.
3. Provide a SQLCipher-enabled Core Data store key in the iOS Keychain (the `KeychainService` generates one automatically for development builds).

## Tests
Run the unit test suite with:

```bash
swift test
```

## Documentation
- [Tech Stack & Design Approach](docs/tech_stack_and_design.md)
