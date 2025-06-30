import Foundation
import CoreMIDI
import Combine

@MainActor
class MIDIManager: ObservableObject {
    @Published var isPush2Connected = false
    @Published var isLaunchkeyConnected = false
    
    // Computed property for overall connection status
    var isConnected: Bool {
        isPush2Connected || isLaunchkeyConnected
    }
    
    var audioEngine: AudioEngine?
    
    private var midiClient: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var push2Controller: Push2Controller?
    private var launchkeyController: LaunchkeyController?
    
    private let midiNotification: MIDINotifyProc = { message, refCon in
        // Handle MIDI system notifications
        print("MIDI notification received")
    }
    
    func setup() {
        createMIDIClient()
        createInputPort()
        scanForControllers()
        
        print("🎛️ MIDI Manager initialized")
    }
    
    private func createMIDIClient() {
        let status = MIDIClientCreate("SoftwaretaktMIDI" as CFString, midiNotification, nil, &midiClient)
        if status == noErr {
            print("✅ MIDI client created successfully")
        } else {
            print("❌ Failed to create MIDI client: \(status)")
        }
    }
    
    private func createInputPort() {
        let status = MIDIInputPortCreate(midiClient, "SoftwaretaktInput" as CFString, midiInputProc, nil, &inputPort)
        if status == noErr {
            print("✅ MIDI input port created successfully")
        } else {
            print("❌ Failed to create MIDI input port: \(status)")
        }
    }
    
    private func scanForControllers() {
        let sourceCount = MIDIGetNumberOfSources()
        
        for i in 0..<sourceCount {
            let source = MIDIGetSource(i)
            
            var deviceName: Unmanaged<CFString>?
            let status = MIDIObjectGetStringProperty(source, kMIDIPropertyName, &deviceName)
            
            if status == noErr, let name = deviceName?.takeRetainedValue() as String? {
                print("🎹 Found MIDI device: \(name)")
                
                // Connect to recognized controllers
                if name.lowercased().contains("push") {
                    connectToPush2(source: source, name: name)
                } else if name.lowercased().contains("launchkey") {
                    connectToLaunchkey(source: source, name: name)
                }
                
                // Connect to the source
                MIDIPortConnectSource(inputPort, source, nil)
            }
        }
    }
    
    private func connectToPush2(source: MIDIEndpointRef, name: String) {
        push2Controller = Push2Controller(audioEngine: audioEngine)
        isPush2Connected = true
        print("🎛️ Connected to Push 2: \(name)")
    }
    
    private func connectToLaunchkey(source: MIDIEndpointRef, name: String) {
        launchkeyController = LaunchkeyController(audioEngine: audioEngine)
        isLaunchkeyConnected = true
        print("🎹 Connected to Launchkey: \(name)")
    }
    
    func refreshConnections() {
        isPush2Connected = false
        isLaunchkeyConnected = false
        scanForControllers()
    }
}

// MIDI input callback
private let midiInputProc: MIDIReadProc = { packetList, readProcRefCon, srcConnRefCon in
    let packets = packetList.pointee
    var packet = packets.packet
    
    for _ in 0..<packets.numPackets {
        let data = withUnsafePointer(to: &packet.data) {
            Data(bytes: $0, count: Int(packet.length))
        }
        
        // Parse MIDI message
        if data.count >= 3 {
            let status = data[0]
            let data1 = data[1]
            let data2 = data[2]
            
            // Get the MIDI manager instance to handle the message
            DispatchQueue.main.async {
                MIDIMessageHandler.shared.handleMIDIMessage(
                    status: status,
                    data1: data1,
                    data2: data2
                )
            }
        }
        
        // Move to next packet
        packet = MIDIPacketNext(&packet).pointee
    }
}

// Singleton to handle MIDI messages
class MIDIMessageHandler {
    static let shared = MIDIMessageHandler()
    weak var audioEngine: AudioEngine?
    
    private init() {}
    
    @MainActor
    func handleMIDIMessage(status: UInt8, data1: UInt8, data2: UInt8) {
        let messageType = status & 0xF0
        let channel = status & 0x0F
        
        switch messageType {
        case 0x90: // Note On
            handleNoteOn(note: data1, velocity: data2, channel: channel)
        case 0x80: // Note Off
            handleNoteOff(note: data1, channel: channel)
        case 0xB0: // Control Change
            handleControlChange(controller: data1, value: data2, channel: channel)
        default:
            break
        }
    }
    
    @MainActor
    private func handleNoteOn(note: UInt8, velocity: UInt8, channel: UInt8) {
        guard velocity > 0 else {
            handleNoteOff(note: note, channel: channel)
            return
        }
        
        // Map MIDI notes to pad triggers
        let padIndex = Int(note) % 64
        let track = Int(channel) % 16
        
        audioEngine?.triggerSample(track: track, padIndex: padIndex)
        
        print("🎵 MIDI Note On: \(note) vel:\(velocity) ch:\(channel) -> pad:\(padIndex) track:\(track)")
    }
    
    private func handleNoteOff(note: UInt8, channel: UInt8) {
        // Handle note off if needed (for sustained samples)
        print("🎵 MIDI Note Off: \(note) ch:\(channel)")
    }
    
    @MainActor
    private func handleControlChange(controller: UInt8, value: UInt8, channel: UInt8) {
        let normalizedValue = Float(value) / 127.0
        let track = Int(channel) % 16
        
        // Map common controllers
        switch controller {
        case 7: // Volume
            audioEngine?.setTrackVolume(track, volume: normalizedValue)
        case 10: // Pan
            let panValue = (normalizedValue * 2.0) - 1.0 // Convert to -1 to 1 range
            audioEngine?.setTrackPan(track, pan: panValue)
        case 74: // Filter cutoff (common mapping)
            let cutoffValue = 20.0 + (normalizedValue * 19980.0) // 20Hz to 20kHz
            audioEngine?.setFilterCutoff(cutoffValue, forTrack: track)
        case 71: // Filter resonance
            let resonanceValue = normalizedValue * 30.0 // 0 to 30
            audioEngine?.setFilterResonance(resonanceValue, forTrack: track)
        default:
            break
        }
        
        print("🎛️ MIDI CC: \(controller) val:\(value) ch:\(channel) -> track:\(track)")
    }
}
