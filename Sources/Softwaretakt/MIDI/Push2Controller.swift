import Foundation
import CoreMIDI

class Push2Controller {
    weak var audioEngine: AudioEngine?
    
    // Push 2 specific MIDI mappings
    private let padNoteStart: UInt8 = 36  // Push 2 pads start at note 36
    private let encoderCCStart: UInt8 = 71 // Push 2 encoders start at CC 71
    
    // Pad layout (8x8 grid)
    private let padGrid: [[UInt8]] = [
        [92, 93, 94, 95, 96, 97, 98, 99],
        [84, 85, 86, 87, 88, 89, 90, 91],
        [76, 77, 78, 79, 80, 81, 82, 83],
        [68, 69, 70, 71, 72, 73, 74, 75],
        [60, 61, 62, 63, 64, 65, 66, 67],
        [52, 53, 54, 55, 56, 57, 58, 59],
        [44, 45, 46, 47, 48, 49, 50, 51],
        [36, 37, 38, 39, 40, 41, 42, 43]
    ]
    
    // Current state
    private var selectedTrack: Int = 0
    private var currentMode: Push2Mode = .play
    
    enum Push2Mode {
        case play       // Normal pad triggering
        case slice      // Slice point creation
        case hotCue     // DJ hot cues
        case effects    // Effects and rolls
    }
    
    init(audioEngine: AudioEngine?) {
        self.audioEngine = audioEngine
        setupInitialState()
    }
    
    private func setupInitialState() {
        // Send initial LED states to Push 2
        // This would normally send SysEx messages to control the pad LEDs
        print("🎛️ Push 2 controller initialized")
    }
    
    @MainActor
    func handlePadPress(note: UInt8, velocity: UInt8) {
        guard let padIndex = getPadIndex(for: note) else { return }
        
        switch currentMode {
        case .play:
            handlePlayMode(padIndex: padIndex, velocity: velocity)
        case .slice:
            handleSliceMode(padIndex: padIndex, velocity: velocity)
        case .hotCue:
            handleHotCueMode(padIndex: padIndex, velocity: velocity)
        case .effects:
            handleEffectsMode(padIndex: padIndex, velocity: velocity)
        }
        
        // Update LED feedback
        updatePadLED(padIndex: padIndex, active: velocity > 0)
    }
    
    @MainActor
    private func handlePlayMode(padIndex: Int, velocity: UInt8) {
        let normalizedVelocity = Float(velocity) / 127.0
        
        // Map pad to MIDI note for synthesis
        let baseNote: UInt8 = 36 // C2
        let midiNote = baseNote + UInt8(padIndex)
        
        // Check if current track is using synthesis
        let engineType = audioEngine?.getEngineType(forTrack: selectedTrack) ?? .sample
        
        if engineType == .sample {
            // Traditional sample triggering
            audioEngine?.triggerSample(track: selectedTrack, padIndex: padIndex)
        } else {
            // Synthesis triggering with MIDI note
            audioEngine?.triggerTrack(selectedTrack, note: midiNote, velocity: normalizedVelocity, padIndex: padIndex)
        }
        
        print("🎹 Push 2 Pad \(padIndex + 1) (\(engineType.displayName)): Note \(midiNote), Vel \(normalizedVelocity)")
        updatePadLED(padIndex: padIndex, active: true)
    }
    
    private func handleSliceMode(padIndex: Int, velocity: UInt8) {
        // Create slice points
        // This would integrate with the slicing engine
        print("✂️ Push 2 Slice point created at pad \(padIndex + 1)")
    }
    
    private func handleHotCueMode(padIndex: Int, velocity: UInt8) {
        // DJ hot cue functionality
        print("🎧 Push 2 Hot cue \(padIndex + 1) triggered")
    }
    
    private func handleEffectsMode(padIndex: Int, velocity: UInt8) {
        // Effects and loop rolls
        print("🎚️ Push 2 Effect \(padIndex + 1) triggered")
    }
    
    @MainActor
    func handleEncoderChange(encoder: UInt8, value: UInt8) {
        let normalizedValue = Float(value) / 127.0
        let encoderIndex = Int(encoder - encoderCCStart)
        
        guard encoderIndex >= 0 && encoderIndex < 8 else { return }
        
        // Map encoders to track parameters
        switch encoderIndex {
        case 0: // Volume
            audioEngine?.setTrackVolume(selectedTrack, volume: normalizedValue)
        case 1: // Pan
            let panValue = (normalizedValue * 2.0) - 1.0
            audioEngine?.setTrackPan(selectedTrack, pan: panValue)
        case 2: // Filter Cutoff
            let cutoffValue = 20.0 + (normalizedValue * 19980.0)
            audioEngine?.setFilterCutoff(cutoffValue, forTrack: selectedTrack)
        case 3: // Filter Resonance
            let resonanceValue = normalizedValue * 30.0
            audioEngine?.setFilterResonance(resonanceValue, forTrack: selectedTrack)
        case 4: // Sample Start
            print("🎛️ Sample Start: \(normalizedValue)")
        case 5: // Sample Length
            print("🎛️ Sample Length: \(normalizedValue)")
        case 6: // Pitch
            print("🎛️ Pitch: \(normalizedValue)")
        case 7: // Time Stretch
            print("🎛️ Time Stretch: \(normalizedValue)")
        default:
            break
        }
        
        print("🎛️ Push 2 Encoder \(encoderIndex + 1): \(normalizedValue)")
    }
    
    func handleButtonPress(button: UInt8, pressed: Bool) {
        // Handle various Push 2 buttons
        switch button {
        case 44: // Track select buttons (example)
            if pressed {
                selectedTrack = (selectedTrack + 1) % 16  // Cycle through 16 tracks
                print("🎯 Push 2 selected track: \(selectedTrack + 1)")
            }
        case 85: // Mode buttons
            if pressed {
                switchMode()
            }
        default:
            break
        }
    }
    
    private func switchMode() {
        switch currentMode {
        case .play:
            currentMode = .slice
        case .slice:
            currentMode = .hotCue
        case .hotCue:
            currentMode = .effects
        case .effects:
            currentMode = .play
        }
        
        print("🔄 Push 2 mode switched to: \(currentMode)")
        updateAllPadLEDs()
    }
    
    private func getPadIndex(for note: UInt8) -> Int? {
        for (rowIndex, row) in padGrid.enumerated() {
            for (colIndex, padNote) in row.enumerated() {
                if padNote == note {
                    return rowIndex * 8 + colIndex
                }
            }
        }
        return nil
    }
    
    private func updatePadLED(padIndex: Int, active: Bool) {
        // Send MIDI message to update pad LED
        // This would normally send SysEx or Note On messages to control LEDs
        let color = getPadColor(padIndex: padIndex, active: active)
        print("💡 Push 2 Pad \(padIndex + 1) LED: \(color)")
    }
    
    private func updateAllPadLEDs() {
        // Update all pad LEDs based on current mode
        for i in 0..<64 {
            updatePadLED(padIndex: i, active: false)
        }
    }
    
    private func getPadColor(padIndex: Int, active: Bool) -> String {
        if !active { return "off" }
        
        switch currentMode {
        case .play:
            return "cyan"
        case .slice:
            return "purple"
        case .hotCue:
            return "orange"
        case .effects:
            return "green"
        }
    }
}

// Extension for sending MIDI data to Push 2
extension Push2Controller {
    func sendMIDIData(_ data: [UInt8]) {
        // This would send MIDI data to the Push 2
        // Implementation would use Core MIDI to send SysEx or other messages
        print("📤 Sending MIDI to Push 2: \(data)")
    }
    
    func sendSysEx(_ data: [UInt8]) {
        // Send SysEx message for advanced Push 2 control
        var sysexData: [UInt8] = [0xF0] // SysEx start
        sysexData.append(contentsOf: data)
        sysexData.append(0xF7) // SysEx end
        
        sendMIDIData(sysexData)
    }
}
