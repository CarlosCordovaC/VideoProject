# VideoProject 🎬

> A native iOS app that connects directly to the Brightcove Video Cloud API, 
> allowing users to manage, consume and upload video content in a TikTok-style feed — securely and natively.

## ✨ Features
- 🎬 Full-screen video feed with autoplay, pause, mute and progress bar
- 🔐 Secure login with Brightcove OAuth 2.0 + iOS Keychain
- ✏️ Edit video name, short and long description
- 🗑️ Delete videos directly from your account
- 📤 Upload videos from your phone via Dynamic Ingest API
- 🔍 Search videos powered by the CMS API
- 📱 Built entirely with SwiftUI

## 🛠️ Technologies
| Technology | Purpose |
|---|---|
| Swift / SwiftUI | Native iOS UI |
| AVFoundation / AVKit | Video playback |
| Brightcove CMS API | Fetch, edit and delete videos |
| Brightcove Dynamic Ingest API | Upload videos to S3 |
| Brightcove OAuth 2.0 | Authentication |
| iOS Keychain | Secure credential storage |
| async/await | Modern Swift concurrency |

## ⚙️ The Process
The app started as an experiment to understand how the Brightcove Video Cloud API works. 
The first version had major issues — all video sources were being fetched simultaneously 
on launch, causing the app to crash.

The rebuild focused on three things:
1. **Async architecture** — Migrated all network calls to async/await with TaskGroup
2. **Lazy loading** — Video sources fetched on demand as the user scrolls
3. **Security** — Credentials moved from hardcoded strings to iOS Keychain

## 📚 What I Learned
- How OAuth 2.0 client_credentials flow works in a real API
- How to manage concurrency in Swift with async/await and TaskGroup
- How AVPlayer handles video playback and lifecycle in SwiftUI
- How the Brightcove Dynamic Ingest pipeline works end to end
- How to store sensitive data securely using iOS Keychain

## 🚀 How It Could Be Improved
- [ ] Backend proxy to avoid exposing credentials in the client
- [ ] Role-based access — Admin vs read-only Client
- [ ] Audio track selector for multi-language videos
- [ ] Seek bar — drag to skip forward/backward
- [ ] Grid view to browse videos

## 📸 Demo
[![Demo Video](https://img.youtube.com/vi/NxpaHXtrUto/maxresdefault.jpg)](https://youtube.com/shorts/NxpaHXtrUto)
> Click the image to watch the full demo


## 👤 Author
**Carlos Camberos**
- GitHub: [@CarlosCordovaC](https://github.com/CarlosCordovaC)
- Email: carloscordovac@outlook.es
