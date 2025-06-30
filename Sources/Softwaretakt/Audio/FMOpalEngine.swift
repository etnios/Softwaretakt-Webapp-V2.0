import Foundation
import Accelerate

// 🎛️ FM-OPAL SYNTHESIS ENGINE - The Heart of Digital Chaos!

class FMOpalEngine {
    
    // MARK: - Core Properties
    
    private let sampleRate: Double = 44100.0
    private var phase: [Double] = [0.0, 0.0, 0.0, 0.0] // 4 operators
    private var envelopePhase: [Double] = [0.0, 0.0, 0.0, 0.0]
    private var isNoteOn: Bool = false
    private var currentNote: UInt8 = 60
    private var velocity: Float = 1.0
    
    // FM Parameters (real-time controllable)
    var algorithm: Int = 0 {
        didSet { updateAlgorithm() }
    }
    
    var operatorRatios: [Float] = [1.0, 1.0, 1.0, 1.0] {
        didSet { updateFrequencies() }
    }
    
    var operatorLevels: [Float] = [1.0, 1.0, 1.0, 1.0]
    var feedback: Float = 0.0
    var fmDepth: Float = 1.0
    
    // Envelope parameters (ADSR for each operator)
    var envelopes: [ADSREnvelope] = [
        ADSREnvelope(), ADSREnvelope(), ADSREnvelope(), ADSREnvelope()
    ]
    
    // Current algorithm configuration
    private var algorithmMatrix: [[Float]] = Array(repeating: Array(repeating: 0.0, count: 4), count: 4)
    private var carrierMask: [Bool] = [false, false, false, true] // Op4 is carrier by default
    
    // Fundamental frequency and operator frequencies
    private var fundamentalFreq: Double = 261.626 // Middle C
    private var operatorFreqs: [Double] = [261.626, 261.626, 261.626, 261.626]
    
    // Feedback delay line
    private var feedbackDelay: Double = 0.0
    
    init() {
        setupDefaultEnvelopes()
        updateAlgorithm()
        updateFrequencies()
    }
    
    // MARK: - Note Control
    
    func noteOn(note: UInt8, velocity: Float) {
        self.currentNote = note
        self.velocity = velocity
        self.isNoteOn = true
        
        // Calculate fundamental frequency from MIDI note
        fundamentalFreq = 440.0 * pow(2.0, (Double(note) - 69.0) / 12.0)
        updateFrequencies()
        
        // Trigger all envelopes
        for i in 0..<4 {
            envelopes[i].noteOn()
            envelopePhase[i] = 0.0
        }
    }
    
    func noteOff() {
        isNoteOn = false
        
        // Release all envelopes
        for i in 0..<4 {
            envelopes[i].noteOff()
        }
    }
    
    // MARK: - Audio Rendering (The Magic!)
    
    func renderAudio(frameCount: Int) -> [Float] {
        var output = Array<Float>(repeating: 0.0, count: frameCount)
        
        let phaseIncrement = Array(0..<4).map { i in
            2.0 * Double.pi * operatorFreqs[i] / sampleRate
        }
        
        for frame in 0..<frameCount {
            // Generate each operator
            var operatorOutputs: [Double] = [0.0, 0.0, 0.0, 0.0]
            
            // Calculate FM modulation for this sample
            var modulationInputs: [Double] = [0.0, 0.0, 0.0, 0.0]
            
            // Apply algorithm matrix (modulation routing)
            for modulator in 0..<4 {
                for target in 0..<4 {
                    if algorithmMatrix[modulator][target] > 0.0 {
                        modulationInputs[target] += operatorOutputs[modulator] * Double(algorithmMatrix[modulator][target]) * Double(fmDepth)
                    }
                }
            }
            
            // Apply feedback to operator 0
            modulationInputs[0] += feedbackDelay * Double(feedback)
            
            // Generate operator outputs
            for op in 0..<4 {
                // Get envelope value
                let envelopeValue = envelopes[op].getNextSample()
                
                // Calculate phase with modulation
                let modulatedPhase = phase[op] + modulationInputs[op]
                
                // Generate sine wave with modulation
                operatorOutputs[op] = sin(modulatedPhase) * Double(operatorLevels[op]) * Double(envelopeValue) * Double(velocity)
                
                // Advance phase
                phase[op] += phaseIncrement[op]
                if phase[op] > 2.0 * Double.pi {
                    phase[op] -= 2.0 * Double.pi
                }
            }
            
            // Update feedback delay
            feedbackDelay = operatorOutputs[0]
            
            // Mix carriers to output
            var sample: Double = 0.0
            for op in 0..<4 {
                if carrierMask[op] {
                    sample += operatorOutputs[op]
                }
            }
            
            // Apply final gain and clipping
            output[frame] = Float(max(-1.0, min(1.0, sample * 0.25))) // Scale down to prevent clipping
        }
        
        return output
    }
    
    // MARK: - Algorithm Configuration (32 Algorithms!)
    
    private func updateAlgorithm() {
        // Reset algorithm matrix
        algorithmMatrix = Array(repeating: Array(repeating: 0.0, count: 4), count: 4)
        carrierMask = [false, false, false, false]
        
        switch algorithm {
        case 0: // Algorithm 1: All modulators to carrier (classic FM)
            algorithmMatrix[0][3] = 1.0  // Op1 -> Op4
            algorithmMatrix[1][3] = 1.0  // Op2 -> Op4
            algorithmMatrix[2][3] = 1.0  // Op3 -> Op4
            carrierMask[3] = true
            
        case 1: // Algorithm 2: Op1->Op2->Op3->Op4 (chain)
            algorithmMatrix[0][1] = 1.0  // Op1 -> Op2
            algorithmMatrix[1][2] = 1.0  // Op2 -> Op3
            algorithmMatrix[2][3] = 1.0  // Op3 -> Op4
            carrierMask[3] = true
            
        case 2: // Algorithm 3: Parallel carriers
            carrierMask = [true, true, true, true]
            
        case 3: // Algorithm 4: Op1->Op2, Op3->Op4 (dual chains)
            algorithmMatrix[0][1] = 1.0  // Op1 -> Op2
            algorithmMatrix[2][3] = 1.0  // Op3 -> Op4
            carrierMask[1] = true
            carrierMask[3] = true
            
        case 4: // Algorithm 5: Complex modulation
            algorithmMatrix[0][2] = 1.0  // Op1 -> Op3
            algorithmMatrix[1][2] = 1.0  // Op2 -> Op3
            algorithmMatrix[2][3] = 1.0  // Op3 -> Op4
            carrierMask[3] = true
            
        case 5: // Algorithm 6: Bell-like
            algorithmMatrix[0][1] = 1.0  // Op1 -> Op2
            algorithmMatrix[2][1] = 1.0  // Op3 -> Op2
            algorithmMatrix[1][3] = 1.0  // Op2 -> Op4
            carrierMask[3] = true
            
        case 6: // Algorithm 7: Brass-like
            algorithmMatrix[0][1] = 1.0  // Op1 -> Op2
            algorithmMatrix[0][2] = 1.0  // Op1 -> Op3
            algorithmMatrix[1][3] = 1.0  // Op2 -> Op4
            algorithmMatrix[2][3] = 1.0  // Op3 -> Op4
            carrierMask[3] = true
            
        case 7: // Algorithm 8: Organ-like
            algorithmMatrix[0][1] = 1.0  // Op1 -> Op2
            carrierMask[1] = true
            carrierMask[2] = true
            carrierMask[3] = true
            
        // Add more algorithms...
        case 8: // Algorithm 9: Metallic
            algorithmMatrix[0][2] = 1.0
            algorithmMatrix[1][3] = 1.0
            algorithmMatrix[2][3] = 0.5
            carrierMask[2] = true
            carrierMask[3] = true
            
        case 9: // Algorithm 10: Chaos
            algorithmMatrix[0][1] = 0.8
            algorithmMatrix[1][0] = 0.3  // Cross-modulation!
            algorithmMatrix[2][3] = 1.0
            carrierMask[1] = true
            carrierMask[3] = true
            
        case 10: // Algorithm 11: Double modulation
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[0][2] = 1.0
            algorithmMatrix[1][3] = 1.0
            algorithmMatrix[2][3] = 1.0
            carrierMask[3] = true
            
        case 11: // Algorithm 12: Triple carrier
            algorithmMatrix[0][1] = 1.0
            carrierMask[1] = true
            carrierMask[2] = true
            carrierMask[3] = true
            
        case 12: // Algorithm 13: Stack modulation
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[1][2] = 1.0
            algorithmMatrix[0][3] = 1.0
            carrierMask[2] = true
            carrierMask[3] = true
            
        case 13: // Algorithm 14: Complex web
            algorithmMatrix[0][2] = 1.0
            algorithmMatrix[1][2] = 1.0
            algorithmMatrix[0][3] = 1.0
            algorithmMatrix[2][3] = 1.0
            carrierMask[3] = true
            
        case 14: // Algorithm 15: Feedback chaos
            algorithmMatrix[1][0] = 0.5  // Cross feedback
            algorithmMatrix[0][2] = 1.0
            algorithmMatrix[1][3] = 1.0
            carrierMask[2] = true
            carrierMask[3] = true
            
        case 15: // Algorithm 16: Bell tower
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[2][1] = 1.0
            algorithmMatrix[3][1] = 1.0
            carrierMask[1] = true
            
        case 16: // Algorithm 17: Dual feedback
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[1][0] = 0.3  // Feedback loop
            algorithmMatrix[2][3] = 1.0
            carrierMask[1] = true
            carrierMask[3] = true
            
        case 17: // Algorithm 18: Metallic resonance
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[2][1] = 1.0
            algorithmMatrix[1][3] = 1.0
            algorithmMatrix[2][3] = 0.5
            carrierMask[3] = true
            
        case 18: // Algorithm 19: Organ pipes
            algorithmMatrix[0][1] = 1.0
            carrierMask[1] = true
            carrierMask[2] = true
            carrierMask[3] = true
            
        case 19: // Algorithm 20: Digital scream
            algorithmMatrix[0][1] = 2.0  // Heavy modulation
            algorithmMatrix[1][2] = 1.5
            algorithmMatrix[2][3] = 1.0
            carrierMask[3] = true
            
        case 20: // Algorithm 21: Harmonic cascade
            algorithmMatrix[0][3] = 1.0
            algorithmMatrix[1][3] = 0.8
            algorithmMatrix[2][3] = 0.6
            carrierMask[3] = true
            
        case 21: // Algorithm 22: Cross chaos
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[1][0] = 0.7  // Cross modulation
            algorithmMatrix[2][3] = 1.0
            algorithmMatrix[3][2] = 0.4  // More cross mod
            carrierMask[1] = true
            carrierMask[3] = true
            
        case 22: // Algorithm 23: Frequency shifter
            algorithmMatrix[0][2] = 1.0
            algorithmMatrix[1][3] = 1.0
            algorithmMatrix[2][3] = 0.3
            carrierMask[2] = true
            carrierMask[3] = true
            
        case 23: // Algorithm 24: Ring modulation
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[2][3] = 1.0
            algorithmMatrix[1][3] = 0.5  // Ring mod effect
            carrierMask[3] = true
            
        case 24: // Algorithm 25: Spectral morph
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[0][2] = 0.7
            algorithmMatrix[0][3] = 0.5
            carrierMask[1] = true
            carrierMask[2] = true
            carrierMask[3] = true
            
        case 25: // Algorithm 26: Noise gate
            algorithmMatrix[0][1] = 1.5
            algorithmMatrix[2][1] = 0.8
            algorithmMatrix[1][3] = 1.0
            carrierMask[3] = true
            
        case 26: // Algorithm 27: Phase distortion
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[1][2] = 1.0
            algorithmMatrix[3][2] = 0.6
            carrierMask[2] = true
            carrierMask[3] = true
            
        case 27: // Algorithm 28: Frequency folding
            algorithmMatrix[0][1] = 2.5  // Extreme modulation
            algorithmMatrix[1][2] = 1.0
            algorithmMatrix[2][3] = 1.0
            carrierMask[3] = true
            
        case 28: // Algorithm 29: Digital shimmer
            algorithmMatrix[0][3] = 1.0
            algorithmMatrix[1][2] = 1.0
            algorithmMatrix[2][3] = 0.4
            carrierMask[2] = true
            carrierMask[3] = true
            
        case 29: // Algorithm 30: Chaos matrix
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[1][2] = 1.0
            algorithmMatrix[2][0] = 0.5  // Feedback loop
            algorithmMatrix[0][3] = 1.0
            carrierMask[3] = true
            
        case 30: // Algorithm 31: Ultimate chaos
            algorithmMatrix[0][1] = 1.0
            algorithmMatrix[1][0] = 0.6  // Cross modulation
            algorithmMatrix[2][3] = 1.0
            algorithmMatrix[3][2] = 0.4  // More cross mod
            algorithmMatrix[0][3] = 0.5  // Additional routing
            carrierMask[1] = true
            carrierMask[3] = true
            
        case 31: // Algorithm 32: PURE MADNESS
            algorithmMatrix[0][1] = 1.5
            algorithmMatrix[1][0] = 0.8  // Heavy cross mod
            algorithmMatrix[2][3] = 1.5
            algorithmMatrix[3][2] = 0.7  // Heavy cross mod
            algorithmMatrix[0][2] = 0.6  // Extra connections
            algorithmMatrix[1][3] = 0.4
            carrierMask[1] = true
            carrierMask[2] = true
            carrierMask[3] = true
            
        default: // Default to algorithm 1
            algorithmMatrix[0][3] = 1.0
            algorithmMatrix[1][3] = 1.0
            algorithmMatrix[2][3] = 1.0
            carrierMask[3] = true
        }
    }
    
    private func updateFrequencies() {
        for i in 0..<4 {
            operatorFreqs[i] = fundamentalFreq * Double(operatorRatios[i])
        }
    }
    
    private func setupDefaultEnvelopes() {
        for i in 0..<4 {
            envelopes[i].attack = 0.01   // 10ms attack
            envelopes[i].decay = 0.1     // 100ms decay
            envelopes[i].sustain = 0.7   // 70% sustain
            envelopes[i].release = 0.5   // 500ms release
        }
    }
    
    // MARK: - Parameter Lock Support
    
    func setParameterLock(parameter: String, value: Float) {
        switch parameter {
        case "FM_ALG":
            algorithm = Int(value * 31) // 0-31 algorithms
        case "OP1_RATIO":
            operatorRatios[0] = value * 8.0 // 0-8x ratio
        case "OP2_RATIO":
            operatorRatios[1] = value * 8.0
        case "OP3_RATIO":
            operatorRatios[2] = value * 8.0
        case "OP4_RATIO":
            operatorRatios[3] = value * 8.0
        case "OP1_LVL":
            operatorLevels[0] = value
        case "OP2_LVL":
            operatorLevels[1] = value
        case "OP3_LVL":
            operatorLevels[2] = value
        case "OP4_LVL":
            operatorLevels[3] = value
        case "FM_DEPTH":
            fmDepth = value * 10.0 // 0-10x modulation depth
        case "FM_FB":
            feedback = value
        default:
            break
        }
    }
    
    // MARK: - Real-time Control
    
    func setOperatorRatio(operatorIndex: Int, ratio: Float) {
        guard operatorIndex >= 0 && operatorIndex < 4 else { return }
        operatorRatios[operatorIndex] = ratio
        updateFrequencies()
    }
    
    func setOperatorLevel(operatorIndex: Int, level: Float) {
        guard operatorIndex >= 0 && operatorIndex < 4 else { return }
        operatorLevels[operatorIndex] = level
    }
    
    func setOperatorEnvelope(operatorIndex: Int, attack: Float, decay: Float, sustain: Float, release: Float) {
        guard operatorIndex >= 0 && operatorIndex < 4 else { return }
        envelopes[operatorIndex].attack = attack
        envelopes[operatorIndex].decay = decay
        envelopes[operatorIndex].sustain = sustain
        envelopes[operatorIndex].release = release
    }
    
    // MARK: - Enhanced Operator Features
    
    // Operator waveforms (beyond just sine waves!)
    enum OperatorWaveform: Int, CaseIterable {
        case sine = 0
        case saw = 1
        case square = 2
        case triangle = 3
        case noise = 4
        
        func generateSample(phase: Double) -> Double {
            switch self {
            case .sine:
                return sin(phase)
            case .saw:
                return (2.0 * (phase / (2.0 * Double.pi))) - 1.0
            case .square:
                return sin(phase) > 0 ? 1.0 : -1.0
            case .triangle:
                let normalized = phase / (2.0 * Double.pi)
                return abs(4.0 * normalized - 2.0) - 1.0
            case .noise:
                return Double.random(in: -1.0...1.0)
            }
        }
    }
    
    var operatorWaveforms: [OperatorWaveform] = [.sine, .sine, .sine, .sine]
    
    // LFO per operator for wild modulation
    private var lfoPhase: [Double] = [0.0, 0.0, 0.0, 0.0]
    var lfoRates: [Float] = [1.0, 1.0, 1.0, 1.0]  // Hz
    var lfoAmounts: [Float] = [0.0, 0.0, 0.0, 0.0] // 0-1
    
    // Velocity sensitivity per operator
    var velocitySensitivity: [Float] = [1.0, 1.0, 1.0, 1.0]
    
    // Enhanced rendering with all features
    func renderAudioEnhanced(frameCount: Int) -> [Float] {
        var output = Array<Float>(repeating: 0.0, count: frameCount)
        
        let phaseIncrement = Array(0..<4).map { i in
            2.0 * Double.pi * operatorFreqs[i] / sampleRate
        }
        
        let lfoIncrement = Array(0..<4).map { i in
            2.0 * Double.pi * Double(lfoRates[i]) / sampleRate
        }
        
        for frame in 0..<frameCount {
            var operatorOutputs: [Double] = [0.0, 0.0, 0.0, 0.0]
            var modulationInputs: [Double] = [0.0, 0.0, 0.0, 0.0]
            
            // Apply algorithm matrix (modulation routing)
            for modulator in 0..<4 {
                for target in 0..<4 {
                    if algorithmMatrix[modulator][target] > 0.0 {
                        modulationInputs[target] += operatorOutputs[modulator] * 
                                                  Double(algorithmMatrix[modulator][target]) * 
                                                  Double(fmDepth)
                    }
                }
            }
            
            // Apply feedback to operator 0
            modulationInputs[0] += feedbackDelay * Double(feedback)
            
            // Generate operator outputs with enhanced features
            for op in 0..<4 {
                // LFO modulation
                let lfoValue = sin(lfoPhase[op]) * Double(lfoAmounts[op])
                lfoPhase[op] += lfoIncrement[op]
                if lfoPhase[op] > 2.0 * Double.pi {
                    lfoPhase[op] -= 2.0 * Double.pi
                }
                
                // Get envelope value
                let envelopeValue = envelopes[op].getNextSample()
                
                // Velocity sensitivity
                let velocityAmount = Double(velocity) * Double(velocitySensitivity[op])
                
                // Calculate phase with modulation and LFO
                let modulatedPhase = phase[op] + modulationInputs[op] + (lfoValue * Double.pi)
                
                // Generate waveform (not just sine!)
                let waveformSample = operatorWaveforms[op].generateSample(phase: modulatedPhase)
                
                // Apply all modulations
                operatorOutputs[op] = waveformSample * 
                                    Double(operatorLevels[op]) * 
                                    Double(envelopeValue) * 
                                    velocityAmount
                
                // Advance phase
                phase[op] += phaseIncrement[op]
                if phase[op] > 2.0 * Double.pi {
                    phase[op] -= 2.0 * Double.pi
                }
            }
            
            // Update feedback delay
            feedbackDelay = operatorOutputs[0]
            
            // Mix carriers to output with stereo spread
            var sample: Double = 0.0
            for op in 0..<4 {
                if carrierMask[op] {
                    sample += operatorOutputs[op]
                }
            }
            
            // Soft clipping for musical distortion
            sample = tanh(sample * 0.7) * 0.8
            
            output[frame] = Float(max(-1.0, min(1.0, sample)))
        }
        
        return output
    }
    
    // MARK: - Preset System Integration
    
    func loadPreset(_ preset: FMPreset) {
        algorithm = preset.algorithm
        operatorRatios = preset.operatorRatios
        operatorLevels = preset.operatorLevels
        feedback = preset.feedback
        fmDepth = preset.fmDepth
        operatorWaveforms = preset.operatorWaveforms
        lfoRates = preset.lfoRates
        lfoAmounts = preset.lfoAmounts
        
        for i in 0..<4 {
            envelopes[i].attack = preset.envelopes[i].attack
            envelopes[i].decay = preset.envelopes[i].decay
            envelopes[i].sustain = preset.envelopes[i].sustain
            envelopes[i].release = preset.envelopes[i].release
        }
        
        updateAlgorithm()
        updateFrequencies()
    }
    
    // MARK: - Real-time Morphing
    
    func morphToAlgorithm(_ targetAlgorithm: Int, morphAmount: Float) {
        // Store current algorithm
        let currentAlg = algorithm
        
        // Temporarily set target algorithm
        algorithm = targetAlgorithm
        let targetMatrix = algorithmMatrix
        let _ = carrierMask
        
        // Restore current algorithm
        algorithm = currentAlg
        updateAlgorithm()
        
        // Interpolate between current and target
        for modulator in 0..<4 {
            for target in 0..<4 {
                let current = algorithmMatrix[modulator][target]
                let targetVal = targetMatrix[modulator][target]
                algorithmMatrix[modulator][target] = current + (targetVal - current) * morphAmount
            }
        }
        
        // Note: Carrier mask morphing would need more complex logic
    }
}

// MARK: - ADSR Envelope

class ADSREnvelope {
    var attack: Float = 0.01
    var decay: Float = 0.1
    var sustain: Float = 0.7
    var release: Float = 0.5
    
    private var state: EnvelopeState = .idle
    private var level: Float = 0.0
    private var sampleRate: Float = 44100.0
    
    enum EnvelopeState {
        case idle, attack, decay, sustain, release
    }
    
    func noteOn() {
        state = .attack
    }
    
    func noteOff() {
        state = .release
    }
    
    func getNextSample() -> Float {
        let attackTime = max(0.001, attack)
        let decayTime = max(0.001, decay)
        let releaseTime = max(0.001, release)
        
        switch state {
        case .idle:
            level = 0.0
            
        case .attack:
            level += 1.0 / (attackTime * sampleRate)
            if level >= 1.0 {
                level = 1.0
                state = .decay
            }
            
        case .decay:
            level -= (1.0 - sustain) / (decayTime * sampleRate)
            if level <= sustain {
                level = sustain
                state = .sustain
            }
            
        case .sustain:
            level = sustain
            
        case .release:
            level -= sustain / (releaseTime * sampleRate)
            if level <= 0.0 {
                level = 0.0
                state = .idle
            }
        }
        
        return max(0.0, min(1.0, level))
    }
}

/*
🎛️ FM-OPAL ENGINE FEATURES:

✅ 4-operator FM synthesis
✅ 32 different algorithms (10 implemented, 22 more to add)
✅ Real-time parameter control
✅ Individual ADSR envelopes per operator
✅ Feedback modulation
✅ Parameter lock support
✅ MIDI note control
✅ Cross-modulation capabilities
✅ Low-latency audio rendering

🔥 NEXT LEVEL FEATURES TO ADD:
- Operator waveform selection (sine, saw, square, noise)
- LFO modulation per operator
- Filter per operator
- Velocity sensitivity per operator
- Real-time algorithm morphing
- Preset system integration
- Multi-timbral support

This is the ENGINE that will make those Focals SCREAM! 🎧⚡️
*/
