# LinkedIn Tool — iOS App

A SwiftUI iPhone app that generates LinkedIn posts using the Anthropic API.

## Files

| File | Purpose |
|------|---------|
| `LinkedInToolApp.swift` | App entry point (`@main`) |
| `ContentView.swift` | Tab bar navigation |
| `CreateView.swift` | Post generation UI |
| `QueueView.swift` | Queue management UI |
| `SettingsView.swift` | API key settings |
| `AppState.swift` | Shared observable state |
| `AnthropicService.swift` | Anthropic API calls |
| `ImageProcessor.swift` | Resize + compress images |
| `Constants.swift` | Prompts, tones, lengths |
| `Models.swift` | Data types |

## Xcode Setup

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - Product Name: `LinkedInTool`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment: **iOS 17**
4. Delete the auto-generated `ContentView.swift`
5. Drag all `.swift` files from this folder into the Xcode project navigator
6. Make sure **"Copy items if needed"** is checked

## Requirements

- iOS 17+ (uses `onChange(of:)` two-arg syntax and `PhotosPicker`)
- Xcode 15+
- An [Anthropic API key](https://console.anthropic.com)

## How It Works

- **API key** is stored in `UserDefaults` (device-local, never transmitted elsewhere)
- **Queue** is persisted as JSON in `UserDefaults`
- **Images** are resized to max 1024px and JPEG-compressed before sending
- Direct HTTPS calls to `https://api.anthropic.com/v1/messages` via `URLSession`
- Model: `claude-sonnet-4-6`
