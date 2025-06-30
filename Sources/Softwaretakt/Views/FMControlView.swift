import SwiftUI

struct FMControlView: View {
    @ObservedObject var audioEngine: AudioEngine
    let selectedTrack: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // FM Algorithm Selector
            algorithmSelector
            
            // Operator Controls
            operatorControls
            
            // FM Modulation
            modulationControls
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var algorithmSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FM ALGORITHM")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Spacer()
            }
            
            algorithmGrid
        }
    }
    
    private var algorithmGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<32, id: \.self) { algorithm in
                    algorithmButton(algorithm)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func algorithmButton(_ algorithm: Int) -> some View {
        Button("\(algorithm + 1)") {
            audioEngine.setSynthParameter(\.fmAlgorithm, value: algorithm, forTrack: selectedTrack)
        }
        .font(.caption2)
        #if os(macOS)
        .font(.caption2.weight(.bold))
        #else
        .fontWeight(.bold)
        #endif
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Int(audioEngine.getSynthParameter(\.fmAlgorithm, forTrack: selectedTrack)) == algorithm ?
            Color.orange : Color.gray.opacity(0.3)
        )
        .foregroundColor(
            Int(audioEngine.getSynthParameter(\.fmAlgorithm, forTrack: selectedTrack)) == algorithm ?
            .black : .white
        )
        .cornerRadius(4)
    }
    
    private var operatorControls: some View {
        VStack(spacing: 12) {
            Text("OPERATORS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            // Operator 1 & 2
            HStack(spacing: 16) {
                operatorSection(number: 1, ratioKeyPath: \.op1Ratio, levelKeyPath: \.op1Level)
                operatorSection(number: 2, ratioKeyPath: \.op2Ratio, levelKeyPath: \.op2Level)
            }
            
            // Operator 3 & 4
            HStack(spacing: 16) {
                operatorSection(number: 3, ratioKeyPath: \.op3Ratio, levelKeyPath: \.op3Level)
                operatorSection(number: 4, ratioKeyPath: \.op4Ratio, levelKeyPath: \.op4Level)
            }
        }
    }
    
    private func operatorSection(
        number: Int,
        ratioKeyPath: WritableKeyPath<SynthParameters, Float>,
        levelKeyPath: WritableKeyPath<SynthParameters, Float>
    ) -> some View {
        VStack(spacing: 8) {
            Text("OP\(number)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            VStack(spacing: 4) {
                Text("RATIO")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Slider(
                    value: Binding(
                        get: { audioEngine.getSynthParameter(ratioKeyPath, forTrack: selectedTrack) },
                        set: { audioEngine.setSynthParameter(ratioKeyPath, value: $0, forTrack: selectedTrack) }
                    ),
                    in: 0.25...16.0
                )
                .accentColor(.orange)
                
                Text(String(format: "%.2f", audioEngine.getSynthParameter(ratioKeyPath, forTrack: selectedTrack)))
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("LEVEL")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Slider(
                    value: Binding(
                        get: { audioEngine.getSynthParameter(levelKeyPath, forTrack: selectedTrack) },
                        set: { audioEngine.setSynthParameter(levelKeyPath, value: $0, forTrack: selectedTrack) }
                    ),
                    in: 0...1
                )
                .accentColor(.orange)
                
                Text(String(format: "%.2f", audioEngine.getSynthParameter(levelKeyPath, forTrack: selectedTrack)))
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
    
    private var modulationControls: some View {
        VStack(spacing: 12) {
            Text("MODULATION")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("FM DEPTH")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Slider(
                        value: Binding(
                            get: { audioEngine.getSynthParameter(\.fmDepth, forTrack: selectedTrack) },
                            set: { audioEngine.setSynthParameter(\.fmDepth, value: $0, forTrack: selectedTrack) }
                        ),
                        in: 0...1
                    )
                    .accentColor(.orange)
                    
                    Text(String(format: "%.2f", audioEngine.getSynthParameter(\.fmDepth, forTrack: selectedTrack)))
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text("FEEDBACK")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Slider(
                        value: Binding(
                            get: { audioEngine.getSynthParameter(\.feedback, forTrack: selectedTrack) },
                            set: { audioEngine.setSynthParameter(\.feedback, value: $0, forTrack: selectedTrack) }
                        ),
                        in: 0...1
                    )
                    .accentColor(.orange)
                    
                    Text(String(format: "%.2f", audioEngine.getSynthParameter(\.feedback, forTrack: selectedTrack)))
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// Enhanced Synthesis Control View with FM support
struct EnhancedSynthControlView: View {
    @ObservedObject var audioEngine: AudioEngine
    @State private var selectedTrack: Int = 0
    @State private var showPresetBrowser: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Track Selector
                trackSelector
                
                // Engine Type Selector
                engineTypeSelector
                
                // Engine-Specific Controls
                if audioEngine.getEngineType(forTrack: selectedTrack) == .fmOpal {
                    FMControlView(audioEngine: audioEngine, selectedTrack: selectedTrack)
                } else if audioEngine.getEngineType(forTrack: selectedTrack) != .sample {
                    standardSynthControls
                }
                
                // Preset Management
                presetControls
            }
            .padding()
        }
        .background(Color.black.opacity(0.9))
        .navigationTitle("Synthesis Controls")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var trackSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRACK SELECTION")
                .font(.caption)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<16, id: \.self) { track in
                        Button("T\(track + 1)") {
                            selectedTrack = track
                        }
                        .font(.caption)
                        #if os(macOS)
                        .font(.caption.weight(.bold))
                        #else
                        .fontWeight(.bold)
                        #endif
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTrack == track ? Color.cyan : Color.gray.opacity(0.3))
                        .foregroundColor(selectedTrack == track ? .black : .white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var engineTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ENGINE TYPE")
                .font(.caption)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SynthEngineType.allCases.filter { $0 != .sample }, id: \.self) { engineType in
                        Button(action: {
                            audioEngine.setEngineType(engineType, forTrack: selectedTrack)
                        }) {
                            VStack(spacing: 4) {
                                Text(engineType.rawValue)
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                
                                Text(engineType.displayName)
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                audioEngine.getEngineType(forTrack: selectedTrack) == engineType ?
                                (engineType == .fmOpal ? Color.orange : Color.cyan) : Color.gray.opacity(0.3)
                            )
                            .foregroundColor(
                                audioEngine.getEngineType(forTrack: selectedTrack) == engineType ? .black : .white
                            )
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var standardSynthControls: some View {
        VStack(spacing: 16) {
            // Standard synthesis controls for non-FM engines
            Text("SYNTHESIS PARAMETERS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.cyan)
            
            // Basic parameters
            parameterSlider(
                label: "PITCH",
                value: Binding(
                    get: { audioEngine.getSynthParameter(\.pitch, forTrack: selectedTrack) },
                    set: { audioEngine.setSynthParameter(\.pitch, value: $0, forTrack: selectedTrack) }
                ),
                range: -24...24,
                format: "%.0f"
            )
            
            parameterSlider(
                label: "FILTER CUTOFF",
                value: Binding(
                    get: { audioEngine.getSynthParameter(\.filterCutoff, forTrack: selectedTrack) },
                    set: { audioEngine.setSynthParameter(\.filterCutoff, value: $0, forTrack: selectedTrack) }
                ),
                range: 20...20000,
                format: "%.0f Hz"
            )
        }
        .padding()
        .background(Color.cyan.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func parameterSlider(
        label: String,
        value: Binding<Float>,
        range: ClosedRange<Float>,
        format: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(String(format: format, value.wrappedValue))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Slider(value: value, in: range)
                .accentColor(.cyan)
        }
    }
    
    private var presetControls: some View {
        HStack(spacing: 12) {
            Button("FM PRESETS") {
                showPresetBrowser = true
            }
            .buttonStyle(OpalButtonStyle())
            
            Button("SAVE") {
                // Save current parameters as preset
            }
            .buttonStyle(OpalButtonStyle())
            
            Button("INIT") {
                // Initialize parameters to default
            }
            .buttonStyle(OpalButtonStyle())
        }
        .sheet(isPresented: $showPresetBrowser) {
            PresetBrowserView(audioEngine: audioEngine, selectedTrack: selectedTrack)
        }
    }
}

struct OpalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            #if os(macOS)
            .font(.caption.weight(.bold))
            #else
            .fontWeight(.bold)
            #endif
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? Color.orange.opacity(0.8) : Color.orange)
            .foregroundColor(.black)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    NavigationView {
        EnhancedSynthControlView(audioEngine: AudioEngine())
    }
    .preferredColorScheme(.dark)
}
