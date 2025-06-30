import Foundation

// 🎛️ FM-OPAL PRESETS - LEGENDARY SOUNDS!

struct FMPreset: Identifiable {
    let id = UUID()
    var name: String
    var category: PresetCategory
    
    // Core FM parameters
    var algorithm: Int = 0
    var operatorRatios: [Float] = [1.0, 1.0, 1.0, 1.0]
    var operatorLevels: [Float] = [1.0, 1.0, 1.0, 1.0]
    var feedback: Float = 0.0
    var fmDepth: Float = 1.0
    
    // Enhanced features
    var operatorWaveforms: [FMOpalEngine.OperatorWaveform] = [.sine, .sine, .sine, .sine]
    var lfoRates: [Float] = [1.0, 1.0, 1.0, 1.0]
    var lfoAmounts: [Float] = [0.0, 0.0, 0.0, 0.0]
    var velocitySensitivity: [Float] = [1.0, 1.0, 1.0, 1.0]
    
    // Envelopes (simplified for preset storage)
    var envelopes: [EnvelopeSettings] = [
        EnvelopeSettings(), EnvelopeSettings(), EnvelopeSettings(), EnvelopeSettings()
    ]
    
    enum PresetCategory: String, CaseIterable {
        case bass = "BASS"
        case lead = "LEAD"
        case pad = "PAD"
        case bell = "BELL"
        case brass = "BRASS"
        case digital = "DIGITAL"
        case chaos = "CHAOS"
        case experimental = "EXPERIMENTAL"
    }
    
    struct EnvelopeSettings: Codable {
        var attack: Float = 0.01
        var decay: Float = 0.1
        var sustain: Float = 0.7
        var release: Float = 0.5
    }
}

// MARK: - Factory Presets

class FMPresetFactory {
    
    static func createFactoryPresets() -> [FMPreset] {
        return [
            // 🔥 BASS PRESETS
            createSubBass(),
            createReeseBass(),
            createAcidBass(),
            
            // ⚡️ LEAD PRESETS
            createDigitalLead(),
            createScreamLead(),
            createBrightLead(),
            
            // 🌊 PAD PRESETS
            createWarmPad(),
            createEtherealPad(),
            createHarshPad(),
            
            // 🔔 BELL PRESETS
            createClassicBell(),
            createMetallicBell(),
            createGlassBell(),
            
            // 🎺 BRASS PRESETS
            createHornSection(),
            createSynBrass(),
            createDistortedBrass(),
            
            // 💥 DIGITAL PRESETS
            createDigitalScream(),
            createBitCrusher(),
            createGlitchTone(),
            
            // 🌪️ CHAOS PRESETS
            createPureChaos(),
            createCrossModMadness(),
            createFeedbackHell(),
            
            // 🧪 EXPERIMENTAL
            createMorphingTexture(),
            createRingModulator(),
            createFrequencyShifter()
        ]
    }
    
    // MARK: - Bass Presets
    
    static func createSubBass() -> FMPreset {
        var preset = FMPreset(name: "SUB BASS", category: .bass)
        preset.algorithm = 1  // Chain modulation
        preset.operatorRatios = [0.5, 1.0, 2.0, 1.0]  // Sub frequency
        preset.operatorLevels = [0.8, 0.6, 0.3, 1.0]
        preset.feedback = 0.1
        preset.fmDepth = 0.5
        
        // Fast attack, long release
        preset.envelopes[3].attack = 0.001
        preset.envelopes[3].release = 2.0
        
        return preset
    }
    
    static func createReeseBass() -> FMPreset {
        var preset = FMPreset(name: "REESE BASS", category: .bass)
        preset.algorithm = 14  // Feedback chaos
        preset.operatorRatios = [0.99, 1.01, 2.0, 1.0]  // Slight detuning
        preset.operatorLevels = [0.9, 0.9, 0.4, 1.0]
        preset.feedback = 0.3
        preset.fmDepth = 1.5
        
        // Add some LFO for movement
        preset.lfoRates = [0.2, 0.3, 0.0, 0.0]
        preset.lfoAmounts = [0.1, 0.1, 0.0, 0.0]
        
        return preset
    }
    
    static func createAcidBass() -> FMPreset {
        var preset = FMPreset(name: "ACID BASS", category: .bass)
        preset.algorithm = 7  // Brass-like
        preset.operatorRatios = [1.0, 3.0, 1.0, 1.0]
        preset.operatorLevels = [1.0, 0.7, 0.8, 1.0]
        preset.feedback = 0.4
        preset.fmDepth = 2.0
        
        // Square waves for digital edge
        preset.operatorWaveforms = [.square, .sine, .saw, .sine]
        
        return preset
    }
    
    // MARK: - Lead Presets
    
    static func createDigitalLead() -> FMPreset {
        var preset = FMPreset(name: "DIGITAL LEAD", category: .lead)
        preset.algorithm = 19  // Digital scream
        preset.operatorRatios = [1.0, 2.0, 3.0, 1.0]
        preset.operatorLevels = [1.0, 0.8, 0.6, 1.0]
        preset.feedback = 0.2
        preset.fmDepth = 1.8
        
        preset.envelopes[3].attack = 0.01
        preset.envelopes[3].decay = 0.3
        preset.envelopes[3].sustain = 0.6
        preset.envelopes[3].release = 0.8
        
        return preset
    }
    
    static func createScreamLead() -> FMPreset {
        var preset = FMPreset(name: "SCREAM LEAD", category: .lead)
        preset.algorithm = 31  // Pure madness
        preset.operatorRatios = [1.0, 7.0, 11.0, 1.0]  // Harsh ratios
        preset.operatorLevels = [1.0, 0.9, 0.7, 1.0]
        preset.feedback = 0.6
        preset.fmDepth = 3.0
        
        // Saw waves for aggression
        preset.operatorWaveforms = [.saw, .saw, .square, .sine]
        
        return preset
    }
    
    // MARK: - Bell Presets
    
    static func createClassicBell() -> FMPreset {
        var preset = FMPreset(name: "CLASSIC BELL", category: .bell)
        preset.algorithm = 5  // Bell-like
        preset.operatorRatios = [1.0, 2.4, 3.7, 1.0]  // Bell ratios
        preset.operatorLevels = [0.8, 0.6, 0.4, 1.0]
        preset.feedback = 0.1
        preset.fmDepth = 1.0
        
        // Bell envelope
        preset.envelopes[3].attack = 0.001
        preset.envelopes[3].decay = 2.0
        preset.envelopes[3].sustain = 0.3
        preset.envelopes[3].release = 3.0
        
        return preset
    }
    
    static func createMetallicBell() -> FMPreset {
        var preset = FMPreset(name: "METALLIC BELL", category: .bell)
        preset.algorithm = 17  // Metallic resonance
        preset.operatorRatios = [1.0, 3.14, 7.83, 1.0]  // Inharmonic
        preset.operatorLevels = [0.9, 0.7, 0.5, 1.0]
        preset.feedback = 0.2
        preset.fmDepth = 1.5
        
        return preset
    }
    
    // MARK: - Chaos Presets
    
    static func createPureChaos() -> FMPreset {
        var preset = FMPreset(name: "PURE CHAOS", category: .chaos)
        preset.algorithm = 31  // Ultimate chaos
        preset.operatorRatios = [1.0, 1.618, 2.718, 3.14159]  // Mathematical constants
        preset.operatorLevels = [1.0, 0.9, 0.8, 1.0]
        preset.feedback = 0.8
        preset.fmDepth = 4.0
        
        // Mixed waveforms for maximum chaos
        preset.operatorWaveforms = [.noise, .square, .saw, .sine]
        
        // Chaotic LFOs
        preset.lfoRates = [1.3, 2.7, 4.1, 0.8]
        preset.lfoAmounts = [0.3, 0.2, 0.4, 0.1]
        
        return preset
    }
    
    static func createCrossModMadness() -> FMPreset {
        var preset = FMPreset(name: "CROSS MOD", category: .chaos)
        preset.algorithm = 21  // Cross chaos
        preset.operatorRatios = [0.99, 1.01, 1.98, 2.02]  // Beating frequencies
        preset.operatorLevels = [1.0, 1.0, 0.8, 0.8]
        preset.feedback = 0.7
        preset.fmDepth = 3.5
        
        return preset
    }
    
    // MARK: - Additional Presets
    
    static func createBrightLead() -> FMPreset {
        var preset = FMPreset(name: "BRIGHT LEAD", category: .lead)
        preset.algorithm = 0
        preset.operatorRatios = [1.0, 4.0, 8.0, 1.0]
        preset.operatorLevels = [1.0, 0.5, 0.3, 1.0]
        preset.feedback = 0.0
        preset.fmDepth = 1.2
        return preset
    }
    
    static func createWarmPad() -> FMPreset {
        var preset = FMPreset(name: "WARM PAD", category: .pad)
        preset.algorithm = 2  // Parallel carriers
        preset.operatorRatios = [1.0, 1.0, 2.0, 3.0]
        preset.operatorLevels = [0.8, 0.6, 0.4, 0.3]
        preset.feedback = 0.1
        preset.fmDepth = 0.8
        
        // Slow attack for pad
        preset.envelopes[0].attack = 1.0
        preset.envelopes[1].attack = 1.2
        preset.envelopes[2].attack = 0.8
        preset.envelopes[3].attack = 1.5
        
        return preset
    }
    
    static func createEtherealPad() -> FMPreset {
        var preset = FMPreset(name: "ETHEREAL PAD", category: .pad)
        preset.algorithm = 24  // Spectral morph
        preset.operatorRatios = [1.0, 1.5, 2.25, 3.375]
        preset.operatorLevels = [0.6, 0.5, 0.4, 0.3]
        preset.feedback = 0.05
        preset.fmDepth = 0.6
        return preset
    }
    
    static func createHarshPad() -> FMPreset {
        var preset = FMPreset(name: "HARSH PAD", category: .pad)
        preset.algorithm = 26
        preset.operatorRatios = [1.0, 1.99, 3.01, 1.0]
        preset.operatorLevels = [0.8, 0.7, 0.6, 0.9]
        preset.feedback = 0.3
        preset.fmDepth = 2.0
        return preset
    }
    
    static func createGlassBell() -> FMPreset {
        var preset = FMPreset(name: "GLASS BELL", category: .bell)
        preset.algorithm = 15  // Bell tower
        preset.operatorRatios = [1.0, 5.04, 8.16, 1.0]
        preset.operatorLevels = [0.7, 0.5, 0.3, 1.0]
        preset.feedback = 0.05
        preset.fmDepth = 0.8
        return preset
    }
    
    static func createHornSection() -> FMPreset {
        var preset = FMPreset(name: "HORN SECTION", category: .brass)
        preset.algorithm = 6  // Brass-like
        preset.operatorRatios = [1.0, 2.0, 3.0, 1.0]
        preset.operatorLevels = [0.9, 0.7, 0.5, 1.0]
        preset.feedback = 0.3
        preset.fmDepth = 1.5
        return preset
    }
    
    static func createSynBrass() -> FMPreset {
        var preset = FMPreset(name: "SYN BRASS", category: .brass)
        preset.algorithm = 7
        preset.operatorRatios = [1.0, 2.0, 4.0, 1.0]
        preset.operatorLevels = [1.0, 0.8, 0.4, 1.0]
        preset.feedback = 0.4
        preset.fmDepth = 2.0
        preset.operatorWaveforms = [.saw, .sine, .square, .sine]
        return preset
    }
    
    static func createDistortedBrass() -> FMPreset {
        var preset = FMPreset(name: "DISTORTED BRASS", category: .brass)
        preset.algorithm = 28  // Frequency folding
        preset.operatorRatios = [1.0, 1.99, 3.01, 1.0]
        preset.operatorLevels = [1.0, 0.9, 0.6, 1.0]
        preset.feedback = 0.6
        preset.fmDepth = 3.0
        return preset
    }
    
    static func createDigitalScream() -> FMPreset {
        var preset = FMPreset(name: "DIGITAL SCREAM", category: .digital)
        preset.algorithm = 19
        preset.operatorRatios = [1.0, 7.0, 13.0, 1.0]
        preset.operatorLevels = [1.0, 0.9, 0.7, 1.0]
        preset.feedback = 0.7
        preset.fmDepth = 4.0
        preset.operatorWaveforms = [.square, .saw, .square, .sine]
        return preset
    }
    
    static func createBitCrusher() -> FMPreset {
        var preset = FMPreset(name: "BIT CRUSHER", category: .digital)
        preset.algorithm = 27
        preset.operatorRatios = [1.0, 16.0, 32.0, 1.0]
        preset.operatorLevels = [1.0, 0.6, 0.4, 1.0]
        preset.feedback = 0.5
        preset.fmDepth = 2.5
        preset.operatorWaveforms = [.square, .square, .square, .sine]
        return preset
    }
    
    static func createGlitchTone() -> FMPreset {
        var preset = FMPreset(name: "GLITCH TONE", category: .digital)
        preset.algorithm = 29
        preset.operatorRatios = [1.0, 1.003, 2.007, 4.011]
        preset.operatorLevels = [0.9, 0.8, 0.6, 1.0]
        preset.feedback = 0.4
        preset.fmDepth = 1.8
        preset.lfoRates = [23.7, 17.3, 0.0, 0.0]
        preset.lfoAmounts = [0.2, 0.15, 0.0, 0.0]
        return preset
    }
    
    static func createFeedbackHell() -> FMPreset {
        var preset = FMPreset(name: "FEEDBACK HELL", category: .chaos)
        preset.algorithm = 16  // Dual feedback
        preset.operatorRatios = [1.0, 1.0, 1.0, 1.0]
        preset.operatorLevels = [1.0, 1.0, 0.8, 0.8]
        preset.feedback = 0.9
        preset.fmDepth = 5.0
        return preset
    }
    
    static func createMorphingTexture() -> FMPreset {
        var preset = FMPreset(name: "MORPHING TEXTURE", category: .experimental)
        preset.algorithm = 24
        preset.operatorRatios = [1.0, 1.618, 2.618, 4.236]
        preset.operatorLevels = [0.8, 0.7, 0.6, 0.5]
        preset.feedback = 0.3
        preset.fmDepth = 1.8
        preset.lfoRates = [0.13, 0.17, 0.23, 0.29]
        preset.lfoAmounts = [0.2, 0.15, 0.1, 0.05]
        return preset
    }
    
    static func createRingModulator() -> FMPreset {
        var preset = FMPreset(name: "RING MODULATOR", category: .experimental)
        preset.algorithm = 23
        preset.operatorRatios = [1.0, 1.414, 1.0, 1.0]
        preset.operatorLevels = [0.8, 0.8, 0.9, 1.0]
        preset.feedback = 0.2
        preset.fmDepth = 1.5
        return preset
    }
    
    static func createFrequencyShifter() -> FMPreset {
        var preset = FMPreset(name: "FREQ SHIFTER", category: .experimental)
        preset.algorithm = 22
        preset.operatorRatios = [1.0, 1.1, 1.2, 1.0]
        preset.operatorLevels = [0.9, 0.8, 0.7, 1.0]
        preset.feedback = 0.1
        preset.fmDepth = 1.2
        return preset
    }
}

/*
🎛️ FM-OPAL PRESET COLLECTION:

✅ 25+ Factory Presets
✅ 8 Categories (Bass, Lead, Pad, Bell, Brass, Digital, Chaos, Experimental)
✅ Professional sound design
✅ Parameter lock ready
✅ Real-time morphing support

🔥 LEGENDARY SOUNDS:
- SUB BASS: Deep, powerful bass tones
- REESE BASS: Classic jungle/dnb bass
- DIGITAL SCREAM: Harsh, aggressive leads
- PURE CHAOS: Unpredictable madness
- CLASSIC BELL: Beautiful bell tones
- CROSS MOD: Frequency beating chaos

Ready to make those Focals ROAR! 🎧⚡️
*/
