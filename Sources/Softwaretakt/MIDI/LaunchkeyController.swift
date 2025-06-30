import Foundation
import CoreMIDI

class LaunchkeyController {
    weak var audioEngine: AudioEngine?
    
    // Launchkey 25 MIDI mappings
    private let keyStart: UInt8 = 36  // Keys start at C2
    private let padStart: UInt8 = 96  // Pads start at C7
    private let knobCCStart: UInt8 = 21 // Knobs start at CC 21
    private let faderCCStart: UInt8 = 41 // Faders start at CC 41
    
    // Current state
    private var selectedTrack: Int = 0
    private var octaveShift: Int = 0
    
    init(audioEngine: AudioEngine?) {
        self.audioEngine = audioEngine
        setupInitialState()
    }
    
    private func setupInitialState() {
        print("🎹 Launchkey 25 controller initialized")
    }
    
    @MainActor
    func handleKeyPress(note: UInt8, velocity: UInt8) {
        let keyIndex = Int(note - keyStart) + (octaveShift * 12)
        
        if velocity > 0 {
            // Play sample chromatically
            playChromatic(keyIndex: keyIndex, velocity: velocity)
        } else {
            // Key release - could stop sustained samples
            stopChromatic(keyIndex: keyIndex)
        }
    }
    
    @MainActor
    func handlePadPress(note: UInt8, velocity: UInt8) {
        let padIndex = Int(note - padStart)
        
        guard padIndex >= 0 && padIndex < 16 else { return }
        
        if velocity > 0 {
            // Trigger sample on selected track
            audioEngine?.triggerSample(track: selectedTrack, padIndex: padIndex)
            print("🥁 Launchkey Pad \(padIndex + 1) triggered on track \(selectedTrack + 1)")
        }
    }
    
    @MainActor
    func handleKnobChange(knob: UInt8, value: UInt8) {
        let normalizedValue = Float(value) / 127.0
        let knobIndex = Int(knob - knobCCStart)
        
        guard knobIndex >= 0 && knobIndex < 8 else { return }
        
        // Map knobs to track parameters
        switch knobIndex {
        case 0: // Track Volume
            audioEngine?.setTrackVolume(selectedTrack, volume: normalizedValue)
        case 1: // Track Pan
            let panValue = (normalizedValue * 2.0) - 1.0
            audioEngine?.setTrackPan(selectedTrack, pan: panValue)
        case 2: // Filter Cutoff
            let cutoffValue = 20.0 + (normalizedValue * 19980.0)
            audioEngine?.setFilterCutoff(cutoffValue, forTrack: selectedTrack)
        case 3: // Filter Resonance
            let resonanceValue = normalizedValue * 30.0
            audioEngine?.setFilterResonance(resonanceValue, forTrack: selectedTrack)
        case 4: // Send/Return Level
            print("🎛️ Send Level: \(normalizedValue)")
        case 5: // Attack
            print("🎛️ Attack: \(normalizedValue)")
        case 6: // Decay
            print("🎛️ Decay: \(normalizedValue)")
        case 7: // Release
            print("🎛️ Release: \(normalizedValue)")
        default:
            break
        }
        
        print("🎛️ Launchkey Knob \(knobIndex + 1): \(normalizedValue)")
    }
    
    @MainActor
    func handleFaderChange(fader: UInt8, value: UInt8) {
        let normalizedValue = Float(value) / 127.0
        let faderIndex = Int(fader - faderCCStart)
        
        guard faderIndex >= 0 && faderIndex < 9 else { return }
        
        if faderIndex < 16 {
            // Track faders (0-15) - note: Launchkey only has 9 faders, so this maps to first 8 tracks + master
            if faderIndex < 8 {
                audioEngine?.setTrackVolume(faderIndex, volume: normalizedValue)
                print("🎚️ Launchkey Track \(faderIndex + 1) volume: \(normalizedValue)")
            }
        } else {
            // Master fader
            print("🎚️ Launchkey Master volume: \(normalizedValue)")
        }
    }
    
    func handleTransportButton(button: UInt8, pressed: Bool) {
        guard pressed else { return }
        
        switch button {
        case 115: // Play button
            print("▶️ Launchkey Play pressed")
            // Start sequencer
        case 116: // Stop button
            print("⏹️ Launchkey Stop pressed")
            // Stop sequencer
        case 117: // Record button
            print("⏺️ Launchkey Record pressed")
            // Start recording
        case 118: // Loop button
            print("🔄 Launchkey Loop pressed")
            // Toggle loop mode
        default:
            break
        }
    }
    
    func handleFunctionButton(button: UInt8, pressed: Bool) {
        guard pressed else { return }
        
        switch button {
        case 104: // Track Left
            selectedTrack = max(0, selectedTrack - 1)
            print("◀️ Launchkey Track \(selectedTrack + 1) selected")
        case 105: // Track Right
            selectedTrack = min(15, selectedTrack + 1)
            print("▶️ Launchkey Track \(selectedTrack + 1) selected")
        case 106: // Octave Down
            octaveShift = max(-2, octaveShift - 1)
            print("🔽 Launchkey Octave: \(octaveShift)")
        case 107: // Octave Up
            octaveShift = min(2, octaveShift + 1)
            print("🔼 Launchkey Octave: \(octaveShift)")
        default:
            break
        }
    }
    
    @MainActor
    private func playChromatic(keyIndex: Int, velocity: UInt8) {
        // Play current sample chromatically across keyboard
        // This would pitch the sample up/down based on key position
        let semitoneOffset = keyIndex - 12 // C3 as root
        
        // Calculate pitch multiplier (2^(semitones/12))
        let pitchRatio = pow(2.0, Float(semitoneOffset) / 12.0)
        
        print("🎹 Launchkey Key \(keyIndex): pitch ratio \(pitchRatio)")
        
        // Trigger sample with pitch adjustment
        audioEngine?.triggerSample(track: selectedTrack, padIndex: 0)
        // Note: Pitch adjustment would be implemented in the audio engine
    }
    
    private func stopChromatic(keyIndex: Int) {
        // Stop chromatic sample if it's sustained
        print("🎹 Launchkey Key \(keyIndex) released")
    }
}

// Extension for LED feedback
extension LaunchkeyController {
    func updatePadLEDs() {
        // Update pad LEDs based on current state
        for i in 0..<16 {
            updatePadLED(index: i, active: false)
        }
    }
    
    private func updatePadLED(index: Int, active: Bool) {
        // Send MIDI Note On to control pad LED
        let _ = padStart + UInt8(index)
        let _: UInt8 = active ? 127 : 0
        
        print("💡 Launchkey Pad \(index + 1) LED: \(active ? "on" : "off")")
        // Implementation would send actual MIDI data
    }
}
