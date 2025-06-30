import SwiftUI

// 🔥 FM TEST CONSOLE - INSTANT GRATIFICATION!

struct FMTestConsole: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var selectedPreset: Int = 0
    @State private var testTrack: Int = 8
    @State private var currentAlgorithm: Int = 0
    
    let presets = FMPresetFactory.createFactoryPresets()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎛️ FM-OPAL TEST CONSOLE")
                .font(.title.bold())
                .foregroundColor(.white)
            
            // Quick test buttons
            HStack(spacing: 20) {
                Button("🔥 TEST FM") {
                    audioEngine.testFMEngine()
                }
                .buttonStyle(TestButtonStyle(color: .red))
                
                Button("🌀 MORPH ALGORITHMS") {
                    audioEngine.testAlgorithmMorphing()
                }
                .buttonStyle(TestButtonStyle(color: .orange))
                
                Button("🎹 CHORD TEST") {
                    testChord()
                }
                .buttonStyle(TestButtonStyle(color: .blue))
            }
            
            // Manual note triggering
            VStack(spacing: 12) {
                Text("MANUAL TRIGGER")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 10) {
                    ForEach([60, 64, 67, 72], id: \.self) { note in
                        Button(noteName(note)) {
                            audioEngine.triggerNote(track: testTrack, note: UInt8(note), velocity: 1.0)
                            
                            // Auto-release after 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                audioEngine.releaseNote(track: testTrack)
                            }
                        }
                        .frame(width: 60, height: 40)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Preset selection
            VStack(spacing: 12) {
                Text("FM PRESETS")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(presets.enumerated()), id: \.offset) { index, preset in
                            Button(preset.name) {
                                audioEngine.loadFMPreset(track: testTrack, preset: preset)
                                selectedPreset = index
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedPreset == index ? Color.green : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Algorithm selector
            VStack(spacing: 12) {
                Text("ALGORITHM: \(currentAlgorithm)")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack {
                    Button("◀") {
                        if currentAlgorithm > 0 {
                            currentAlgorithm -= 1
                            audioEngine.applyParameterLock(track: testTrack, parameter: "FM_ALG", value: Float(currentAlgorithm) / 31.0)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Slider(value: Binding(
                        get: { Float(currentAlgorithm) },
                        set: { 
                            currentAlgorithm = Int($0)
                            audioEngine.applyParameterLock(track: testTrack, parameter: "FM_ALG", value: Float(currentAlgorithm) / 31.0)
                        }
                    ), in: 0...31, step: 1)
                    .accentColor(.red)
                    
                    Button("▶") {
                        if currentAlgorithm < 31 {
                            currentAlgorithm += 1
                            audioEngine.applyParameterLock(track: testTrack, parameter: "FM_ALG", value: Float(currentAlgorithm) / 31.0)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            // Track selector
            HStack {
                Text("TEST TRACK:")
                    .foregroundColor(.gray)
                
                Picker("Track", selection: $testTrack) {
                    ForEach(8..<16, id: \.self) { track in
                        Text("Track \(track + 1)").tag(track)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .accentColor(.blue)
            }
            
            // Chaos mode
            Button("🌪️ PURE CHAOS MODE") {
                chaosModeTest()
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.headline.bold())
            
            Spacer()
        }
        .padding()
        .background(Color.black)
        .foregroundColor(.white)
    }
    
    private func testChord() {
        // Play a chord with different FM sounds
        let notes: [UInt8] = [60, 64, 67, 72] // C, E, G, C
        
        for (index, note) in notes.enumerated() {
            let track = testTrack + index
            if track < 16 {
                audioEngine.triggerNote(track: track, note: note, velocity: 0.8)
                
                // Release after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    audioEngine.releaseNote(track: track)
                }
            }
        }
    }
    
    private func chaosModeTest() {
        // Load chaos presets and trigger random notes
        let chaosPresets = presets.filter { $0.category == .chaos }
        
        for i in 0..<4 {
            let track = testTrack + i
            if track < 16 && i < chaosPresets.count {
                audioEngine.loadFMPreset(track: track, preset: chaosPresets[i])
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                    let randomNote = UInt8.random(in: 48...72)
                    audioEngine.triggerNote(track: track, note: randomNote, velocity: 1.0)
                    
                    // Release after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        audioEngine.releaseNote(track: track)
                    }
                }
            }
        }
    }
    
    private func noteName(_ midiNote: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (midiNote / 12) - 1
        let note = noteNames[midiNote % 12]
        return "\(note)\(octave)"
    }
}

struct TestButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct FMTestConsole_Previews: PreviewProvider {
    static var previews: some View {
        FMTestConsole()
            .environmentObject(AudioEngine())
            .preferredColorScheme(.dark)
    }
}
