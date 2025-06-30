import SwiftUI

struct SynthControlView: View {
    @ObservedObject var audioEngine: AudioEngine
    @State private var selectedTrack: Int = 0
    @State private var showPresetBrowser: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Engine Type Selector
            engineTypeSelector
            
            // Synthesis Parameters
            if audioEngine.getEngineType(forTrack: selectedTrack) != .sample {
                synthParametersView
            }
            
            // Preset Management
            presetControls
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
    
    private var engineTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ENGINE TYPE")
                .font(.caption)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SynthEngineType.allCases, id: \.self) { engineType in
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
                                Color.orange : Color.gray.opacity(0.3)
                            )
                            .foregroundColor(
                                audioEngine.getEngineType(forTrack: selectedTrack) == engineType ?
                                .black : .white
                            )
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var synthParametersView: some View {
        VStack(spacing: 16) {
            // Oscillator Section
            parameterSection(title: "OSCILLATOR") {
                VStack(spacing: 12) {
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
                        label: "WAVE",
                        value: Binding(
                            get: { audioEngine.getSynthParameter(\.wave, forTrack: selectedTrack) },
                            set: { audioEngine.setSynthParameter(\.wave, value: $0, forTrack: selectedTrack) }
                        ),
                        range: 0...1,
                        format: "%.2f"
                    )
                    
                    if audioEngine.getEngineType(forTrack: selectedTrack) == .dsaw {
                        parameterSlider(
                            label: "SYNC",
                            value: Binding(
                                get: { audioEngine.getSynthParameter(\.sync, forTrack: selectedTrack) },
                                set: { audioEngine.setSynthParameter(\.sync, value: $0, forTrack: selectedTrack) }
                            ),
                            range: 0...1,
                            format: "%.2f"
                        )
                    }
                }
            }
            
            // Filter Section
            parameterSection(title: "FILTER") {
                VStack(spacing: 12) {
                    parameterSlider(
                        label: "CUTOFF",
                        value: Binding(
                            get: { audioEngine.getSynthParameter(\.filterCutoff, forTrack: selectedTrack) },
                            set: { audioEngine.setSynthParameter(\.filterCutoff, value: $0, forTrack: selectedTrack) }
                        ),
                        range: 20...20000,
                        format: "%.0f Hz"
                    )
                    
                    parameterSlider(
                        label: "RESONANCE",
                        value: Binding(
                            get: { audioEngine.getSynthParameter(\.filterResonance, forTrack: selectedTrack) },
                            set: { audioEngine.setSynthParameter(\.filterResonance, value: $0, forTrack: selectedTrack) }
                        ),
                        range: 0.1...30.0,
                        format: "%.1f"
                    )
                }
            }
            
            // Envelope Section
            parameterSection(title: "ENVELOPE") {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        parameterSlider(
                            label: "A",
                            value: Binding(
                                get: { audioEngine.getSynthParameter(\.attack, forTrack: selectedTrack) },
                                set: { audioEngine.setSynthParameter(\.attack, value: $0, forTrack: selectedTrack) }
                            ),
                            range: 0.001...10.0,
                            format: "%.3f"
                        )
                        
                        parameterSlider(
                            label: "D",
                            value: Binding(
                                get: { audioEngine.getSynthParameter(\.decay, forTrack: selectedTrack) },
                                set: { audioEngine.setSynthParameter(\.decay, value: $0, forTrack: selectedTrack) }
                            ),
                            range: 0.001...10.0,
                            format: "%.3f"
                        )
                    }
                    
                    HStack(spacing: 12) {
                        parameterSlider(
                            label: "S",
                            value: Binding(
                                get: { audioEngine.getSynthParameter(\.sustain, forTrack: selectedTrack) },
                                set: { audioEngine.setSynthParameter(\.sustain, value: $0, forTrack: selectedTrack) }
                            ),
                            range: 0...1,
                            format: "%.2f"
                        )
                        
                        parameterSlider(
                            label: "R",
                            value: Binding(
                                get: { audioEngine.getSynthParameter(\.release, forTrack: selectedTrack) },
                                set: { audioEngine.setSynthParameter(\.release, value: $0, forTrack: selectedTrack) }
                            ),
                            range: 0.001...10.0,
                            format: "%.3f"
                        )
                    }
                }
            }
        }
    }
    
    private func parameterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            content()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
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
                .accentColor(.orange)
        }
    }
    
    private var presetControls: some View {
        HStack(spacing: 12) {
            Button("PRESETS") {
                showPresetBrowser = true
            }
            .buttonStyle(SoftwaretaktButtonStyle())
            
            Button("SAVE") {
                // Save current parameters as preset
            }
            .buttonStyle(SoftwaretaktButtonStyle())
            
            Button("INIT") {
                // Initialize parameters to default
            }
            .buttonStyle(SoftwaretaktButtonStyle())
        }
        .sheet(isPresented: $showPresetBrowser) {
            PresetBrowserView(audioEngine: audioEngine, selectedTrack: selectedTrack)
        }
    }
}

struct PresetBrowserView: View {
    @ObservedObject var audioEngine: AudioEngine
    let selectedTrack: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(SynthPreset.factory) { preset in
                        PresetCardView(preset: preset) {
                            // Load preset
                            audioEngine.setEngineType(preset.engineType, forTrack: selectedTrack)
                            loadPresetParameters(preset)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Synthesis Presets")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            #else
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
            #endif
        }
    }
    
    private func loadPresetParameters(_ preset: SynthPreset) {
        // Load all parameters from preset
        audioEngine.setSynthParameter(\.pitch, value: preset.parameters.pitch, forTrack: selectedTrack)
        audioEngine.setSynthParameter(\.wave, value: preset.parameters.wave, forTrack: selectedTrack)
        audioEngine.setSynthParameter(\.filterCutoff, value: preset.parameters.filterCutoff, forTrack: selectedTrack)
        audioEngine.setSynthParameter(\.filterResonance, value: preset.parameters.filterResonance, forTrack: selectedTrack)
        audioEngine.setSynthParameter(\.attack, value: preset.parameters.attack, forTrack: selectedTrack)
        audioEngine.setSynthParameter(\.decay, value: preset.parameters.decay, forTrack: selectedTrack)
        audioEngine.setSynthParameter(\.sustain, value: preset.parameters.sustain, forTrack: selectedTrack)
        audioEngine.setSynthParameter(\.release, value: preset.parameters.release, forTrack: selectedTrack)
    }
}

struct PresetCardView: View {
    let preset: SynthPreset
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(preset.engineType.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                Text(preset.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    ForEach(preset.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                    }
                    Spacer()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SoftwaretaktButtonStyle: ButtonStyle {
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
    SynthControlView(audioEngine: AudioEngine())
        .preferredColorScheme(.dark)
}
