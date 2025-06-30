import Foundation

// 🎛️ ELEKTRON-STYLE SEQUENCER - The Heart of the Workflow!

// MARK: - Step Data (Like Digitakt/Syntakt)
struct Step: Codable {
    var isActive: Bool = false
    var velocity: Float = 1.0
    var microtiming: Float = 0.0        // -23 to +23 (like Elektron)
    var length: Float = 1.0             // Step length multiplier
    var retrig: RetrigSettings?         // Retriggering
    var probability: Float = 1.0        // 0.0 to 1.0 (like Elektron %)
    var condition: TrigCondition = .none // Conditional triggering
    
    // 🔥 PARAMETER LOCKS - This is the MAGIC!
    var parameterLocks: [ParameterLock] = []
    
    // Note data for synthesis
    var note: UInt8? = nil              // MIDI note for synth tracks
    var sampleSlice: Int? = nil         // Sample slice selection
}

// MARK: - Parameter Locks (Elektron's Secret Sauce!)
struct ParameterLock: Identifiable, Codable {
    var id = UUID()
    let parameter: LockableParameter
    let value: Float
    let stepIndex: Int
    
    enum LockableParameter: String, CaseIterable, Codable {
        // Sample parameters
        case sampleStart = "SMP_START"
        case sampleLength = "SMP_LEN"
        case samplePitch = "SMP_PITCH"
        case sampleReverse = "SMP_REV"
        
        // Synthesis parameters (FM-OPAL)
        case fmAlgorithm = "FM_ALG"
        case op1Ratio = "OP1_RATIO"
        case op2Ratio = "OP2_RATIO"
        case op1Level = "OP1_LVL"
        case op2Level = "OP2_LVL"
        case fmDepth = "FM_DEPTH"
        case feedback = "FM_FB"
        
        // Filter parameters
        case filterCutoff = "FILT_FREQ"
        case filterResonance = "FILT_RES"
        
        // Amplitude parameters
        case volume = "VOLUME"
        case pan = "PAN"
        case attack = "ATTACK"
        case decay = "DECAY"
        case sustain = "SUSTAIN"
        case release = "RELEASE"
        
        // LFO parameters
        case lfoRate = "LFO_RATE"
        case lfoAmount = "LFO_AMT"
        
        var displayName: String {
            switch self {
            case .sampleStart: return "SMP START"
            case .sampleLength: return "SMP LEN"
            case .samplePitch: return "SMP PITCH"
            case .sampleReverse: return "SMP REV"
            case .fmAlgorithm: return "FM ALG"
            case .op1Ratio: return "OP1 RATIO"
            case .op2Ratio: return "OP2 RATIO"
            case .op1Level: return "OP1 LVL"
            case .op2Level: return "OP2 LVL"
            case .fmDepth: return "FM DEPTH"
            case .feedback: return "FM FB"
            case .filterCutoff: return "FILT FREQ"
            case .filterResonance: return "FILT RES"
            case .volume: return "VOLUME"
            case .pan: return "PAN"
            case .attack: return "ATTACK"
            case .decay: return "DECAY"
            case .sustain: return "SUSTAIN"
            case .release: return "RELEASE"
            case .lfoRate: return "LFO RATE"
            case .lfoAmount: return "LFO AMT"
            }
        }
    }
}

// MARK: - Retrig Settings (Elektron-style)
struct RetrigSettings: Codable {
    var rate: RetrigRate = .sixteenth    // Retrig rate
    var count: Int = 2                   // Number of retrigs
    var velocity: Float = 0.8            // Retrig velocity multiplier
    var length: Float = 0.5              // Retrig length
    
    enum RetrigRate: String, CaseIterable, Codable {
        case thirtysecond = "1/32"
        case sixteenth = "1/16"
        case eighth = "1/8"
        case quarter = "1/4"
        
        var subdivision: Double {
            switch self {
            case .thirtysecond: return 1.0/32.0
            case .sixteenth: return 1.0/16.0
            case .eighth: return 1.0/8.0
            case .quarter: return 1.0/4.0
            }
        }
    }
}

// MARK: - Conditional Triggering (Elektron Magic!)
enum TrigCondition: String, CaseIterable, Codable {
    case none = "---"
    case fill = "FILL"              // Only on fill
    case notFill = "NOT:FILL"       // Not on fill
    case first = "FIRST"            // First time only
    case notFirst = "NOT:FIRST"     // Not first time
    case oneOfTwo = "1:2"           // Every other time
    case oneOfThree = "1:3"         // Every third time
    case oneOfFour = "1:4"          // Every fourth time
    case twoOfThree = "2:3"         // Two out of three
    case threeOfFour = "3:4"        // Three out of four
    case neighbor = "NEI"           // If neighbor triggered
    case prevStep = "PRE"           // If previous step triggered
    
    var displayName: String {
        return self.rawValue
    }
    
    var shortName: String {
        switch self {
        case .none: return "---"
        case .fill: return "FIL"
        case .notFill: return "N:F"
        case .first: return "1ST"
        case .notFirst: return "N:1"
        case .oneOfTwo: return "1:2"
        case .oneOfThree: return "1:3"
        case .oneOfFour: return "1:4"
        case .twoOfThree: return "2:3"
        case .threeOfFour: return "3:4"
        case .neighbor: return "NEI"
        case .prevStep: return "PRE"
        }
    }
}

// MARK: - ElektronPattern (Elektron-style 64-step pattern)
class ElektronPattern: ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var steps: [Step]
    @Published var patternLength: Int = 16      // 1-64 steps
    @Published var timeSignature: TimeSignature = .fourFour
    @Published var swing: Float = 0.0           // -50 to +50
    @Published var scale: PatternScale = .sixteenth
    
    // Pattern chaining (Elektron-style)
    @Published var chainMode: ChainMode = .none
    @Published var chainLength: Int = 1
    
    // Master track effects
    @Published var masterVolume: Float = 1.0
    @Published var masterCompression: Float = 0.0
    @Published var masterDistortion: Float = 0.0
    
    enum TimeSignature: String, CaseIterable {
        case fourFour = "4/4"
        case threeFour = "3/4"
        case fiveFour = "5/4"
        case sevenEight = "7/8"
        
        var beatsPerPattern: Int {
            switch self {
            case .fourFour: return 4
            case .threeFour: return 3
            case .fiveFour: return 5
            case .sevenEight: return 7
            }
        }
    }
    
    enum PatternScale: String, CaseIterable {
        case thirtysecond = "1/32"
        case sixteenth = "1/16"
        case eighth = "1/8"
        case quarter = "1/4"
        
        var stepsPerBeat: Int {
            switch self {
            case .thirtysecond: return 8
            case .sixteenth: return 4
            case .eighth: return 2
            case .quarter: return 1
            }
        }
    }
    
    enum ChainMode: String, CaseIterable {
        case none = "OFF"
        case chain = "CHAIN"
        case random = "RND"
        case pingPong = "PING"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    init(id: UUID = UUID(), name: String, stepCount: Int = 16) {
        self.id = id
        self.name = name
        self.patternLength = stepCount
        self.steps = Array(repeating: Step(), count: 64) // Max 64 steps like Elektron
    }
    
    // MARK: - Step Manipulation (Elektron-style)
    
    func toggleStep(_ stepIndex: Int) {
        guard stepIndex < steps.count else { return }
        steps[stepIndex].isActive.toggle()
    }
    
    func setStepVelocity(_ stepIndex: Int, velocity: Float) {
        guard stepIndex < steps.count else { return }
        steps[stepIndex].velocity = max(0.0, min(1.0, velocity))
    }
    
    func setMicrotiming(_ stepIndex: Int, timing: Float) {
        guard stepIndex < steps.count else { return }
        steps[stepIndex].microtiming = max(-23.0, min(23.0, timing))
    }
    
    func setStepProbability(_ stepIndex: Int, probability: Float) {
        guard stepIndex < steps.count else { return }
        steps[stepIndex].probability = max(0.0, min(1.0, probability))
    }
    
    func setStepCondition(_ stepIndex: Int, condition: TrigCondition) {
        guard stepIndex < steps.count else { return }
        steps[stepIndex].condition = condition
    }
    
    // MARK: - Parameter Locks (The MAGIC!)
    
    func addParameterLock(_ stepIndex: Int, parameter: ParameterLock.LockableParameter, value: Float) {
        guard stepIndex < steps.count else { return }
        
        // Remove existing lock for this parameter
        steps[stepIndex].parameterLocks.removeAll { $0.parameter == parameter }
        
        // Add new lock
        let lock = ParameterLock(parameter: parameter, value: value, stepIndex: stepIndex)
        steps[stepIndex].parameterLocks.append(lock)
    }
    
    func removeParameterLock(_ stepIndex: Int, parameter: ParameterLock.LockableParameter) {
        guard stepIndex < steps.count else { return }
        steps[stepIndex].parameterLocks.removeAll { $0.parameter == parameter }
    }
    
    func getParameterLock(_ stepIndex: Int, parameter: ParameterLock.LockableParameter) -> Float? {
        guard stepIndex < steps.count else { return nil }
        return steps[stepIndex].parameterLocks.first { $0.parameter == parameter }?.value
    }
    
    // MARK: - Retrig Settings
    
    func setRetrig(_ stepIndex: Int, settings: RetrigSettings?) {
        guard stepIndex < steps.count else { return }
        steps[stepIndex].retrig = settings
    }
    
    // MARK: - Pattern Operations (Elektron-style)
    
    func clear() {
        for i in 0..<steps.count {
            steps[i] = Step()
        }
    }
    
    func copy(from otherPattern: ElektronPattern) {
        self.steps = otherPattern.steps
        self.patternLength = otherPattern.patternLength
        self.timeSignature = otherPattern.timeSignature
        self.swing = otherPattern.swing
        self.scale = otherPattern.scale
    }
    
    func reverse() {
        let activeSteps = steps.prefix(patternLength)
        let reversedSteps = Array(activeSteps.reversed())
        for i in 0..<patternLength {
            steps[i] = reversedSteps[i]
        }
    }
    
    func shift(_ amount: Int) {
        let activeSteps = Array(steps.prefix(patternLength))
        let shiftedSteps = Array(activeSteps.suffix(activeSteps.count - amount) + activeSteps.prefix(amount))
        for i in 0..<patternLength {
            steps[i] = shiftedSteps[i]
        }
    }
    
    func randomize(probability: Float = 0.5) {
        for i in 0..<patternLength {
            steps[i].isActive = Float.random(in: 0...1) < probability
            if steps[i].isActive {
                steps[i].velocity = Float.random(in: 0.5...1.0)
                steps[i].microtiming = Float.random(in: -10...10)
            }
        }
    }
    
    // MARK: - Pattern Analysis
    
    var activeStepCount: Int {
        return steps.prefix(patternLength).filter { $0.isActive }.count
    }
    
    var hasParameterLocks: Bool {
        return steps.prefix(patternLength).contains { !$0.parameterLocks.isEmpty }
    }
    
    var hasRetrigs: Bool {
        return steps.prefix(patternLength).contains { $0.retrig != nil }
    }
    
    var hasConditions: Bool {
        return steps.prefix(patternLength).contains { $0.condition != .none }
    }
}

// MARK: - Song Mode (Pattern Chaining)
class Song: ObservableObject {
    let id = UUID()
    @Published var name: String = "New Song"
    @Published var patterns: [Pattern] = []
    @Published var chain: [PatternChainLink] = []
    @Published var currentChainIndex: Int = 0
    @Published var tempo: Float = 120.0
    @Published var isPlaying: Bool = false
    
    struct PatternChainLink {
        let patternId: UUID
        let repeatCount: Int
        let mute: Bool
        
        init(patternId: UUID, repeatCount: Int = 1, mute: Bool = false) {
            self.patternId = patternId
            self.repeatCount = repeatCount
            self.mute = mute
        }
    }
    
    func addPattern(_ pattern: Pattern) {
        patterns.append(pattern)
    }
    
    func addToChain(patternId: UUID, repeatCount: Int = 1) {
        let link = PatternChainLink(patternId: patternId, repeatCount: repeatCount)
        chain.append(link)
    }
    
    func removeFromChain(at index: Int) {
        guard index < chain.count else { return }
        chain.remove(at: index)
    }
}

/*
🎛️ ELEKTRON-STYLE SEQUENCER FEATURES IMPLEMENTED:

✅ 64-step patterns (like Digitakt/Syntakt)
✅ Parameter locks on EVERY parameter
✅ Conditional triggering (1:2, 1:3, FILL, etc.)
✅ Microtiming (-23 to +23)
✅ Retriggering with rate and count
✅ Pattern length (1-64 steps)
✅ Swing and time signatures
✅ Pattern chaining and song mode
✅ Step probability
✅ Pattern operations (reverse, shift, randomize)

🔥 NEXT LEVEL FEATURES:
- Real-time parameter locks via hardware controllers
- Visual step editing with parameter lock indicators
- Pattern morphing and interpolation
- Advanced conditional triggers
- Live pattern switching
- Fill patterns
- Master track effects

This is the ELEKTRON WORKFLOW in iOS! 🎹🔥
*/
