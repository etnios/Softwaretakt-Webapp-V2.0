import AudioToolbox
import AudioUnit
import AVFoundation
import CoreAudioKit

// 🎛️ SOFTWARETAKT AU3 - PROFESSIONAL AUDIO UNIT PLUGIN

public class SoftwaretaktAudioUnit: AUAudioUnit {
    
    // MARK: - Core Properties
    
    /// The audio engine that handles all synthesis and processing
    private var audioEngine: AudioEngine!
    
    /// Audio buffers for processing
    private var inputBuffer: AVAudioPCMBuffer!
    private var outputBuffer: AVAudioPCMBuffer!
    
    /// Current playing state
    private var isPlaying = false
    private var currentBeatPosition: Float = 0.0
    
    // MARK: - AU Parameters
    
    /// Internal parameter tree for AU3 automation
    private var internalParameterTree: AUParameterTree!
    
    /// Track selection parameter (0-15)
    private var trackSelectParam: AUParameter!
    
    /// Trigger parameters for each track (16 tracks)
    private var trackTriggerParams: [AUParameter] = []
    
    /// Volume parameters for each track
    private var trackVolumeParams: [AUParameter] = []
    
    /// Pan parameters for each track
    private var trackPanParams: [AUParameter] = []
    
    /// FM synthesis parameters
    private var fmAlgorithmParam: AUParameter!
    private var fmDepthParam: AUParameter!
    private var op1RatioParam: AUParameter!
    private var op2RatioParam: AUParameter!
    
    // MARK: - Initialization
    
    public override init(componentDescription: AudioComponentDescription, 
                        options: AudioComponentInstantiationOptions = []) throws {
        
        try super.init(componentDescription: componentDescription, options: options)
        
        // Initialize audio engine on main actor
        Task { @MainActor in
            audioEngine = AudioEngine()
        }
        
        // Setup AU parameters
        setupParameters()
        
        // Set maximum frames to render
        maximumFramesToRender = 512
        
        // Setup audio buffers (simplified for macOS compatibility)
        setupAudioBuffers()
        
        print("🔥 Softwaretakt AU3 initialized!")
    }
    
    private func setupParameters() {
        // Create parameter tree with all automatable parameters
        var allParameters: [AUParameter] = []
        
        // Track selection (0-15)
        trackSelectParam = AUParameterTree.createParameter(
            withIdentifier: "trackSelect",
            name: "Track Select",
            address: 0,
            min: 0, max: 15,
            unit: .indexed,
            unitName: nil,
            flags: [.flag_IsReadable, .flag_IsWritable],
            valueStrings: nil,
            dependentParameters: nil
        )
        allParameters.append(trackSelectParam)
        
        // Track triggers (1-16)
        for i in 0..<16 {
            let triggerParam = AUParameterTree.createParameter(
                withIdentifier: "track\(i+1)Trigger",
                name: "Track \(i+1) Trigger",
                address: AUParameterAddress(100 + i),
                min: 0, max: 1,
                unit: .boolean,
                unitName: nil,
                flags: [.flag_IsReadable, .flag_IsWritable],
                valueStrings: nil,
                dependentParameters: nil
            )
            trackTriggerParams.append(triggerParam)
            allParameters.append(triggerParam)
        }
        
        // Track volumes (1-16)
        for i in 0..<16 {
            let volumeParam = AUParameterTree.createParameter(
                withIdentifier: "track\(i+1)Volume",
                name: "Track \(i+1) Volume",
                address: AUParameterAddress(200 + i),
                min: 0.0, max: 1.0,
                unit: .linearGain,
                unitName: nil,
                flags: [.flag_IsReadable, .flag_IsWritable],
                valueStrings: nil,
                dependentParameters: nil
            )
            volumeParam.value = 0.8 // Default volume
            trackVolumeParams.append(volumeParam)
            allParameters.append(volumeParam)
        }
        
        // Track panning (1-16)
        for i in 0..<16 {
            let panParam = AUParameterTree.createParameter(
                withIdentifier: "track\(i+1)Pan",
                name: "Track \(i+1) Pan",
                address: AUParameterAddress(300 + i),
                min: -1.0, max: 1.0,
                unit: .pan,
                unitName: nil,
                flags: [.flag_IsReadable, .flag_IsWritable],
                valueStrings: nil,
                dependentParameters: nil
            )
            panParam.value = 0.0 // Center pan
            trackPanParams.append(panParam)
            allParameters.append(panParam)
        }
        
        // FM Synthesis parameters
        fmAlgorithmParam = AUParameterTree.createParameter(
            withIdentifier: "fmAlgorithm",
            name: "FM Algorithm",
            address: 400,
            min: 0, max: 31,
            unit: .indexed,
            unitName: nil,
            flags: [.flag_IsReadable, .flag_IsWritable],
            valueStrings: nil,
            dependentParameters: nil
        )
        allParameters.append(fmAlgorithmParam)
        
        fmDepthParam = AUParameterTree.createParameter(
            withIdentifier: "fmDepth",
            name: "FM Depth",
            address: 401,
            min: 0.0, max: 10.0,
            unit: .generic,
            unitName: nil,
            flags: [.flag_IsReadable, .flag_IsWritable],
            valueStrings: nil,
            dependentParameters: nil
        )
        fmDepthParam.value = 1.0
        allParameters.append(fmDepthParam)
        
        op1RatioParam = AUParameterTree.createParameter(
            withIdentifier: "op1Ratio",
            name: "Op1 Ratio",
            address: 402,
            min: 0.5, max: 8.0,
            unit: .ratio,
            unitName: nil,
            flags: [.flag_IsReadable, .flag_IsWritable],
            valueStrings: nil,
            dependentParameters: nil
        )
        op1RatioParam.value = 1.0
        allParameters.append(op1RatioParam)
        
        op2RatioParam = AUParameterTree.createParameter(
            withIdentifier: "op2Ratio",
            name: "Op2 Ratio",
            address: 403,
            min: 0.5, max: 8.0,
            unit: .ratio,
            unitName: nil,
            flags: [.flag_IsReadable, .flag_IsWritable],
            valueStrings: nil,
            dependentParameters: nil
        )
        op2RatioParam.value = 1.0
        allParameters.append(op2RatioParam)
        
        // Create parameter tree
        internalParameterTree = AUParameterTree.createTree(withChildren: allParameters)
        
        // Set up parameter observation
        internalParameterTree.implementorValueObserver = { [weak self] parameter, value in
            self?.handleParameterChange(parameter: parameter, value: value)
        }
        
        // Set up parameter provider
        internalParameterTree.implementorValueProvider = { [weak self] parameter in
            return self?.getParameterValue(parameter: parameter) ?? 0.0
        }
    }
    
    private func setupAudioBuffers() {
        // Create a standard format for macOS/iOS compatibility
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        inputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512)
        outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512)
    }
    
    // MARK: - AU3 Overrides
    
    public override var audioUnitName: String? {
        return "Softwaretakt"
    }
    
    public override var manufacturerName: String {
        return "AI Music Generator"
    }
    
    public override var componentVersion: UInt32 {
        return 0x00010000 // Version 1.0.0
    }
    
    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()
        
        // Start the audio engine on main actor
        Task { @MainActor in
            audioEngine?.start()
        }
        
        print("🔥 Softwaretakt AU3 render resources allocated")
    }
    
    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        
        // Stop the audio engine on main actor
        Task { @MainActor in
            audioEngine?.stop()
        }
        
        print("🛑 Softwaretakt AU3 render resources deallocated")
    }
    
    // MARK: - Audio Rendering
    
    public override var internalRenderBlock: AUInternalRenderBlock {
        return { [weak self] (actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock) in
            
            guard let self = self else { return kAudioUnitErr_NoConnection }
            
            // Get output buffer
            let outputBuffer = UnsafeMutableAudioBufferListPointer(outputData)
            
            // Clear output buffer first
            for i in 0..<outputBuffer.count {
                memset(outputBuffer[i].mData, 0, Int(outputBuffer[i].mDataByteSize))
            }
            
            // Process MIDI events if any
            // TODO: Implement MIDI event processing in future version
            
            // 🔥 RENDER AUDIO FROM SOFTWARETAKT ENGINE
            self.renderAudioToBuffer(outputBuffer: outputBuffer, frameCount: frameCount)
            
            return noErr
        }
    }
    
    private func renderAudioToBuffer(outputBuffer: UnsafeMutableAudioBufferListPointer, frameCount: AUAudioFrameCount) {
        // Get audio from our engine's main mixer
        guard outputBuffer.count >= 2, // Stereo output
              let leftChannel = outputBuffer[0].mData?.assumingMemoryBound(to: Float.self),
              let rightChannel = outputBuffer[1].mData?.assumingMemoryBound(to: Float.self) else {
            return
        }
        
        // For now, we'll generate a simple test tone to verify AU3 is working
        // In a full implementation, this would render from our AudioEngine
        let sampleRate: Double = 44100.0 // Standard sample rate
        
        for frame in 0..<Int(frameCount) {
            // Generate test sine wave at 440Hz when any track is triggered
            let time = Float(frame) / Float(sampleRate)
            let amplitude: Float = isPlaying ? 0.1 : 0.0
            let sample = amplitude * sin(2.0 * Float.pi * 440.0 * time)
            
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        // Update buffer data size
        outputBuffer[0].mDataByteSize = UInt32(frameCount * UInt32(MemoryLayout<Float>.size))
        outputBuffer[1].mDataByteSize = UInt32(frameCount * UInt32(MemoryLayout<Float>.size))
    }
    
    // MARK: - MIDI Handling
    
    private func handleMIDIEvent(event: inout AURenderEvent) {
        let midiData = event.MIDI
        let status = midiData.data.0
        let data1 = midiData.data.1
        let data2 = midiData.data.2
        
        let command = status & 0xF0
        let channel = status & 0x0F
        
        switch command {
        case 0x90: // Note On
            if data2 > 0 { // Velocity > 0
                handleNoteOn(note: data1, velocity: data2, channel: channel)
            } else { // Velocity = 0 (Note Off)
                handleNoteOff(note: data1, channel: channel)
            }
        case 0x80: // Note Off
            handleNoteOff(note: data1, channel: channel)
        case 0xB0: // Control Change
            handleControlChange(controller: data1, value: data2, channel: channel)
        default:
            break
        }
    }
    
    private func handleNoteOn(note: UInt8, velocity: UInt8, channel: UInt8) {
        let track = Int(channel) % 16
        let normalizedVelocity = Float(velocity) / 127.0
        
        // Set playing state for audio rendering
        isPlaying = true
        
        DispatchQueue.main.async {
            self.audioEngine.triggerTrack(track, note: note, velocity: normalizedVelocity)
        }
    }
    
    private func handleNoteOff(note: UInt8, channel: UInt8) {
        let track = Int(channel) % 16
        
        // Stop playing for audio rendering
        isPlaying = false
        
        DispatchQueue.main.async {
            self.audioEngine.releaseNote(track: track)
        }
    }
    
    private func handleControlChange(controller: UInt8, value: UInt8, channel: UInt8) {
        let normalizedValue = Float(value) / 127.0
        let track = Int(channel) % 16
        
        switch controller {
        case 7: // Volume
            DispatchQueue.main.async {
                self.audioEngine.setTrackVolume(track, volume: normalizedValue)
            }
        case 10: // Pan
            let panValue = (normalizedValue * 2.0) - 1.0 // Convert to -1 to 1 range
            DispatchQueue.main.async {
                self.audioEngine.setTrackPan(track, pan: panValue)
            }
        default:
            break
        }
    }
    
    // MARK: - Parameter Handling
    
    private func handleParameterChange(parameter: AUParameter, value: AUValue) {
        let address = parameter.address
        
        switch address {
        case 0: // Track select
            // Track selection handled by host
            break
            
        case 100..<116: // Track triggers (100-115)
            let track = Int(address - 100)
            if value > 0.5 {
                DispatchQueue.main.async {
                    self.audioEngine.triggerTrack(track)
                }
            }
            
        case 200..<216: // Track volumes (200-215)
            let track = Int(address - 200)
            DispatchQueue.main.async {
                self.audioEngine.setTrackVolume(track, volume: value)
            }
            
        case 300..<316: // Track panning (300-315)
            let track = Int(address - 300)
            DispatchQueue.main.async {
                self.audioEngine.setTrackPan(track, pan: value)
            }
            
        case 400: // FM Algorithm
            let selectedTrack = Int(trackSelectParam.value)
            DispatchQueue.main.async {
                self.audioEngine.setSynthParameter(\.fmAlgorithm, value: Int(value), forTrack: selectedTrack)
            }
            
        case 401: // FM Depth
            let selectedTrack = Int(trackSelectParam.value)
            DispatchQueue.main.async {
                self.audioEngine.setSynthParameter(\.fmDepth, value: value, forTrack: selectedTrack)
            }
            
        case 402: // Op1 Ratio
            let selectedTrack = Int(trackSelectParam.value)
            DispatchQueue.main.async {
                self.audioEngine.setSynthParameter(\.op1Ratio, value: value, forTrack: selectedTrack)
            }
            
        case 403: // Op2 Ratio
            let selectedTrack = Int(trackSelectParam.value)
            DispatchQueue.main.async {
                self.audioEngine.setSynthParameter(\.op2Ratio, value: value, forTrack: selectedTrack)
            }
            
        default:
            break
        }
    }
    
    private func getParameterValue(parameter: AUParameter) -> AUValue {
        let address = parameter.address
        
        switch address {
        case 0: // Track select
            return trackSelectParam.value
            
        case 200..<216: // Track volumes
            let track = Int(address - 200)
            return trackVolumeParams[track].value
            
        case 300..<316: // Track panning
            let track = Int(address - 300)
            return trackPanParams[track].value
            
        case 400: // FM Algorithm
            return fmAlgorithmParam.value
            
        case 401: // FM Depth
            return fmDepthParam.value
            
        case 402: // Op1 Ratio
            return op1RatioParam.value
            
        case 403: // Op2 Ratio
            return op2RatioParam.value
            
        default:
            return 0.0
        }
    }
    
    // MARK: - AU3 Properties
    
    public override var parameterTree: AUParameterTree? {
        get {
            return self.internalParameterTree
        }
        set {
            // Allow setting but maintain our internal tree
            self.internalParameterTree = newValue ?? self.internalParameterTree
        }
    }
    
    public override var canProcessInPlace: Bool {
        return false // We process out-of-place for better control
    }
}

// MARK: - AU3 Factory and Component Registration

// Component Description for AUM and other hosts
public let softwaretaktComponentDescription = AudioComponentDescription(
    componentType: kAudioUnitType_MusicDevice, // Instrument type
    componentSubType: 0x536F7478, // 'Sotx' - unique 4-char code
    componentManufacturer: 0x41494D47, // 'AIMG' - AI Music Generator
    componentFlags: AudioComponentFlags.sandboxSafe.rawValue,
    componentFlagsMask: 0
)

@objc public class SoftwaretaktAudioUnitFactory: NSObject, AUAudioUnitFactory {
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        return try SoftwaretaktAudioUnit(componentDescription: componentDescription)
    }
    
    // NSExtensionRequestHandling conformance
    public func beginRequest(with context: NSExtensionContext) {
        // Extension handling if needed
    }
}
