import Foundation

class Track: ObservableObject, Identifiable {
    let id: Int
    @Published var name: String
    @Published var volume: Float
    @Published var pan: Float
    @Published var isMuted: Bool
    @Published var isSoloed: Bool
    
    // Sample assignment
    @Published var currentSample: Sample?
    @Published var sampleSlices: [SampleSlice] = []
    
    // Effects parameters
    @Published var filterCutoff: Float = 1000.0
    @Published var filterResonance: Float = 1.0
    @Published var filterType: TrackFilterType = .lowPass
    @Published var delayTime: Float = 0.25
    @Published var delayFeedback: Float = 0.3
    @Published var delayMix: Float = 0.0
    @Published var reverbSize: Float = 0.5
    @Published var reverbDamping: Float = 0.5
    @Published var reverbMix: Float = 0.0
    
    // Sequencer pattern
    @Published var pattern: Pattern
    
    // Performance parameters
    @Published var pitch: Float = 0.0 // In semitones
    @Published var sampleStart: Float = 0.0 // 0.0 to 1.0
    @Published var sampleLength: Float = 1.0 // 0.0 to 1.0
    @Published var reverse: Bool = false
    
    init(id: Int, name: String, volume: Float = 0.8, pan: Float = 0.0, isMuted: Bool = false, isSoloed: Bool = false) {
        self.id = id
        self.name = name
        self.volume = volume
        self.pan = pan
        self.isMuted = isMuted
        self.isSoloed = isSoloed
        self.pattern = Pattern()
    }
    
    // MARK: - Sample Management
    
    func loadSample(_ sample: Sample) {
        currentSample = sample
        
        if sample.isSliced {
            sampleSlices = sample.getSlices()
        } else {
            sampleSlices = []
        }
    }
    
    func clearSample() {
        currentSample = nil
        sampleSlices = []
    }
    
    // MARK: - Effects Control
    
    func setFilter(cutoff: Float, resonance: Float, type: TrackFilterType) {
        filterCutoff = cutoff
        filterResonance = resonance
        filterType = type
    }
    
    func setDelay(time: Float, feedback: Float, mix: Float) {
        delayTime = time
        delayFeedback = feedback
        delayMix = mix
    }
    
    func setReverb(size: Float, damping: Float, mix: Float) {
        reverbSize = size
        reverbDamping = damping
        reverbMix = mix
    }
    
    // MARK: - Pattern Management
    
    func setStep(_ step: Int, active: Bool) {
        pattern.setStep(step, active: active)
    }
    
    func toggleStep(_ step: Int) {
        pattern.toggleStep(step)
    }
    
    func clearPattern() {
        pattern.clear()
    }
    
    func randomizePattern(density: Float = 0.5) {
        pattern.randomize(density: density)
    }
    
    // MARK: - Parameter Locks
    
    func setParameterLock(step: Int, parameter: ParameterLockType, value: Float) {
        pattern.setParameterLock(step: step, parameter: parameter, value: value)
    }
    
    func clearParameterLocks(step: Int) {
        pattern.clearParameterLocks(step: step)
    }
}

// Filter types
enum TrackFilterType: String, CaseIterable, Codable {
    case lowPass = "Low Pass"
    case highPass = "High Pass"
    case bandPass = "Band Pass"
    case notch = "Notch"
    
    var emoji: String {
        switch self {
        case .lowPass: return "📉"
        case .highPass: return "📈"
        case .bandPass: return "📊"
        case .notch: return "🔀"
        }
    }
}

// Parameter lock types
enum ParameterLockType: String, CaseIterable, Codable {
    case volume = "Volume"
    case pan = "Pan"
    case pitch = "Pitch"
    case filterCutoff = "Filter Cutoff"
    case filterResonance = "Filter Resonance"
    case sampleStart = "Sample Start"
    case sampleLength = "Sample Length"
    case delayMix = "Delay Mix"
    case reverbMix = "Reverb Mix"
    
    var emoji: String {
        switch self {
        case .volume: return "🔊"
        case .pan: return "↔️"
        case .pitch: return "🎵"
        case .filterCutoff: return "🎛️"
        case .filterResonance: return "🔄"
        case .sampleStart: return "▶️"
        case .sampleLength: return "📏"
        case .delayMix: return "🔁"
        case .reverbMix: return "🌊"
        }
    }
}
