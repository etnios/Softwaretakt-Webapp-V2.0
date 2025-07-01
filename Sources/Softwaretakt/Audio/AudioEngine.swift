import Foundation
import AVFoundation
import AudioKit
import AudioKitEX

// MARK: - Math Constants
let π = Float.pi

// 🎛️ SOFTWARETAKT AUDIO ENGINE - NOW WITH FM-OPAL POWER!

// MARK: - Enums and Supporting Types

enum AudioFilterType: String, CaseIterable {
    case lowpass = "LP"
    case highpass = "HP"
    case bandpass = "BP"
    case notch = "NOTCH"
}

enum LFODestination: String, CaseIterable {
    case pitch = "PITCH"
    case filter = "FILTER"
    case amplitude = "AMP"
    case wave = "WAVE"
}

// MARK: - Track Configuration
struct TrackConfig {
    var engineType: SynthEngineType = .sample
    var synthParams: SynthParameters = SynthParameters()
    var sample: Sample? = nil
    var volume: Float = 0.8
    var pan: Float = 0.0
    var isMuted: Bool = false
    var isSoloed: Bool = false
}

// MARK: - Synthesis Voice
class SynthVoice {
    let engineType: SynthEngineType
    var parameters: SynthParameters
    var isPlaying: Bool = false
    var noteNumber: UInt8 = 60
    var velocity: Float = 1.0
    
    // Audio nodes
    private var oscillator1: AVAudioUnitGenerator?
    private var oscillator2: AVAudioUnitGenerator?
    private var filter: AVAudioUnitEQ?
    private var envelope: AVAudioUnitVarispeed? // Placeholder for envelope
    
    init(engineType: SynthEngineType) {
        self.engineType = engineType
        self.parameters = SynthParameters()
        setupSynthEngine()
    }
    
    private func setupSynthEngine() {
        switch engineType {
        case .sample:
            // Sample playback - no synthesis needed
            break
        case .dvco:
            setupDVCOEngine()
        case .dsaw:
            setupDSAWEngine()
        case .dtone:
            setupDTONEEngine()
        case .dualvco:
            setupDualVCOEngine()
        case .analog:
            setupAnalogEngine()
        case .syRaw:
            setupSYRAWEngine()
        case .syChip:
            setupSYCHIPEngine()
        case .syDual:
            setupSYDUALEngine()
        case .noise:
            setupNoiseEngine()
        case .fmOpal:
            setupFMOpalEngine()
        }
    }
    
    // MARK: - Synthesis Engine Implementations
    
    private func setupDVCOEngine() {
        // Digital VCO - Classic waveforms (sin, saw, square, triangle)
        print("🎛️ Setting up DVCO engine")
        // Implementation: Use AVAudioUnitGenerator with custom waveform generation
    }
    
    private func setupDSAWEngine() {
        // Digital Sawtooth with sync capabilities
        print("🎛️ Setting up DSAW engine")
        // Implementation: Sawtooth oscillator with hard sync
    }
    
    private func setupDTONEEngine() {
        // Digital tone synthesis - FM-like synthesis
        print("🎛️ Setting up DTONE engine")
        // Implementation: Basic FM synthesis with operator
    }
    
    private func setupDualVCOEngine() {
        // Dual oscillator engine
        print("🎛️ Setting up DUALVCO engine")
        // Implementation: Two oscillators with mix, detune, sync
    }
    
    private func setupAnalogEngine() {
        // Analog modeling synthesis
        print("🎛️ Setting up ANALOG engine")
        // Implementation: Virtual analog oscillator with filter modeling
    }
    
    private func setupSYRAWEngine() {
        // Raw analog-style synthesis
        print("🎛️ Setting up SY-RAW engine")
        // Implementation: Raw, gritty analog-style oscillator
    }
    
    private func setupSYCHIPEngine() {
        // Chiptune/8-bit synthesis
        print("🎛️ Setting up SY-CHIP engine")
        // Implementation: 8-bit style square waves, noise, etc.
    }
    
    private func setupSYDUALEngine() {
        // Dual synthesis engine
        print("🎛️ Setting up SY-DUAL engine")
        // Implementation: Two independent synthesis engines
    }
    
    private func setupNoiseEngine() {
        // Advanced noise synthesis
        print("🎛️ Setting up NOISE engine")
        // Implementation: Various noise types with filtering
    }
    
    private func setupFMOpalEngine() {
        // 4-operator FM synthesis (Opal-inspired)
        print("🎛️ Setting up FM-OPAL engine")
        // Implementation: 4-operator FM synthesis with 32 algorithms
        // - Operator frequency ratios (0.5x to 16.0x)
        // - Operator output levels (0.0 to 1.0)
        // - FM algorithms (like Digitone/Opal)
        // - Operator feedback
        // - Modulation matrix
    }
    
    func trigger(note: UInt8, velocity: Float) {
        self.noteNumber = note
        self.velocity = velocity
        self.isPlaying = true
        
        // Calculate frequency from MIDI note
        let frequency = 440.0 * pow(2.0, (Double(note) - 69.0) / 12.0)
        
        print("🎹 Triggering \(engineType.displayName) note \(note) at \(frequency)Hz")
        
        // Start synthesis based on engine type
        startSynthesis(frequency: Float(frequency))
    }
    
    func release() {
        self.isPlaying = false
        print("🎹 Releasing \(engineType.displayName) note \(noteNumber)")
        // Start release phase of envelope
    }
    
    private func startSynthesis(frequency: Float) {
        // Engine-specific synthesis triggering
        switch engineType {
        case .sample:
            break // Handled by sample engine
        default:
            // Generic synthesis start
            print("🎵 Starting synthesis at \(frequency)Hz")
        }
    }
}

// MARK: - Main Audio Engine
@MainActor
class AudioEngine: ObservableObject {
    // MARK: - Core Audio Components
    private var audioEngine = AVAudioEngine()
    private var mainMixer = AVAudioMixerNode()
    
    // MARK: - Sample Management
    private lazy var sampleManager = SimpleSampleManager()
    
    // MARK: - Track Management (16 stereo tracks)
    private var trackMixers: [AVAudioMixerNode] = []
    private var trackPlayers: [AVAudioPlayerNode] = []
    private var fmEngines: [FMOpalEngine] = []  // 🔥 FM synthesis engines!
    
    // Track configuration
    @Published var trackEngines: [SynthEngineType] = Array(repeating: .sample, count: 16)
    @Published var trackSynthParams: [SynthParameters] = Array(repeating: SynthParameters(), count: 16)
    @Published var isPlaying: Bool = false
    @Published var currentBPM: Double = 120.0
    
    // Track states - 16 hybrid sample/synth channels
    @Published var tracks: [Track] = []
    
    // Track configurations - 16 channels
    private var trackConfigs: [TrackConfig] = Array(repeating: TrackConfig(), count: 16)
    
    // Sample management
    private var availableSamples: [Sample] = []
    private var loadedSamples: [AVAudioPCMBuffer?] = Array(repeating: nil, count: 16)
    private var samplePlayers: [[AVAudioPlayerNode]] = []
    
    // Synthesis management - 16 tracks x 16 voices each
    private var synthVoices: [[SynthVoice]] = []
    
    // Sequencer
    private var isSequencerRunning = false
    private var sequencerTimer: Timer?
    private var currentStep = 0
    private let bpm: Float = 120.0
    
    // FM Parameters (legacy support)
    var op3Level: Float = 0.5       // Operator 3 output level
    var op4Level: Float = 0.5       // Operator 4 output level
    var fmDepth: Float = 0.5        // Global FM modulation depth
    var feedback: Float = 0.0       // Operator feedback (0.0 to 1.0)
    
    // Filter parameters
    var filterCutoff: Float = 1000.0    // 20Hz to 20kHz
    var filterResonance: Float = 1.0     // 0.1 to 30.0
    var filterType: AudioFilterType = .lowpass
    
    // Envelope parameters
    var attack: Float = 0.001       // 0.001 to 10.0 seconds
    var decay: Float = 0.3          // 0.001 to 10.0 seconds
    var sustain: Float = 0.7        // 0.0 to 1.0
    var release: Float = 0.5        // 0.001 to 10.0 seconds
    
    // LFO parameters
    var lfoRate: Float = 1.0        // 0.1 to 20.0 Hz
    var lfoAmount: Float = 0.0      // 0.0 to 1.0
    var lfoDestination: LFODestination = .pitch
    
    // Engine-specific parameters
    var param1: Float = 0.5         // Engine-specific parameter 1
    var param2: Float = 0.5         // Engine-specific parameter 2
    var param3: Float = 0.5         // Engine-specific parameter 3
    var param4: Float = 0.5         // Engine-specific parameter 4
    
    // MARK: - Project Integration
    weak var projectManager: ProjectManager?
    
    func setProjectManager(_ projectManager: ProjectManager) {
        self.projectManager = projectManager
    }
    
    // Enhanced sample loading with project tracking
    func loadSampleWithProjectTracking(_ sample: Sample, toTrack track: Int) {
        // Use the existing loadSample method
        loadSample(sample, toTrack: track)
        
        // Notify project manager about sample usage
        projectManager?.addSampleToProject(sample, toTrack: track)
    }
    
    // Smart sample loading with reference checking
    func loadSampleWithReference(_ sampleReference: SampleReference, toTrack track: Int) {
        let sampleURL = URL(fileURLWithPath: sampleReference.originalPath)
        
        if FileManager.default.fileExists(atPath: sampleReference.originalPath) {
            let sample = Sample(url: sampleURL)
            loadSample(sample, toTrack: track)
            print("✅ Loaded sample reference: \(sampleReference.sampleName)")
        } else {
            print("❌ Sample missing: \(sampleReference.sampleName) at \(sampleReference.originalPath)")
        }
    }
    
    // Get project-aware track info
    func getTrackInfo(_ track: Int) -> String {
        guard track < 16 else { return "Invalid track" }
        
        let config = trackConfigs[track]
        let engineName = config.engineType.displayName
        let sampleName = config.sample?.name ?? "No sample"
        let volume = Int(config.volume * 100)
        
        return "Track \(track + 1): \(engineName) | \(sampleName) | \(volume)%"
    }
    
    init() {
        self.mainMixer = AVAudioMixerNode()
        
        setupAudioEngine()
        setupFMEngines()  // 🔥 Initialize FM synthesis!
        loadDefaultSamples()
        initializeTracks()
        initializeSynthVoices()
    }
    
    private func setupAudioEngine() {
        // Attach main mixer to engine
        audioEngine.attach(mainMixer)
        audioEngine.connect(mainMixer, to: audioEngine.mainMixerNode, format: nil)
        
        // Create track mixers for 16 hybrid channels
        for _ in 0..<16 {
            let trackMixer = AVAudioMixerNode()
            trackMixers.append(trackMixer)
            
            // Attach track mixer to engine and connect to main mixer
            audioEngine.attach(trackMixer)
            audioEngine.connect(trackMixer, to: mainMixer, format: nil)
            
            // Create sample players for this track
            var trackPlayers: [AVAudioPlayerNode] = []
            for _ in 0..<16 {
                let player = AVAudioPlayerNode()
                audioEngine.attach(player)
                audioEngine.connect(player, to: trackMixer, format: nil)
                trackPlayers.append(player)
            }
            samplePlayers.append(trackPlayers)
        }
    }
    
    private func initializeSynthVoices() {
        // Initialize synthesis voices for each track
        for trackIndex in 0..<16 {
            var trackVoices: [SynthVoice] = []
            
            // 16 polyphonic voices per track
            for _ in 0..<16 {
                let voice = SynthVoice(engineType: trackConfigs[trackIndex].engineType)
                trackVoices.append(voice)
            }
            
            synthVoices.append(trackVoices)
        }
    }
    
    // MARK: - Engine Type Management
    
    func setEngineType(_ engineType: SynthEngineType, forTrack track: Int) {
        guard track < 16 else { return }
        
        trackConfigs[track].engineType = engineType
        
        // Reinitialize synthesis voices for this track
        synthVoices[track] = []
        for _ in 0..<16 {
            let voice = SynthVoice(engineType: engineType)
            synthVoices[track].append(voice)
        }
        
        print("🔄 Track \(track + 1) engine changed to \(engineType.displayName)")
    }
    
    func getEngineType(forTrack track: Int) -> SynthEngineType {
        guard track < 16 else { return .sample }
        return trackConfigs[track].engineType
    }
    
    // MARK: - Synthesis Parameter Control
    
    func setSynthParameter(_ parameter: WritableKeyPath<SynthParameters, Float>, value: Float, forTrack track: Int) {
        guard track < 16 else { return }
        
        // Update parameter for all voices on this track
        for voice in synthVoices[track] {
            voice.parameters[keyPath: parameter] = value
        }
        
        trackConfigs[track].synthParams[keyPath: parameter] = value
        print("🎛️ Track \(track + 1) parameter updated: \(value)")
    }
    
    func getSynthParameter(_ parameter: KeyPath<SynthParameters, Float>, forTrack track: Int) -> Float {
        guard track < 16 else { return 0.0 }
        return trackConfigs[track].synthParams[keyPath: parameter]
    }
    
    // MARK: - Overloaded methods for Int parameters
    
    func setSynthParameter(_ parameter: WritableKeyPath<SynthParameters, Int>, value: Int, forTrack track: Int) {
        guard track < 16 else { return }
        
        // Update parameter for all voices on this track
        // Note: SynthVoice uses Float parameters, so we convert if needed
        trackConfigs[track].synthParams[keyPath: parameter] = value
        print("🎛️ Track \(track + 1) parameter updated: \(value)")
    }
    
    func getSynthParameter(_ parameter: KeyPath<SynthParameters, Int>, forTrack track: Int) -> Int {
        guard track < 16 else { return 0 }
        return trackConfigs[track].synthParams[keyPath: parameter]
    }
    
    // MARK: - Triggering
    
    func triggerTrack(_ track: Int, note: UInt8 = 60, velocity: Float = 1.0, padIndex: Int = 0) {
        guard track < 16 else { return }
        
        let engineType = trackConfigs[track].engineType
        
        switch engineType {
        case .sample:
            // Use sample playback
            triggerSample(track: track, padIndex: padIndex)
        default:
            // Use synthesis
            triggerSynthesis(track: track, note: note, velocity: velocity)
        }
    }
    
    func triggerSample(track: Int, padIndex: Int) {
        guard let sample = trackConfigs[track].sample else { return }
        
        // Find available sample player
        let players = samplePlayers[track]
        let playerIndex = padIndex % players.count
        let player = players[playerIndex]
        
        do {
            let audioFile = try AVAudioFile(forReading: sample.url)
            player.scheduleFile(audioFile, at: nil)
            player.volume = trackConfigs[track].volume
            player.play()
            
            print("🔊 Playing sample '\(sample.name)' on track \(track + 1)")
        } catch {
            print("❌ Failed to play sample: \(error)")
        }
    }
    
    private func triggerSynthesis(track: Int, note: UInt8, velocity: Float) {
        // Find available synthesis voice
        let voices = synthVoices[track]
        guard let availableVoice = voices.first(where: { !$0.isPlaying }) else {
            print("⚠️ No available synthesis voice for track \(track + 1)")
            return
        }
        
        availableVoice.trigger(note: note, velocity: velocity)
        print("🎹 Triggered \(availableVoice.engineType.displayName) on track \(track + 1)")
    }
    
    // MARK: - Standard Audio Engine Methods
    
    func start() {
        do {
            try audioEngine.start()
            isPlaying = true
            print("✅ Hybrid Audio Engine started with 16 sample/synth channels")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }
    
    func stop() {
        audioEngine.stop()
        isPlaying = false
        stopSequencer()
        print("⏹️ Hybrid Audio Engine stopped")
    }
    
    func loadSample(_ sample: Sample, toTrack track: Int) {
        guard track < 16 else { 
            print("❌ Invalid track number: \(track)")
            return 
        }
        
        // Validate sample file exists
        guard FileManager.default.fileExists(atPath: sample.url.path) else {
            print("❌ Cannot load sample: File does not exist: \(sample.url.path)")
            return
        }
        
        trackConfigs[track].sample = sample
        
        // Also set engine type to sample if it's currently a synth
        if trackConfigs[track].engineType != .sample {
            setEngineType(.sample, forTrack: track)
        }
        
        print("📂 Loaded sample '\(sample.name)' to track \(track + 1)")
    }
    
    // MARK: - Track Controls
    
    func setTrackVolume(_ track: Int, volume: Float) {
        guard track < 16 else { return }
        trackConfigs[track].volume = max(0.0, min(1.0, volume))
        trackMixers[track].outputVolume = trackConfigs[track].volume
    }
    
    func getTrackVolume(_ track: Int) -> Float {
        guard track < 16 else { return 0.0 }
        return trackConfigs[track].volume
    }
    
    func getTrackPan(_ track: Int) -> Float {
        guard track < 16 else { return 0.0 }
        return trackConfigs[track].pan
    }
    
    func toggleMute(_ track: Int) {
        guard track < 16 else { return }
        trackConfigs[track].isMuted.toggle()
        
        // Update track state
        if track < tracks.count {
            tracks[track].isMuted = trackConfigs[track].isMuted
        }
        
        // Apply mute to audio mixer
        trackMixers[track].outputVolume = trackConfigs[track].isMuted ? 0.0 : trackConfigs[track].volume
        print("🔇 Track \(track + 1) \(trackConfigs[track].isMuted ? "muted" : "unmuted")")
    }
    
    func isTrackMuted(_ track: Int) -> Bool {
        guard track < 16 else { return false }
        return trackConfigs[track].isMuted
    }
    
    func toggleSolo(_ track: Int) {
        guard track < 16 else { return }
        trackConfigs[track].isSoloed.toggle()
        
        // Update track state
        if track < tracks.count {
            tracks[track].isSoloed = trackConfigs[track].isSoloed
        }
        
        // Solo logic: if any track is soloed, mute all others
        let hasSoloedTracks = trackConfigs.contains { $0.isSoloed }
        
        for (index, config) in trackConfigs.enumerated() {
            if hasSoloedTracks {
                // If there are soloed tracks, only play soloed tracks
                let shouldPlay = config.isSoloed && !config.isMuted
                trackMixers[index].outputVolume = shouldPlay ? config.volume : 0.0
            } else {
                // No solo tracks, respect individual mute states
                trackMixers[index].outputVolume = config.isMuted ? 0.0 : config.volume
            }
        }
        
        print("🎯 Track \(track + 1) \(trackConfigs[track].isSoloed ? "soloed" : "unsoloed")")
    }
    
    func isTrackSoloed(_ track: Int) -> Bool {
        guard track < 16 else { return false }
        return trackConfigs[track].isSoloed
    }
    
    // MARK: - Initialization helpers
    
    private func loadDefaultSamples() {
        // Load sample files from the Resources directory
        guard let bundlePath = Bundle.main.resourcePath else { 
            print("⚠️ No bundle resource path found")
            return 
        }
        
        let bundleURL = URL(fileURLWithPath: bundlePath)
        let supportedFormats = ["wav", "aiff", "mp3", "m4a", "caf"]
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
            
            for file in files {
                let fileExtension = file.pathExtension.lowercased()
                if supportedFormats.contains(fileExtension) {
                    let sample = Sample(url: file)
                    availableSamples.append(sample)
                    print("✅ Loaded bundled sample: \(sample.name)")
                    
                    // Stop after loading a few samples to avoid overload
                    if availableSamples.count >= 8 { break }
                }
            }
        } catch {
            print("⚠️ Could not load bundled samples: \(error)")
        }
        
        print("📊 Debug: Available samples count: \(availableSamples.count)")
        
        // Set up track configurations (first samples to sample tracks, rest as synths)
        for index in 0..<16 {
            print("🔧 Configuring track \(index)...")
            
            if index < availableSamples.count && index < 8 {
                // Load samples to first tracks (but only if we have samples)
                print("🔧 Setting track \(index) to sample mode with sample: \(availableSamples[index].name)")
                trackConfigs[index].sample = availableSamples[index]
                trackConfigs[index].engineType = .sample
            } else if index >= 8 {
                // Initialize tracks 8-15 as synthesis engines only
                let synthEngines: [SynthEngineType] = [.dvco, .dsaw, .dtone, .dualvco, .analog, .syRaw, .fmOpal, .noise]
                let synthIndex = (index - 8) % synthEngines.count
                print("🔧 Setting track \(index) to synth index \(synthIndex) (engine: \(synthEngines[synthIndex]))")
                trackConfigs[index].engineType = synthEngines[synthIndex]
            } else {
                // For tracks 0-7 if we have fewer samples, set them to sample mode with no sample loaded
                trackConfigs[index].engineType = .sample
                trackConfigs[index].sample = nil
                print("🔧 Setting track \(index) to sample mode (no sample loaded)")
            }
        }
        
        print("🎵 Loaded \(availableSamples.count) samples and set up hybrid sample/synth tracks")
    }
    
    private func initializeTracks() {
        tracks = []
        for index in 0..<16 {
            let config = trackConfigs[index]
            tracks.append(Track(
                id: index,
                name: "Track \(index + 1)",
                volume: config.volume,
                pan: config.pan,
                isMuted: config.isMuted,
                isSoloed: config.isSoloed
            ))
        }
    }
    
    // MARK: - FM Engine Setup (🔥 THE MAGIC!)
    
    private func setupFMEngines() {
        // Create FM-OPAL engine for each track
        for _ in 0..<16 {
            let fmEngine = FMOpalEngine()
            fmEngines.append(fmEngine)
        }
        
        // Load some default presets for immediate testing
        loadDefaultFMPresets()
    }
    
    private func loadDefaultFMPresets() {
        let presets = FMPresetFactory.createFactoryPresets()
        
        // Load different presets on different tracks for instant variety
        if presets.count >= 8 {
            fmEngines[8].loadPreset(presets[0])   // Track 9: SUB BASS
            fmEngines[9].loadPreset(presets[3])   // Track 10: DIGITAL LEAD  
            fmEngines[10].loadPreset(presets[9])  // Track 11: CLASSIC BELL
            fmEngines[11].loadPreset(presets[15]) // Track 12: PURE CHAOS
            fmEngines[12].loadPreset(presets[1])  // Track 13: REESE BASS
            fmEngines[13].loadPreset(presets[4])  // Track 14: SCREAM LEAD
            fmEngines[14].loadPreset(presets[12]) // Track 15: HORN SECTION
            fmEngines[15].loadPreset(presets[18]) // Track 16: DIGITAL SCREAM
        }
        
        // Set tracks 9-16 to FM synthesis by default
        for i in 8..<16 {
            trackEngines[i] = .fmOpal
        }
    }
    
    // MARK: - Real-time Audio Generation (🎵 HEAR THE MAGIC!)
    
    func triggerNote(track: Int, note: UInt8, velocity: Float) {
        guard track >= 0 && track < 16 else { return }
        
        switch trackEngines[track] {
        case .sample:
            // Original sample playback
            if let buffer = loadedSamples[track] {
                let player = trackPlayers[track]
                player.stop()
                player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                player.volume = velocity
                player.play()
            }
            
        case .fmOpal:
            // 🔥 FM-OPAL SYNTHESIS!
            let fmEngine = fmEngines[track]
            fmEngine.noteOn(note: note, velocity: velocity)
            
            // Generate audio buffer and play it
            let frameCount = 4410 // 0.1 seconds at 44.1kHz
            let audioData = fmEngine.renderAudioEnhanced(frameCount: frameCount)
            
            if let buffer = createAudioBuffer(from: audioData) {
                let player = trackPlayers[track]
                player.stop()
                player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                player.play()
            }
            
        default:
            // Other synthesis engines (to be implemented)
            print("Synthesis engine \(trackEngines[track]) not yet implemented")
        }
    }
    
    func releaseNote(track: Int) {
        guard track >= 0 && track < 16 else { return }
        
        if trackEngines[track] == .fmOpal {
            fmEngines[track].noteOff()
        }
    }
    
    // MARK: - Parameter Lock Support (🎛️ ELEKTRON MAGIC!)
    
    func applyParameterLock(track: Int, parameter: String, value: Float) {
        guard track >= 0 && track < 16 else { return }
        
        if trackEngines[track] == .fmOpal {
            fmEngines[track].setParameterLock(parameter: parameter, value: value)
        }
        
        // Update UI parameter tracking
        switch parameter {
        case "FM_ALG":
            trackSynthParams[track].fmAlgorithm = Int(value * 31)
        case "OP1_RATIO":
            trackSynthParams[track].op1Ratio = value * 8.0
        case "OP2_RATIO":
            trackSynthParams[track].op2Ratio = value * 8.0
        case "FM_DEPTH":
            trackSynthParams[track].fmDepth = value * 10.0
        case "FM_FB":
            trackSynthParams[track].feedback = value
        default:
            break
        }
    }
    
    // MARK: - Real-time Control (🎛️ HARDWARE READY!)
    
    func setTrackEngine(track: Int, engine: SynthEngineType) {
        guard track >= 0 && track < 16 else { return }
        trackEngines[track] = engine
        
        if engine == .fmOpal {
            // Load a default preset when switching to FM
            let presets = FMPresetFactory.createFactoryPresets()
            if !presets.isEmpty {
                fmEngines[track].loadPreset(presets[0])
            }
        }
    }
    
    func loadFMPreset(track: Int, preset: FMPreset) {
        guard track >= 0 && track < 16 else { return }
        fmEngines[track].loadPreset(preset)
        trackEngines[track] = .fmOpal
    }
    
    // MARK: - Audio Buffer Creation
    
    private func createAudioBuffer(from audioData: [Float]) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(audioData.count))!
        
        buffer.frameLength = UInt32(audioData.count)
        
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        
        for i in 0..<audioData.count {
            channelData[i] = audioData[i]
        }
        
        return buffer
    }
    
    // MARK: - Quick Test Functions (🎧 INSTANT GRATIFICATION!)
    
    func testFMEngine(track: Int = 8) {
        print("🔥 Testing FM engine on track \(track + 1)!")
        
        // Play a C major chord with different FM sounds
        triggerNote(track: track, note: 60, velocity: 1.0)     // C
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.triggerNote(track: track + 1, note: 64, velocity: 0.8)  // E
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.triggerNote(track: track + 2, note: 67, velocity: 0.8)  // G
        }
        
        // Release notes after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.releaseNote(track: track)
            self.releaseNote(track: track + 1)
            self.releaseNote(track: track + 2)
        }
    }
    
    func testAlgorithmMorphing(track: Int = 8) {
        print("🌀 Testing algorithm morphing!")
        
        triggerNote(track: track, note: 60, velocity: 1.0)
        
        // Morph through different algorithms every 0.5 seconds
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                let algorithm = i * 4 // Jump through algorithms
                self.fmEngines[track].algorithm = algorithm
                print("🎛️ Switched to algorithm \(algorithm)")
            }
        }
        
        // Release after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.releaseNote(track: track)
        }
    }
    
    // MARK: - Additional Control Methods
    
    func setTrackPan(_ track: Int, pan: Float) {
        guard track < 16 else { return }
        trackConfigs[track].pan = max(-1.0, min(1.0, pan))
        
        // Update mix parameters
        // Implementation would adjust the audio mix node pan values
        print("🎛️ Track \(track + 1) pan: \(pan)")
    }
    
    // MARK: - Preview Methods
    
    private var previewTimer: Timer?
    @Published var isPreviewingSample: Bool = false
    @Published var previewingSampleName: String = ""
    
    func previewSample(_ sample: Sample) {
        do {
            // Stop any current preview first
            stopPreview()
            
            // Validate sample file exists
            guard FileManager.default.fileExists(atPath: sample.url.path) else {
                print("❌ Preview failed: Sample file does not exist: \(sample.url.path)")
                return
            }
            
            // Use the first available sample player for preview
            let previewPlayer = samplePlayers[0][0]
            
            // Load and play the sample
            let audioFile = try AVAudioFile(forReading: sample.url)
            previewPlayer.scheduleFile(audioFile, at: nil)
            previewPlayer.volume = 0.8 // Slightly higher volume for preview
            previewPlayer.play()
            
            // Update preview state
            isPreviewingSample = true
            previewingSampleName = sample.name
            
            // Auto-stop preview after 10 seconds to prevent infinite playback
            previewTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                Task { @MainActor in
                    self.stopPreview()
                }
            }
            
            print("🔊 Previewing sample: \(sample.name)")
        } catch {
            print("❌ Failed to preview sample: \(error.localizedDescription)")
            isPreviewingSample = false
            previewingSampleName = ""
        }
    }
    
    /// Stop sample preview
    func stopPreview() {
        samplePlayers[0][0].stop()
        previewTimer?.invalidate()
        previewTimer = nil
        isPreviewingSample = false
        previewingSampleName = ""
        print("⏹️ Stopped sample preview")
    }
    
    // MARK: - Filter Getters
    
    func getFilterResonance(_ track: Int) -> Float {
        guard track < 16 else { return 1.0 }
        return filterResonance
    }
    
    func getFilterCutoff(_ track: Int) -> Float {
        guard track < 16 else { return 1000.0 }
        return filterCutoff
    }
    
    func setFilterCutoff(_ cutoff: Float, forTrack track: Int) {
        guard track < 16 else { return }
        self.filterCutoff = max(20.0, min(20000.0, cutoff))
        // Apply to synthesis voices
        for voice in synthVoices[track] {
            voice.parameters.filterCutoff = self.filterCutoff
        }
    }
    
    func setFilterResonance(_ resonance: Float, forTrack track: Int) {
        guard track < 16 else { return }
        self.filterResonance = max(0.1, min(30.0, resonance))
        // Apply to synthesis voices
        for voice in synthVoices[track] {
            voice.parameters.filterResonance = self.filterResonance
        }
    }
    
    func stopSequencer() {
        isSequencerRunning = false
        sequencerTimer?.invalidate()
        sequencerTimer = nil
        currentStep = 0
        print("⏹️ Sequencer stopped")
    }
    
    // MARK: - Sample Management Methods
    
    func getSample(for track: Int) -> Sample? {
        guard track < 16 else { return nil }
        return trackConfigs[track].sample
    }
    
    // MARK: - Simple Sample Management
    
    /// Super simple sample import - just give it a file URL!
    func importSample(from url: URL) -> Bool {
        do {
            // Copy to user samples directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let samplesDirectory = documentsPath.appendingPathComponent("Samples")
            let destinationURL = samplesDirectory.appendingPathComponent(url.lastPathComponent)
            
            // Create directory if needed
            try FileManager.default.createDirectory(at: samplesDirectory, withIntermediateDirectories: true)
            
            // Copy file
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Add to available samples
            let sample = Sample(url: destinationURL)
            availableSamples.append(sample)
            
            print("📂 Easy sample import successful: \(sample.name)")
            return true
        } catch {
            print("❌ Failed to import sample: \(error)")
            return false
        }
    }
    
    /// Get all available samples (simplified)
    func getAvailableSamples() -> [Sample] {
        // Return existing samples, or create new ones from simple manager
        if availableSamples.isEmpty {
            for simpleSample in sampleManager.availableSamples {
                if simpleSample.exists {
                    let sample = Sample(url: simpleSample.url)
                    availableSamples.append(sample)
                }
            }
        }
        return availableSamples
    }
    
    /// Super simple sample loading - just specify sample name and track number!
    func loadSampleByName(_ name: String, toTrack track: Int) -> Bool {
        if let simpleSample = sampleManager.availableSamples.first(where: { $0.name.lowercased().contains(name.lowercased()) }) {
            let sample = Sample(url: simpleSample.url)
            loadSample(sample, toTrack: track)
            return true
        }
        print("❌ Sample '\(name)' not found")
        return false
    }
    
    /// Refresh samples from file system
    func refreshSamples() {
        availableSamples.removeAll()
        sampleManager.refresh()
        
        // Reload available samples
        _ = getAvailableSamples()
        print("🔄 Samples refreshed - found \(availableSamples.count) samples")
    }
    
    func startSequencer() {
        print("▶️ Starting sequencer...")
        // Basic sequencer implementation
    }
    
    func getCurrentSample(_ track: Int) -> String? {
        guard track < 16 else { return nil }
        return trackConfigs[track].sample?.name
    }
    
    // MARK: - Sample Compatibility
    
    /// Load SimpleSample (from SimpleSampleManager) to a track
    func loadSimpleSample(_ simpleSample: SimpleSample, toTrack track: Int) {
        // Convert SimpleSample to Sample for compatibility
        let sample = Sample(url: simpleSample.url)
        loadSample(sample, toTrack: track)
    }
    
    /// Preview SimpleSample (from SimpleSampleManager)
    func previewSimpleSample(_ simpleSample: SimpleSample) {
        let sample = Sample(url: simpleSample.url)
        previewSample(sample)
    }
    
    // MARK: - SimpleSample Management
    
    func getSimpleSample(for track: Int) -> SimpleSample? {
        guard track < 16, let sample = trackConfigs[track].sample else { return nil }
        
        // Convert Sample to SimpleSample for editing
        return SimpleSample(url: sample.url, category: .user)
    }
    
    func setSimpleSample(_ simpleSample: SimpleSample, for track: Int) {
        guard track < 16 else { return }
        
        // Convert SimpleSample back to Sample and load it
        let sample = Sample(url: simpleSample.url)
        sample.name = simpleSample.name
        
        trackConfigs[track].sample = sample
        loadSample(sample, toTrack: track)
    }
}