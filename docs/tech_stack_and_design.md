# NovaCoach Tech Stack & Design Approach

This document summarises the recommended technology choices and architectural guidelines for building the NovaCoach iOS application.

## Platform & Language
- **Language:** Swift 5
- **UI Framework:** SwiftUI for declarative interfaces, fluid animations, glassmorphism, and dark-mode support.
- **Target Platform:** iOS 17 and later.

## Architecture
- Adopt **MVVM combined with Clean Architecture** to separate views, view models, use cases, repositories, and data sources.
- Embrace **Test-Driven Development (TDD)** with XCTest, Quick/Nimble, and SnapshotTesting.
- Maintain code coverage thresholds (>80%) and integrate tests into CI/CD (GitHub Actions).

## Data Storage & Security
- Persist data locally using **Core Data** with **SQLCipher** providing AES-256 encryption.
- Enable `NSPersistentStoreFileProtectionKey` with `.complete` to leverage the iOS Data Protection API.
- Store OAuth tokens and sensitive secrets exclusively in **Keychain Services**; avoid `UserDefaults` for sensitive data.
- Exclude sensitive files from iTunes/iCloud backups and never log sensitive information.

## Authentication
- Provide **Google Sign-In (OAuth 2.0)** using the official GoogleSignIn Swift package (v7.1.0+).
- Include **Sign in with Apple** via the `AuthenticationServices` framework.
- Support multi-factor authentication and create local Core Data user profiles after successful sign-in.

## Voice Assistant
- Use an on-device wake-word engine such as **Picovoice Porcupine** with a custom wake word ("Hey Buddy").
- After activation, rely on Apple’s Speech framework for transcription and `AVSpeechSynthesizer` for TTS.
- Ensure all audio processing remains on-device.

## Core Features
### OKR & Goals
- Manage Objectives and Key Results in encrypted storage (`OKRTable`).
- Display progress using SwiftUI Charts and allow CSV/PDF exports via PDFKit.

### 10:10s (1:1 Conversations)
- Record meetings with `AVAudioRecorder` and transcribe locally.
- Store notes, transcripts, and action items in `OneOnOneTable` with notification reminders.
- Implement search and filtering by participant, keyword, or status.

### Personal (Daily Journal & Focus Tracker)
- Capture daily plans and reflections in `PersonalLog` with adjustable reminders via `UserNotifications`.
- Link tasks to related OKRs where applicable.

### Analytics
- Compute OKR completion, action item status, and reflection streaks.
- Render radial, line, and bar charts using SwiftUI’s Chart APIs.
- Offer CSV/PDF export options.

## Notifications & Scheduling
- Leverage `UserNotifications` and `UNCalendarNotificationTrigger` for reminders (daily plans, reflections, action items).
- Allow user-customisable schedules.

## Design Language
- Pursue a minimalist aesthetic with glassmorphic panels, bold accent colours, and micro-interactions.
- Provide dark-mode support, haptic feedback, and confetti effects for milestones.
- Ensure accessibility compliance (Dynamic Type, VoiceOver, adjustable contrast).

## AI & Intelligence
- Use on-device ML (Apple NaturalLanguage, local LLMs) for summarisation and insights.
- Keep all processing and user data on-device.

## Compliance & Privacy
- Implement privacy-by-design and data minimisation practices.
- Document privacy policies highlighting Google Sign-In data handling.
- Adhere to GDPR/EU AI Act requirements and App Store privacy manifest regulations.

## Future Enhancements
- Potential integrations: GitHub/Jira APIs, sentiment analysis on 1:1 notes, expanded on-device ML models.
- Continue evaluating local-first AI capabilities as Apple releases new frameworks.

