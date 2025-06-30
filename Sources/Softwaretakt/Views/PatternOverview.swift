import SwiftUI

// 🎛️ ELEKTRON-STYLE PATTERN OVERVIEW - See All 16 Tracks!

struct PatternOverview: View {
    @ObservedObject var song: Song
    @State private var selectedTrack: Int = 0
    @State private var selectedPattern: Int = 0
    @State private var isPlaying: Bool = false
    @State private var currentStep: Int = 0
    @State private var showPatternChain: Bool = false
    
    let trackNames = [
        "BD", "SD", "CH", "OH", "CLP", "CRS", "RIM", "COW",
        "SY1", "SY2", "SY3", "SY4", "FM1", "FM2", "FM3", "FM4"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Transport and pattern info
            transportHeader
            
            if showPatternChain {
                patternChainView
            } else {
                // Track overview grid
                trackOverviewGrid
                
                // Selected track step editor
                if !song.patterns.isEmpty && selectedPattern < song.patterns.count {
                    ElektronStepEditor(
                        pattern: song.patterns[selectedPattern],
                        trackIndex: selectedTrack
                    )
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .background(Color.black)
        .onAppear {
            setupDefaultPattern()
        }
    }
    
    // MARK: - Transport Header
    
    private var transportHeader: some View {
        HStack {
            // Play controls
            HStack(spacing: 16) {
                Button(action: { isPlaying.toggle() }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(isPlaying ? .red : .green)
                }
                
                Button("STOP") {
                    isPlaying = false
                    currentStep = 0
                }
                .foregroundColor(.red)
                
                Button("REC") {
                    // Record functionality
                }
                .foregroundColor(.orange)
            }
            
            Spacer()
            
            // Pattern info
            VStack(alignment: .center, spacing: 2) {
                Text("PATTERN \(selectedPattern + 1)")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                if !song.patterns.isEmpty && selectedPattern < song.patterns.count {
                    Text(song.patterns[selectedPattern].name)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Tempo and controls
            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("BPM")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(song.tempo))")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                Button(showPatternChain ? "TRACKS" : "CHAIN") {
                    showPatternChain.toggle()
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Track Overview Grid
    
    private var trackOverviewGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 2), spacing: 4) {
                ForEach(0..<16, id: \.self) { trackIndex in
                    trackRow(trackIndex)
                }
            }
            .padding()
        }
    }
    
    private func trackRow(_ trackIndex: Int) -> some View {
        VStack(spacing: 4) {
            // Track header
            HStack {
                // Track name and selection
                Button(action: { selectedTrack = trackIndex }) {
                    HStack {
                        Text(trackNames[trackIndex])
                            .font(.caption.bold())
                            .foregroundColor(selectedTrack == trackIndex ? .black : .white)
                            .frame(width: 30)
                            .background(selectedTrack == trackIndex ? Color.blue : Color.clear)
                            .cornerRadius(2)
                        
                        // Track type indicator
                        trackTypeIndicator(trackIndex)
                    }
                }
                
                Spacer()
                
                // Track controls
                HStack(spacing: 4) {
                    // Mute
                    Button("M") {
                        // Mute track
                    }
                    .font(.caption2)
                    .foregroundColor(.red)
                    .frame(width: 20, height: 20)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(2)
                    
                    // Solo
                    Button("S") {
                        // Solo track
                    }
                    .font(.caption2)
                    .foregroundColor(.yellow)
                    .frame(width: 20, height: 20)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(2)
                }
            }
            
            // Mini step display (16 steps visible)
            if !song.patterns.isEmpty && selectedPattern < song.patterns.count {
                miniStepDisplay(trackIndex)
            }
        }
        .padding(8)
        .background(selectedTrack == trackIndex ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onTapGesture {
            selectedTrack = trackIndex
        }
    }
    
    private func trackTypeIndicator(_ trackIndex: Int) -> some View {
        let engineType = getTrackEngineType(trackIndex)
        
        return Text(engineType)
            .font(.system(size: 8))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(engineTypeColor(engineType))
            .cornerRadius(2)
    }
    
    private func getTrackEngineType(_ trackIndex: Int) -> String {
        // This would come from your track model
        if trackIndex < 8 {
            return "SMP" // Sample tracks
        } else if trackIndex < 12 {
            return "SYN" // Synthesis tracks
        } else {
            return "FM"  // FM tracks
        }
    }
    
    private func engineTypeColor(_ engineType: String) -> Color {
        switch engineType {
        case "SMP": return .cyan
        case "SYN": return .green
        case "FM": return Color(red: 1.0, green: 0.0, blue: 1.0) // Magenta replacement
        default: return .gray
        }
    }
    
    private func miniStepDisplay(_ trackIndex: Int) -> some View {
        let pattern = song.patterns[selectedPattern]
        let visibleSteps = Array(0..<min(16, pattern.patternLength))
        
        return HStack(spacing: 1) {
            ForEach(visibleSteps, id: \.self) { stepIndex in
                let step = pattern.steps[stepIndex]
                
                Rectangle()
                    .fill(stepColor(step, stepIndex))
                    .frame(width: 12, height: 8)
                    .overlay(
                        // Parameter lock indicators
                        VStack(spacing: 0) {
                            if !step.parameterLocks.isEmpty {
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(height: 1)
                            }
                            if step.condition != .none {
                                Rectangle()
                                    .fill(Color.yellow)
                                    .frame(height: 1)
                            }
                            if step.retrig != nil {
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(height: 1)
                            }
                        }
                    )
                    .overlay(
                        // Current step indicator
                        Rectangle()
                            .stroke(currentStep == stepIndex && isPlaying ? Color.white : Color.clear, lineWidth: 1)
                    )
            }
            
            // Pad remaining space for shorter patterns
            if pattern.patternLength < 16 {
                ForEach(pattern.patternLength..<16, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 8)
                }
            }
        }
    }
    
    private func stepColor(_ step: Step, _ stepIndex: Int) -> Color {
        if step.isActive {
            let intensity = step.velocity
            return Color.blue.opacity(Double(intensity))
        } else if stepIndex % 4 == 0 {
            return Color.gray.opacity(0.3) // Beat markers
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    // MARK: - Pattern Chain View
    
    private var patternChainView: some View {
        VStack(spacing: 16) {
            Text("PATTERN CHAIN")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(song.chain.enumerated()), id: \.offset) { index, link in
                        patternChainLink(link, index: index)
                    }
                    
                    // Add pattern button
                    Button("+") {
                        if !song.patterns.isEmpty {
                            song.addToChain(patternId: song.patterns[0].id)
                        }
                    }
                    .frame(width: 60, height: 40)
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(4)
                    .foregroundColor(.white)
                }
                .padding(.horizontal)
            }
            
            // Chain controls
            HStack(spacing: 16) {
                Button("CLEAR CHAIN") {
                    song.chain.removeAll()
                }
                .foregroundColor(.red)
                
                Button("LOOP CHAIN") {
                    // Toggle chain loop
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("CHAIN LENGTH: \(song.chain.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    private func patternChainLink(_ link: Song.PatternChainLink, index: Int) -> some View {
        VStack(spacing: 4) {
            // Pattern number
            if let pattern = song.patterns.first(where: { $0.id == link.patternId }) {
                Text("P\(song.patterns.firstIndex(of: pattern) ?? 0 + 1)")
                    .font(.caption.bold())
                    .foregroundColor(song.currentChainIndex == index ? .black : .white)
            }
            
            // Repeat count
            if link.repeatCount > 1 {
                Text("×\(link.repeatCount)")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            
            // Mute indicator
            if link.mute {
                Text("M")
                    .font(.system(size: 8))
                    .foregroundColor(.red)
            }
        }
        .frame(width: 60, height: 40)
        .background(song.currentChainIndex == index ? Color.blue : Color.gray.opacity(0.3))
        .cornerRadius(4)
        .onTapGesture {
            song.currentChainIndex = index
        }
    }
    
    // MARK: - Helper Functions
    
    private func setupDefaultPattern() {
        if song.patterns.isEmpty {
            let pattern = Pattern(length: 16, name: "Pattern 1")
            song.addPattern(pattern)
        }
    }
}

// MARK: - Preview

struct PatternOverview_Previews: PreviewProvider {
    static var previews: some View {
        let song = Song()
        let pattern1 = Pattern(length: 16, name: "Kick Pattern")
        pattern1.toggleStep(0)
        pattern1.toggleStep(4)
        pattern1.toggleStep(8)
        pattern1.toggleStep(12)
        
        let pattern2 = Pattern(length: 16, name: "Snare Pattern")
        pattern2.toggleStep(4)
        pattern2.toggleStep(12)
        
        song.addPattern(pattern1)
        song.addPattern(pattern2)
        song.addToChain(patternId: pattern1.id)
        song.addToChain(patternId: pattern2.id)
        
        return PatternOverview(song: song)
            .preferredColorScheme(.dark)
    }
}
