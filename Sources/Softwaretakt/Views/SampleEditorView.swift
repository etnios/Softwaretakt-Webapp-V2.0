import SwiftUI
import AVFoundation

struct SampleEditorView: View {
    @Binding var sample: SimpleSample
    @EnvironmentObject var audioEngine: AudioEngine
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: EditorTab = .envelope
    @State private var isPlaying: Bool = false
    @State private var waveformData: [Float] = []
    @State private var playbackPosition: Float = 0.0
    @State private var showAutoTuneSettings: Bool = false
    
    enum EditorTab: String, CaseIterable {
        case envelope = "Envelope"
        case pitch = "Pitch"
        case filter = "Filter"
        case playback = "Playback"
        
        var icon: String {
            switch self {
            case .envelope: return "waveform.path.ecg"
            case .pitch: return "tuningfork"
            case .filter: return "slider.horizontal.3"
            case .playback: return "play.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .envelope: return .green
            case .pitch: return .orange
            case .filter: return .purple
            case .playback: return .cyan
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Waveform Display
                    waveformView
                        .frame(height: 120)
                        .padding(.horizontal, 20)
                    
                    // Tab Selector
                    tabSelector
                    
                    // Content Area
                    contentArea
                        .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Transport Controls
                    transportControls
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            loadWaveformData()
        }
        .presentationBackground(.ultraThinMaterial)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.gray)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(sample.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(sample.durationString) • \(Int(sample.sampleRate))Hz")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button("Save") {
                // Save changes and dismiss
                dismiss()
            }
            .foregroundColor(.cyan)
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Waveform View
    
    private var waveformView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            if !waveformData.isEmpty {
                WaveformShape(data: waveformData)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.8),
                                Color.blue.opacity(0.6)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
                    .padding(8)
            }
            
            // Interactive sample region overlay
            InteractiveWaveformOverlay(
                startPoint: Binding(
                    get: { sample.editParameters.startPoint },
                    set: { sample.editParameters.startPoint = $0 }
                ),
                endPoint: Binding(
                    get: { sample.editParameters.endPoint },
                    set: { sample.editParameters.endPoint = $0 }
                ),
                loopStart: Binding(
                    get: { sample.editParameters.loopStart },
                    set: { sample.editParameters.loopStart = $0 }
                ),
                loopEnd: Binding(
                    get: { sample.editParameters.loopEnd },
                    set: { sample.editParameters.loopEnd = $0 }
                ),
                loopEnabled: sample.editParameters.loopEnabled,
                sampleDuration: sample.duration
            )
            
            // Playback position indicator
            if isPlaying {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2)
                    .position(x: CGFloat(playbackPosition) * (UIScreen.main.bounds.width - 40), y: 60)
                    .animation(.linear(duration: 0.1), value: playbackPosition)
                    .shadow(color: .white, radius: 3)
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(EditorTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == tab ? 
                                      tab.color.opacity(0.3) : 
                                      Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            selectedTab == tab ? tab.color.opacity(0.6) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: selectedTab == tab ? tab.color.opacity(0.3) : .clear, radius: 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Content Area
    
    private var contentArea: some View {
        Group {
            switch selectedTab {
            case .envelope:
                envelopeEditor
            case .pitch:
                pitchEditor
            case .filter:
                filterEditor
            case .playback:
                playbackEditor
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.vertical, 20)
    }
    
    // MARK: - Envelope Editor
    
    private var envelopeEditor: some View {
        VStack(spacing: 24) {
            Text("ADSR Envelope")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)
            
            // Envelope visualization
            EnvelopeVisualizationView(
                attack: sample.editParameters.attack,
                decay: sample.editParameters.decay,
                sustain: sample.editParameters.sustain,
                release: sample.editParameters.release
            )
            .frame(height: 120)
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Attack
                ParameterSlider(
                    title: "Attack",
                    value: Binding(
                        get: { sample.editParameters.attack },
                        set: { sample.editParameters.attack = $0 }
                    ),
                    range: 0.001...2.0,
                    unit: "s",
                    color: .green
                )
                
                // Decay
                ParameterSlider(
                    title: "Decay",
                    value: Binding(
                        get: { sample.editParameters.decay },
                        set: { sample.editParameters.decay = $0 }
                    ),
                    range: 0.001...5.0,
                    unit: "s",
                    color: .green
                )
                
                // Sustain
                ParameterSlider(
                    title: "Sustain",
                    value: Binding(
                        get: { sample.editParameters.sustain },
                        set: { sample.editParameters.sustain = $0 }
                    ),
                    range: 0.0...1.0,
                    unit: "",
                    color: .green
                )
                
                // Release
                ParameterSlider(
                    title: "Release",
                    value: Binding(
                        get: { sample.editParameters.release },
                        set: { sample.editParameters.release = $0 }
                    ),
                    range: 0.001...10.0,
                    unit: "s",
                    color: .green
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Pitch Editor
    
    private var pitchEditor: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Pitch Control")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Auto-tune lock toggle
                Button(action: {
                    sample.editParameters.autoTuneLock.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: sample.editParameters.autoTuneLock ? "lock.fill" : "lock.open")
                        Text("Auto-Tune Lock")
                            .font(.caption)
                    }
                    .foregroundColor(sample.editParameters.autoTuneLock ? .orange : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(sample.editParameters.autoTuneLock ? 
                                  Color.orange.opacity(0.2) : 
                                  Color.white.opacity(0.05))
                            .overlay(
                                Capsule()
                                    .stroke(
                                        sample.editParameters.autoTuneLock ? 
                                        Color.orange.opacity(0.6) : 
                                        Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top)
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Pitch Coarse
                ParameterSlider(
                    title: "Pitch Coarse",
                    value: Binding(
                        get: { sample.editParameters.pitchCoarse },
                        set: { 
                            if sample.editParameters.autoTuneLock {
                                // Round to nearest semitone
                                sample.editParameters.pitchCoarse = round($0)
                            } else {
                                sample.editParameters.pitchCoarse = $0
                            }
                        }
                    ),
                    range: -24.0...24.0,
                    unit: "st",
                    color: .orange,
                    step: sample.editParameters.autoTuneLock ? 1.0 : 0.1
                )
                
                // Pitch Fine (disabled when auto-tune lock is on)
                ParameterSlider(
                    title: "Pitch Fine",
                    value: Binding(
                        get: { sample.editParameters.autoTuneLock ? 0.0 : sample.editParameters.pitchFine },
                        set: { sample.editParameters.pitchFine = $0 }
                    ),
                    range: -100.0...100.0,
                    unit: "¢",
                    color: .orange,
                    isEnabled: !sample.editParameters.autoTuneLock
                )
                
                // Auto-tune reference frequency
                if sample.editParameters.autoTuneLock {
                    ParameterSlider(
                        title: "Reference (A4)",
                        value: Binding(
                            get: { sample.editParameters.autoTuneReference },
                            set: { sample.editParameters.autoTuneReference = $0 }
                        ),
                        range: 415.0...466.0,
                        unit: "Hz",
                        color: .orange
                    )
                }
            }
            .padding(.horizontal)
            
            // Pitch info display
            VStack(spacing: 8) {
                Text("Current Pitch Offset")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                let totalCents = sample.editParameters.pitchCoarse * 100 + 
                                (sample.editParameters.autoTuneLock ? 0 : sample.editParameters.pitchFine)
                
                Text(String(format: "%.0f cents", totalCents))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                if sample.editParameters.autoTuneLock {
                    Text("🔒 Locked to semitones")
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.8))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
            )
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Filter Editor
    
    private var filterEditor: some View {
        VStack(spacing: 24) {
            Text("Filter")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)
            
            // Filter type selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Filter Type")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(FilterType.allCases, id: \.self) { filterType in
                        Button(action: {
                            sample.editParameters.filterType = filterType
                        }) {
                            Text(filterType.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(sample.editParameters.filterType == filterType ? .white : .gray)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(sample.editParameters.filterType == filterType ? 
                                              Color.purple.opacity(0.3) : 
                                              Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    sample.editParameters.filterType == filterType ? 
                                                    Color.purple.opacity(0.6) : 
                                                    Color.white.opacity(0.1),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Cutoff frequency
                ParameterSlider(
                    title: "Cutoff",
                    value: Binding(
                        get: { sample.editParameters.filterCutoff },
                        set: { sample.editParameters.filterCutoff = $0 }
                    ),
                    range: 0.0...1.0,
                    unit: "",
                    color: .purple
                )
                
                // Resonance
                ParameterSlider(
                    title: "Resonance",
                    value: Binding(
                        get: { sample.editParameters.filterResonance },
                        set: { sample.editParameters.filterResonance = $0 }
                    ),
                    range: 0.0...1.0,
                    unit: "",
                    color: .purple
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Enhanced Playback Editor
    
    private var playbackEditor: some View {
        VStack(spacing: 24) {
            Text("Playback & Sample Regions")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)
            
            // Sample region info display
            SampleRegionInfoView(
                sample: sample,
                startPoint: sample.editParameters.startPoint,
                endPoint: sample.editParameters.endPoint,
                loopStart: sample.editParameters.loopStart,
                loopEnd: sample.editParameters.loopEnd,
                loopEnabled: sample.editParameters.loopEnabled
            )
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Volume
                ParameterSlider(
                    title: "Volume",
                    value: Binding(
                        get: { sample.editParameters.volume },
                        set: { sample.editParameters.volume = $0 }
                    ),
                    range: 0.0...1.0,
                    unit: "",
                    color: .cyan,
                    displayAsPercentage: true
                )
                
                // Pan
                ParameterSlider(
                    title: "Pan",
                    value: Binding(
                        get: { sample.editParameters.pan },
                        set: { sample.editParameters.pan = $0 }
                    ),
                    range: -1.0...1.0,
                    unit: "",
                    color: .cyan,
                    centerValue: 0.0,
                    displayAsPercentage: true
                )
            }
            .padding(.horizontal)
            
            // Sample trimming section
            VStack(spacing: 16) {
                HStack {
                    Text("Sample Trimming")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Reset") {
                        sample.editParameters.startPoint = 0.0
                        sample.editParameters.endPoint = 1.0
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                // Start Point with time display
                EnhancedParameterSlider(
                    title: "Start Point",
                    value: Binding(
                        get: { sample.editParameters.startPoint },
                        set: { sample.editParameters.startPoint = min($0, sample.editParameters.endPoint - 0.01) }
                    ),
                    range: 0.0...1.0,
                    color: .green,
                    sampleDuration: sample.duration,
                    displayType: .time
                )
                
                // End Point with time display
                EnhancedParameterSlider(
                    title: "End Point",
                    value: Binding(
                        get: { sample.editParameters.endPoint },
                        set: { sample.editParameters.endPoint = max($0, sample.editParameters.startPoint + 0.01) }
                    ),
                    range: 0.0...1.0,
                    color: .red,
                    sampleDuration: sample.duration,
                    displayType: .time
                )
            }
            .padding(.horizontal)
            
            // Enhanced loop settings
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Toggle("Loop Enabled", isOn: Binding(
                                get: { sample.editParameters.loopEnabled },
                                set: { sample.editParameters.loopEnabled = $0 }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                            
                            if sample.editParameters.loopEnabled {
                                Image(systemName: "repeat")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                        
                        if sample.editParameters.loopEnabled {
                            Text("Creates seamless loop between points")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                }
                
                if sample.editParameters.loopEnabled {
                    VStack(spacing: 12) {
                        EnhancedParameterSlider(
                            title: "Loop Start",
                            value: Binding(
                                get: { sample.editParameters.loopStart },
                                set: { sample.editParameters.loopStart = min($0, sample.editParameters.loopEnd - 0.01) }
                            ),
                            range: 0.0...1.0,
                            color: .orange,
                            sampleDuration: sample.duration,
                            displayType: .time
                        )
                        
                        EnhancedParameterSlider(
                            title: "Loop End",
                            value: Binding(
                                get: { sample.editParameters.loopEnd },
                                set: { sample.editParameters.loopEnd = max($0, sample.editParameters.loopStart + 0.01) }
                            ),
                            range: 0.0...1.0,
                            color: .orange,
                            sampleDuration: sample.duration,
                            displayType: .time
                        )
                        
                        // Loop info
                        HStack {
                            let loopDuration = (sample.editParameters.loopEnd - sample.editParameters.loopStart) * Float(sample.duration)
                            Text("Loop Duration: \(String(format: "%.3f", loopDuration))s")
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.8))
                            
                            Spacer()
                        }
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Toggle("Reverse", isOn: Binding(
                                get: { sample.editParameters.reverse },
                                set: { sample.editParameters.reverse = $0 }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: .red))
                            
                            if sample.editParameters.reverse {
                                Image(systemName: "arrow.left.circle")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        
                        if sample.editParameters.reverse {
                            Text("Plays sample backwards")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Transport Controls
    
    private var transportControls: some View {
        HStack(spacing: 20) {
            // Reset button
            Button(action: resetToDefaults) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Play/Stop button
            Button(action: togglePlayback) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    isPlaying ? Color.red.opacity(0.9) : Color.green.opacity(0.9),
                                    isPlaying ? Color.red.opacity(0.7) : Color.green.opacity(0.7)
                                ]),
                                center: .center,
                                startRadius: 5,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .shadow(color: isPlaying ? .red.opacity(0.4) : .green.opacity(0.4), radius: 15)
            
            Spacer()
            
            // Export button
            Button(action: exportSample) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.cyan)
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helper Functions
    
    private func loadWaveformData() {
        // Load waveform data for visualization
        // This would typically involve reading the audio file and extracting amplitude data
        // For now, we'll create some dummy data
        waveformData = (0..<200).map { _ in Float.random(in: -1...1) }
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            // Start playing the sample with current parameters
            audioEngine.playSampleWithParameters(sample)
            startPlaybackPositionUpdates()
        } else {
            // Stop playback
            audioEngine.stopSample()
        }
    }
    
    private func startPlaybackPositionUpdates() {
        // Update playback position indicator
        // This would be connected to the audio engine's playback position
    }
    
    private func resetToDefaults() {
        sample.editParameters = SampleEditParameters()
    }
    
    private func exportSample() {
        // Export the edited sample
        // This would render the sample with all applied effects
    }
}

// MARK: - Supporting Views

struct WaveformShape: Shape {
    let data: [Float]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !data.isEmpty else { return path }
        
        let stepWidth = rect.width / CGFloat(data.count)
        let midY = rect.height / 2
        
        path.move(to: CGPoint(x: 0, y: midY + CGFloat(data[0]) * midY))
        
        for (index, value) in data.enumerated() {
            let x = CGFloat(index) * stepWidth
            let y = midY + CGFloat(value) * midY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct EnvelopeVisualizationView: View {
    let attack: Float
    let decay: Float
    let sustain: Float
    let release: Float
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let totalTime = attack + decay + 0.5 + release // 0.5s hold time
            
            let attackWidth = CGFloat(attack / totalTime) * width
            let decayWidth = CGFloat(decay / totalTime) * width
            let holdWidth = CGFloat(0.5 / totalTime) * width
            let releaseWidth = CGFloat(release / totalTime) * width
            
            Path { path in
                // Start at zero
                path.move(to: CGPoint(x: 0, y: height))
                
                // Attack phase
                path.addLine(to: CGPoint(x: attackWidth, y: 0))
                
                // Decay phase
                path.addLine(to: CGPoint(x: attackWidth + decayWidth, y: height * CGFloat(1 - sustain)))
                
                // Hold phase (sustain)
                path.addLine(to: CGPoint(x: attackWidth + decayWidth + holdWidth, y: height * CGFloat(1 - sustain)))
                
                // Release phase
                path.addLine(to: CGPoint(x: attackWidth + decayWidth + holdWidth + releaseWidth, y: height))
            }
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.cyan]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
            
            // Phase labels
            VStack {
                HStack {
                    Text("A")
                        .frame(width: attackWidth)
                    Text("D")
                        .frame(width: decayWidth)
                    Text("S")
                        .frame(width: holdWidth)
                    Text("R")
                        .frame(width: releaseWidth)
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct ParameterSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let unit: String
    let color: Color
    var centerValue: Float? = nil
    var step: Float? = nil
    var isEnabled: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isEnabled ? .white : .gray)
                
                Spacer()
                
                Text(String(format: "%.2f%@", value, unit))
                    .font(.caption)
                    .foregroundColor(isEnabled ? color : .gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
            }
            
            ZStack {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)
                
                // Center indicator (if centerValue is provided)
                if let centerValue = centerValue {
                    let centerPosition = (centerValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2, height: 12)
                        .position(x: CGFloat(centerPosition) * (UIScreen.main.bounds.width - 40), y: 6)
                }
                
                // Fill
                GeometryReader { geometry in
                    let fillWidth = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        color.opacity(0.8),
                                        color
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: fillWidth, height: 8)
                        
                        Spacer()
                    }
                }
            }
            .opacity(isEnabled ? 1.0 : 0.5)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard isEnabled else { return }
                        
                        let width = UIScreen.main.bounds.width - 40
                        let newValue = Float(gesture.location.x / width) * (range.upperBound - range.lowerBound) + range.lowerBound
                        let clampedValue = max(range.lowerBound, min(range.upperBound, newValue))
                        
                        if let step = step {
                            value = round(clampedValue / step) * step
                        } else {
                            value = clampedValue
                        }
                    }
            )
        }
    }
}

// MARK: - Interactive Waveform Overlay

struct InteractiveWaveformOverlay: View {
    @Binding var startPoint: Float
    @Binding var endPoint: Float
    @Binding var loopStart: Float
    @Binding var loopEnd: Float
    let loopEnabled: Bool
    let sampleDuration: TimeInterval
    
    @State private var isDraggingStart = false
    @State private var isDraggingEnd = false
    @State private var isDraggingLoopStart = false
    @State private var isDraggingLoopEnd = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sample region overlay
                sampleRegionOverlay(geometry: geometry)
                
                // Loop region overlay (if enabled)
                if loopEnabled {
                    loopRegionOverlay(geometry: geometry)
                }
                
                // Region markers
                regionMarkers(geometry: geometry)
                
                // Info cards
                infoCards(geometry: geometry)
            }
        }
    }
    
    private func sampleRegionOverlay(geometry: GeometryProxy) -> some View {
        let startX = CGFloat(startPoint) * geometry.size.width
        let endX = CGFloat(endPoint) * geometry.size.width
        let regionWidth = endX - startX
        
        return ZStack {
            // Dimmed areas outside sample region
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: startX)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: regionWidth)
                
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: geometry.size.width - endX)
            }
            
            // Active sample region highlight
            Rectangle()
                .fill(Color.green.opacity(0.1))
                .frame(width: regionWidth)
                .position(x: startX + regionWidth/2, y: geometry.size.height/2)
                .overlay(
                    Rectangle()
                        .stroke(Color.green.opacity(0.6), lineWidth: 2)
                        .frame(width: regionWidth)
                        .position(x: startX + regionWidth/2, y: geometry.size.height/2)
                )
        }
    }
    
    private func loopRegionOverlay(geometry: GeometryProxy) -> some View {
        let loopStartX = CGFloat(loopStart) * geometry.size.width
        let loopEndX = CGFloat(loopEnd) * geometry.size.width
        let loopWidth = loopEndX - loopStartX
        
        return Rectangle()
            .fill(Color.orange.opacity(0.15))
            .frame(width: loopWidth, height: geometry.size.height * 0.6)
            .position(x: loopStartX + loopWidth/2, y: geometry.size.height/2)
            .overlay(
                Rectangle()
                    .stroke(Color.orange.opacity(0.8), lineWidth: 2, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .frame(width: loopWidth, height: geometry.size.height * 0.6)
                    .position(x: loopStartX + loopWidth/2, y: geometry.size.height/2)
            )
    }
    
    private func regionMarkers(geometry: GeometryProxy) -> some View {
        ZStack {
            // Start point marker
            startPointMarker(geometry: geometry)
            
            // End point marker
            endPointMarker(geometry: geometry)
            
            // Loop markers (if enabled)
            if loopEnabled {
                loopStartMarker(geometry: geometry)
                loopEndMarker(geometry: geometry)
            }
        }
    }
    
    private func startPointMarker(geometry: GeometryProxy) -> some View {
        let x = CGFloat(startPoint) * geometry.size.width
        
        return VStack(spacing: 0) {
            Image(systemName: "triangle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .rotationEffect(.degrees(180))
            
            Rectangle()
                .fill(Color.green)
                .frame(width: 3, height: geometry.size.height)
        }
        .position(x: x, y: geometry.size.height/2)
        .scaleEffect(isDraggingStart ? 1.2 : 1.0)
        .animation(.spring(response: 0.2), value: isDraggingStart)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDraggingStart = true
                    let newValue = Float(value.location.x / geometry.size.width)
                    startPoint = max(0, min(endPoint - 0.01, newValue))
                }
                .onEnded { _ in
                    isDraggingStart = false
                }
        )
    }
    
    private func endPointMarker(geometry: GeometryProxy) -> some View {
        let x = CGFloat(endPoint) * geometry.size.width
        
        return VStack(spacing: 0) {
            Image(systemName: "triangle.fill")
                .foregroundColor(.red)
                .font(.caption)
                .rotationEffect(.degrees(180))
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 3, height: geometry.size.height)
        }
        .position(x: x, y: geometry.size.height/2)
        .scaleEffect(isDraggingEnd ? 1.2 : 1.0)
        .animation(.spring(response: 0.2), value: isDraggingEnd)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDraggingEnd = true
                    let newValue = Float(value.location.x / geometry.size.width)
                    endPoint = max(startPoint + 0.01, min(1.0, newValue))
                }
                .onEnded { _ in
                    isDraggingEnd = false
                }
        )
    }
    
    private func loopStartMarker(geometry: GeometryProxy) -> some View {
        let x = CGFloat(loopStart) * geometry.size.width
        
        return VStack(spacing: 0) {
            Image(systemName: "repeat")
                .foregroundColor(.orange)
                .font(.caption2)
            
            Rectangle()
                .fill(Color.orange)
                .frame(width: 2, height: geometry.size.height * 0.8)
        }
        .position(x: x, y: geometry.size.height/2)
        .scaleEffect(isDraggingLoopStart ? 1.2 : 1.0)
        .animation(.spring(response: 0.2), value: isDraggingLoopStart)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDraggingLoopStart = true
                    let newValue = Float(value.location.x / geometry.size.width)
                    loopStart = max(startPoint, min(loopEnd - 0.01, newValue))
                }
                .onEnded { _ in
                    isDraggingLoopStart = false
                }
        )
    }
    
    private func loopEndMarker(geometry: GeometryProxy) -> some View {
        let x = CGFloat(loopEnd) * geometry.size.width
        
        return VStack(spacing: 0) {
            Image(systemName: "repeat")
                .foregroundColor(.orange)
                .font(.caption2)
            
            Rectangle()
                .fill(Color.orange)
                .frame(width: 2, height: geometry.size.height * 0.8)
        }
        .position(x: x, y: geometry.size.height/2)
        .scaleEffect(isDraggingLoopEnd ? 1.2 : 1.0)
        .animation(.spring(response: 0.2), value: isDraggingLoopEnd)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDraggingLoopEnd = true
                    let newValue = Float(value.location.x / geometry.size.width)
                    loopEnd = max(loopStart + 0.01, min(endPoint, newValue))
                }
                .onEnded { _ in
                    isDraggingLoopEnd = false
                }
        )
    }
    
    private func infoCards(geometry: GeometryProxy) -> some View {
        ZStack {
            // Sample region info
            sampleRegionInfo(geometry: geometry)
            
            // Loop region info (if enabled and visible)
            if loopEnabled && (isDraggingLoopStart || isDraggingLoopEnd) {
                loopRegionInfo(geometry: geometry)
            }
        }
    }
    
    private func sampleRegionInfo(geometry: GeometryProxy) -> some View {
        let startX = CGFloat(startPoint) * geometry.size.width
        let endX = CGFloat(endPoint) * geometry.size.width
        let centerX = (startX + endX) / 2
        
        let startTime = Double(startPoint) * sampleDuration
        let endTime = Double(endPoint) * sampleDuration
        let duration = endTime - startTime
        
        return VStack(spacing: 4) {
            Text("Sample Region")
                .font(.caption2)
                .foregroundColor(.white)
            
            Text("\(String(format: "%.3f", startTime))s - \(String(format: "%.3f", endTime))s")
                .font(.caption)
                .foregroundColor(.green)
            
            Text("Duration: \(String(format: "%.3f", duration))s")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.6), lineWidth: 1)
                )
        )
        .position(x: centerX, y: -20)
        .opacity(isDraggingStart || isDraggingEnd ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.2), value: isDraggingStart || isDraggingEnd)
    }
    
    private func loopRegionInfo(geometry: GeometryProxy) -> some View {
        let loopStartX = CGFloat(loopStart) * geometry.size.width
        let loopEndX = CGFloat(loopEnd) * geometry.size.width
        let centerX = (loopStartX + loopEndX) / 2
        
        let loopStartTime = Double(loopStart) * sampleDuration
        let loopEndTime = Double(loopEnd) * sampleDuration
        let loopDuration = loopEndTime - loopStartTime
        
        return VStack(spacing: 4) {
            Text("Loop Region")
                .font(.caption2)
                .foregroundColor(.white)
            
            Text("\(String(format: "%.3f", loopStartTime))s - \(String(format: "%.3f", loopEndTime))s")
                .font(.caption)
                .foregroundColor(.orange)
            
            Text("Duration: \(String(format: "%.3f", loopDuration))s")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.6), lineWidth: 1)
                )
        )
        .position(x: centerX, y: geometry.size.height + 40)
        .animation(.easeInOut(duration: 0.2), value: isDraggingLoopStart || isDraggingLoopEnd)
    }
}

// MARK: - Enhanced Parameter Slider

struct EnhancedParameterSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let color: Color
    let sampleDuration: TimeInterval?
    let displayType: DisplayType
    
    enum DisplayType {
        case percentage
        case time
        case value
    }
    
    @State private var isDragging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formattedValue)
                    .font(.caption)
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
            }
            
            ZStack {
                // Track background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 12)
                
                // Progress fill
                GeometryReader { geometry in
                    let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                    let fillWidth = progress * geometry.size.width
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        color.opacity(0.6),
                                        color
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: fillWidth, height: 12)
                        
                        Spacer()
                    }
                }
                
                // Thumb
                GeometryReader { geometry in
                    let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                    let thumbX = progress * geometry.size.width
                    
                    Circle()
                        .fill(color)
                        .frame(width: isDragging ? 20 : 16, height: isDragging ? 20 : 16)
                        .shadow(color: color.opacity(0.5), radius: isDragging ? 8 : 4)
                        .position(x: thumbX, y: geometry.size.height / 2)
                        .animation(.spring(response: 0.3), value: isDragging)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let width = UIScreen.main.bounds.width - 40
                        let newValue = Float(gesture.location.x / width) * (range.upperBound - range.lowerBound) + range.lowerBound
                        value = max(range.lowerBound, min(range.upperBound, newValue))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }
    
    private var formattedValue: String {
        switch displayType {
        case .percentage:
            return String(format: "%.1f%%", value * 100)
        case .time:
            if let duration = sampleDuration {
                let timeValue = Double(value) * duration
                return String(format: "%.3fs", timeValue)
            } else {
                return String(format: "%.3f", value)
            }
        case .value:
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Audio Engine Extension

extension AudioEngine {
    func playSampleWithParameters(_ sample: SimpleSample) {
        // This would implement playing the sample with all the edit parameters applied
        print("🎵 Playing sample: \(sample.name) with parameters")
    }
    
    func stopSample() {
        // This would stop the currently playing sample
        print("⏹️ Stopping sample playback")
    }
}

#Preview {
    @State var samplePreview = SimpleSample(
        url: URL(fileURLWithPath: "/path/to/sample.wav"),
        category: .bundled
    )
    
    return SampleEditorView(sample: $samplePreview)
        .environmentObject(AudioEngine())
}
