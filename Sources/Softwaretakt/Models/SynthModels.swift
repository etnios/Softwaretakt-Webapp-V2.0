import Foundation

// MARK: - Synthesis Engine Types
enum SynthEngineType: String, CaseIterable, Codable {
    case sample = "SAMPLE"
    case dvco = "DVCO"
    case dsaw = "DSAW"
    case dtone = "DTONE"
    case dualvco = "DUAL VCO"
    case analog = "ANALOG"
    case syRaw = "SY RAW"
    case syChip = "SY CHIP"
    case syDual = "SY DUAL"
    case fmOpal = "FM OPAL"
    case noise = "NOISE"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Synthesis Parameters
struct SynthParameters: Codable {
    // Basic parameters
    var pitch: Float = 0.0
    var tune: Float = 0.0
    var wave: Float = 0.5
    var sync: Float = 0.0
    
    // Filter parameters
    var filterCutoff: Float = 1000.0
    var filterResonance: Float = 1.0
    
    // Envelope parameters
    var attack: Float = 0.01
    var decay: Float = 0.3
    var sustain: Float = 0.6
    var release: Float = 0.8
    
    // FM parameters
    var fmAlgorithm: Int = 0
    var op1Ratio: Float = 1.0
    var op2Ratio: Float = 1.0
    var op3Ratio: Float = 1.0
    var op4Ratio: Float = 1.0
    var op1Level: Float = 1.0
    var op2Level: Float = 0.5
    var op3Level: Float = 0.5
    var op4Level: Float = 0.5
    var fmDepth: Float = 0.5
    var feedback: Float = 0.0
    
    init(
        pitch: Float = 0.0,
        tune: Float = 0.0,
        wave: Float = 0.5,
        sync: Float = 0.0,
        filterCutoff: Float = 1000.0,
        filterResonance: Float = 1.0,
        attack: Float = 0.01,
        decay: Float = 0.3,
        sustain: Float = 0.6,
        release: Float = 0.8,
        fmAlgorithm: Int = 0,
        op1Ratio: Float = 1.0,
        op2Ratio: Float = 1.0,
        op3Ratio: Float = 1.0,
        op4Ratio: Float = 1.0,
        op1Level: Float = 1.0,
        op2Level: Float = 0.5,
        op3Level: Float = 0.5,
        op4Level: Float = 0.5,
        fmDepth: Float = 0.5,
        feedback: Float = 0.0
    ) {
        self.pitch = pitch
        self.tune = tune
        self.wave = wave
        self.sync = sync
        self.filterCutoff = filterCutoff
        self.filterResonance = filterResonance
        self.attack = attack
        self.decay = decay
        self.sustain = sustain
        self.release = release
        self.fmAlgorithm = fmAlgorithm
        self.op1Ratio = op1Ratio
        self.op2Ratio = op2Ratio
        self.op3Ratio = op3Ratio
        self.op4Ratio = op4Ratio
        self.op1Level = op1Level
        self.op2Level = op2Level
        self.op3Level = op3Level
        self.op4Level = op4Level
        self.fmDepth = fmDepth
        self.feedback = feedback
    }
}

// MARK: - Extended Track Model for Synthesis
extension Track {
    var engineType: SynthEngineType {
        get {
            // In a real implementation, this would be determined from track configuration
            return .sample // Default to sample for now
        }
    }
    
    var synthParameters: SynthParameters {
        get {
            // In a real implementation, this would be stored in Core Data or similar
            return SynthParameters()
        }
        set {
            // Store synthesis parameters
        }
    }
}

// MARK: - Synthesis Preset Management
struct SynthPreset: Identifiable, Codable {
    var id = UUID()
    let name: String
    let engineType: SynthEngineType
    let parameters: SynthParameters
    let tags: [String]
    
    static let factory: [SynthPreset] = [
        // DVCO Presets
        SynthPreset(
            name: "Classic Saw Lead",
            engineType: .dvco,
            parameters: SynthParameters(
                pitch: 0, wave: 0.8, filterCutoff: 2000,
                attack: 0.01, decay: 0.3, sustain: 0.6, release: 0.8
            ),
            tags: ["lead", "classic", "bright"]
        ),
        SynthPreset(
            name: "Warm Pad",
            engineType: .dvco,
            parameters: SynthParameters(
                pitch: -12, wave: 0.3, filterCutoff: 800,
                attack: 1.2, decay: 1.0, sustain: 0.8, release: 2.0
            ),
            tags: ["pad", "warm", "ambient"]
        ),
        
        // DSAW Presets
        SynthPreset(
            name: "Sync Lead",
            engineType: .dsaw,
            parameters: SynthParameters(
                pitch: 0, sync: 0.6, filterCutoff: 3000,
                attack: 0.001, decay: 0.2, sustain: 0.3, release: 0.5
            ),
            tags: ["lead", "sync", "aggressive"]
        ),
        
        // Analog Presets
        SynthPreset(
            name: "Analog Bass",
            engineType: .analog,
            parameters: SynthParameters(
                pitch: -24, wave: 0.9, filterCutoff: 400,
                attack: 0.001, decay: 0.8, sustain: 0.2, release: 0.3
            ),
            tags: ["bass", "analog", "punchy"]
        ),
        
        // SY-CHIP Presets
        SynthPreset(
            name: "8-Bit Lead",
            engineType: .syChip,
            parameters: SynthParameters(
                pitch: 12, wave: 1.0, filterCutoff: 4000,
                attack: 0.001, decay: 0.1, sustain: 0.5, release: 0.2
            ),
            tags: ["chiptune", "retro", "bright"]
        ),
        
        // Noise Presets
        SynthPreset(
            name: "White Noise Snare",
            engineType: .noise,
            parameters: SynthParameters(
                filterCutoff: 2000, filterResonance: 5.0,
                attack: 0.001, decay: 0.15, sustain: 0.0, release: 0.1
            ),
            tags: ["percussion", "noise", "snare"]
        ),
        
        // FM-OPAL Presets (Opal-inspired)
        SynthPreset(
            name: "FM Bell",
            engineType: .fmOpal,
            parameters: SynthParameters(
                pitch: 0, filterCutoff: 8000, attack: 0.01, decay: 2.0, sustain: 0.3, release: 3.0,
                fmAlgorithm: 4, op1Ratio: 1.0, op2Ratio: 3.0,
                op1Level: 1.0, op2Level: 0.8, fmDepth: 0.7
            ),
            tags: ["fm", "bell", "opal", "digitone"]
        ),
        SynthPreset(
            name: "FM Bass",
            engineType: .fmOpal,
            parameters: SynthParameters(
                pitch: -12, filterCutoff: 1200, attack: 0.001, decay: 0.5, sustain: 0.4, release: 0.8,
                fmAlgorithm: 1, op1Ratio: 1.0, op2Ratio: 0.5,
                op1Level: 1.0, op2Level: 0.9, fmDepth: 0.6, feedback: 0.3
            ),
            tags: ["fm", "bass", "punchy", "digitone"]
        ),
        SynthPreset(
            name: "FM Metallic Lead",
            engineType: .fmOpal,
            parameters: SynthParameters(
                pitch: 12, filterCutoff: 5000, attack: 0.005, decay: 0.3, sustain: 0.6, release: 1.0,
                fmAlgorithm: 7, op1Ratio: 2.0, op2Ratio: 7.0,
                op3Ratio: 3.0, op1Level: 0.8, op2Level: 0.6, op3Level: 0.4,
                fmDepth: 0.9, feedback: 0.2
            ),
            tags: ["fm", "lead", "metallic", "bright"]
        ),
        SynthPreset(
            name: "FM Pad",
            engineType: .fmOpal,
            parameters: SynthParameters(
                pitch: -12, filterCutoff: 3000, attack: 1.5, decay: 2.0, sustain: 0.8, release: 4.0,
                fmAlgorithm: 12, op1Ratio: 1.0, op2Ratio: 2.0,
                op3Ratio: 1.5, op4Ratio: 0.5, op1Level: 0.7, op2Level: 0.5,
                op3Level: 0.6, op4Level: 0.3, fmDepth: 0.4
            ),
            tags: ["fm", "pad", "ambient", "warm"]
        ),
        SynthPreset(
            name: "FM Pluck",
            engineType: .fmOpal,
            parameters: SynthParameters(
                pitch: 0, filterCutoff: 4000, attack: 0.001, decay: 0.8, sustain: 0.1, release: 1.2,
                fmAlgorithm: 2, op1Ratio: 1.0, op2Ratio: 4.0,
                op1Level: 1.0, op2Level: 0.7, fmDepth: 0.8
            ),
            tags: ["fm", "pluck", "percussive", "digitone"]
        ),
        
        // 🔥 EXTREME FM PRESETS - For the "INSANE" sounds you love!
        SynthPreset(
            name: "FM CHAOS",
            engineType: .fmOpal,
            parameters: SynthParameters(
                pitch: 0, filterCutoff: 12000, attack: 0.001, decay: 0.2, sustain: 0.7, release: 0.5,
                fmAlgorithm: 32, op1Ratio: Float.pi, op2Ratio: 13.0,
                op3Ratio: 7.0, op4Ratio: 16.0, op1Level: 1.0, op2Level: 0.9,
                op3Level: 0.7, op4Level: 0.5, fmDepth: 1.0, feedback: 0.8
            ),
            tags: ["fm", "chaos", "extreme", "digital", "insane"]
        ),
        SynthPreset(
            name: "FM DIGITAL SCREAM",
            engineType: .fmOpal,
            parameters: SynthParameters(
                pitch: 12, filterCutoff: 15000, attack: 0.001, decay: 0.1, sustain: 0.9, release: 0.3,
                fmAlgorithm: 30, op1Ratio: 2.0, op2Ratio: 11.0,
                op3Ratio: 6.28, op4Ratio: 5.0, op1Level: 0.9, op2Level: 1.0,
                op3Level: 0.8, op4Level: 0.6, fmDepth: 0.95, feedback: 0.7
            ),
            tags: ["fm", "lead", "scream", "digital", "cutting"]
        ),
        SynthPreset(
            name: "FM CRYSTALLINE",
            engineType: .fmOpal,
            parameters: SynthParameters(
                pitch: 24, filterCutoff: 18000, attack: 0.005, decay: 0.8, sustain: 0.4, release: 2.0,
                fmAlgorithm: 26, op1Ratio: 4.0, op2Ratio: 7.0,
                op3Ratio: 11.0, op4Ratio: 2.0, op1Level: 0.8, op2Level: 0.7,
                op3Level: 0.5, op4Level: 0.9, fmDepth: 0.8, feedback: 0.4
            ),
            tags: ["fm", "crystal", "bright", "metallic", "high"]
        ),
        SynthPreset(
            name: "FM GLASS BREAK",
            engineType: .fmOpal,
            parameters: SynthParameters(
                pitch: 12, filterCutoff: 16000, attack: 0.001, decay: 0.05, sustain: 0.0, release: 0.8,
                fmAlgorithm: 25, op1Ratio: 1.41, op2Ratio: Float.pi,
                op3Ratio: 13.0, op4Ratio: 3.0, op1Level: 1.0, op2Level: 0.8,
                op3Level: 0.6, op4Level: 0.9, fmDepth: 0.9, feedback: 0.6
            ),
            tags: ["fm", "glass", "percussive", "attack", "bright"]
        ),
        SynthPreset(
            name: "FM ALIEN VOICE",
            engineType: .fmOpal,
            parameters: SynthParameters(
                pitch: -12, filterCutoff: 8000, attack: 0.1, decay: 1.0, sustain: 0.6, release: 1.5,
                fmAlgorithm: 29, op1Ratio: 0.5, op2Ratio: 7.0,
                op3Ratio: 1.41, op4Ratio: 11.0, op1Level: 0.9, op2Level: 0.7,
                op3Level: 0.8, op4Level: 0.4, fmDepth: 0.7, feedback: 0.9
            ),
            tags: ["fm", "alien", "voice", "weird", "modulated"]
        ),
    ]
}
