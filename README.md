# 🎛️ Softwaretakt - iOS Digitakt-Style Sampler

A professional iOS sampling app inspired by the Elektron Digitakt, designed for iPad Pro with Push 2 MIDI controller integration.

## ✨ Features

- **64-Pad Interface** - Full Push 2 integration with visual feedback
- **Advanced Slicing** - Tap-to-slice with 64-bar loop support  
- **Real-time Controls** - 8 encoders for live parameter manipulation
- **Professional Audio** - Core Audio engine with low latency
- **Sample Management** - Import, organize, and edit samples
- **Pattern Sequencing** - 8-track step sequencer like Digitakt
- **Effects Chain** - Filters, delays, reverb per track
- **DJ Mode** - Hot cues and loop rolling capabilities

## 🎯 Target Devices

- **Primary**: iPad Pro (all sizes)
- **Controllers**: Ableton Push 2, Novation Launchkey 25
- **iOS**: 16.0+ required for latest Core Audio features

## 🛠️ Technical Stack

- **Swift 5.9+** - Modern iOS development
- **SwiftUI** - Declarative user interface
- **Core Audio** - Low-latency audio engine
- **Core MIDI** - Hardware controller integration
- **AudioKit** - Advanced audio processing library
- **AVFoundation** - Sample playback and recording

## 🚀 Getting Started

### Prerequisites
- **Xcode 15+** 
- **iOS 16+ device** or simulator
- **macOS 13+** for development
- **Apple Developer Account** (free tier sufficient for testing)

### Installation
1. Open `Softwaretakt.xcodeproj` in Xcode
2. Select your iPad Pro as the target device
3. Build and run (⌘+R)

### Hardware Setup
1. Connect Push 2 via USB-C to Lightning adapter
2. Connect Launchkey 25 via USB hub if needed  
3. Enable MIDI access in iOS Settings > Privacy & Security > Local Network
4. Launch Softwaretakt and verify controller connection

## 🎵 Quick Start Guide

### Basic Sampling
1. **Import samples** - Drag audio files into the app
2. **Select track** - Choose one of 8 available tracks
3. **Load sample** - Assign sample to selected track
4. **Play** - Tap pads on Push 2 or screen to trigger

### Slicing Workflow  
1. **Load long sample** (up to 64 bars)
2. **Enter slice mode** - Push 2 button or screen control
3. **Tap to slice** - Play sample and tap pads to create slice points
4. **Fine-tune** - Use encoders to adjust slice start/end points
5. **Save** - Store sliced sample for later use

### Push 2 Layout
- **Pads 1-16**: Trigger samples/slices for current track
- **Pads 17-32**: Set slice points (in slice mode)  
- **Pads 33-48**: Hot cues (in DJ mode)
- **Pads 49-64**: Loop rolls and effects triggers
- **8 Encoders**: Real-time parameter control
- **Touch Strip**: Crossfader/pitch bend

## 📁 Project Structure

```
Softwaretakt/
├── Sources/
│   ├── Softwaretakt/
│   │   ├── App/
│   │   │   ├── SoftwaretaktApp.swift      # Main app entry point
│   │   │   └── ContentView.swift          # Root view
│   │   ├── Views/
│   │   │   ├── PadGridView.swift          # 8x8 pad interface
│   │   │   ├── TrackControlView.swift     # Track parameters
│   │   │   ├── SampleBrowserView.swift    # Sample management
│   │   │   └── SequencerView.swift        # Pattern sequencer
│   │   ├── Audio/
│   │   │   ├── AudioEngine.swift          # Core audio processing
│   │   │   ├── SamplePlayer.swift         # Sample playback
│   │   │   ├── AudioEffects.swift         # Filter, delay, reverb
│   │   │   └── Slicer.swift              # Audio slicing engine
│   │   ├── MIDI/
│   │   │   ├── MIDIManager.swift          # MIDI input/output
│   │   │   ├── Push2Controller.swift      # Push 2 integration
│   │   │   └── LaunchkeyController.swift  # Launchkey integration
│   │   ├── Models/
│   │   │   ├── Sample.swift               # Sample data model
│   │   │   ├── Track.swift                # Track data model
│   │   │   ├── Pattern.swift              # Sequencer pattern
│   │   │   └── Project.swift              # Project management
│   │   └── Utilities/
│   │       ├── AudioUtilities.swift       # Audio helper functions
│   │       └── FileManager+Audio.swift    # File management
├── Tests/
│   └── SoftwaretaktTests/
└── Resources/
    ├── Samples/                           # Default sample library
    └── Presets/                           # Default patterns/settings
```

## 🎛️ Development Roadmap

### Phase 1: Core Engine ✅
- [x] Audio engine setup
- [x] Basic sample playback
- [x] MIDI input handling
- [x] Push 2 connection

### Phase 2: Sampling Features
- [ ] Sample browser and import
- [ ] Multi-sample support per track
- [ ] Basic slicing functionality
- [ ] Real-time pad triggering

### Phase 3: Sequencer
- [ ] Step sequencer (16 steps per pattern)
- [ ] Pattern chaining
- [ ] Parameter locks per step
- [ ] Swing and groove settings

### Phase 4: Effects & Polish
- [ ] Per-track effects (filter, delay, reverb)
- [ ] Performance optimizations
- [ ] UI/UX refinements
- [ ] Advanced slicing features

### Phase 5: DJ Features
- [ ] Hot cue system
- [ ] Loop rolling
- [ ] Crossfader implementation
- [ ] Beat matching tools

## 🤝 Contributing

This is a personal project, but feedback and suggestions are welcome!

## 📄 License

Personal project - not for commercial distribution.

---

**Built with ❤️ for music producers who miss their Digitakt!** 🎵
