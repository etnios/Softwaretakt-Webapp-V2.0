// SwiftUI Web Preview System
// This allows you to see your SwiftUI views in a web browser

import SwiftUI

// Web-compatible version of your ContentView for preview
struct WebPreviewContentView: View {
    @State private var selectedTrack: Int = 0
    @State private var isPlaying: Bool = false
    @State private var viewMode: ViewMode = .overview
    @State private var pulseAnimation: Bool = false
    
    enum ViewMode {
        case overview, step, pads, fmTest, projects, samples
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient (web-compatible)
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black,
                                Color(red: 0.05, green: 0.05, blue: 0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top navigation
                    webNavigationBar
                    
                    // Main content
                    webMainContent(geometry: geometry)
                        .padding(20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private var webNavigationBar: some View {
        VStack(spacing: 12) {
            HStack {
                // App title
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Text("SOFTWARETAKT")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Status indicators
                HStack(spacing: 16) {
                    webStatusIndicator(isActive: true, icon: "♪", label: "AUDIO")
                    webStatusIndicator(isActive: false, icon: "📡", label: "MIDI")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Mode selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    webModeCard(.overview, icon: "⊞", title: "OVERVIEW", color: .cyan)
                    webModeCard(.step, icon: "~", title: "STEP EDIT", color: .blue)
                    webModeCard(.pads, icon: "▦", title: "PADS", color: .purple)
                    webModeCard(.fmTest, icon: "〰", title: "FM SYNTH", color: .orange)
                    webModeCard(.projects, icon: "📁", title: "PROJECTS", color: .green)
                    webModeCard(.samples, icon: "🎵", title: "SAMPLES", color: .pink)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.black.opacity(0.8))
    }
    
    private func webStatusIndicator(isActive: Bool, icon: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? .green : .gray)
                
                Circle()
                    .fill(isActive ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
            }
            
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(isActive ? .green.opacity(0.8) : .gray.opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func webModeCard(_ mode: ViewMode, icon: String, title: String, color: Color) -> some View {
        Button(action: {
            viewMode = mode
        }) {
            VStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 18))
                    .foregroundColor(viewMode == mode ? color : .gray)
                
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(viewMode == mode ? .white : .gray)
            }
            .frame(width: 80, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewMode == mode ? color.opacity(0.3) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewMode == mode ? color.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(viewMode == mode ? 1.05 : 1.0)
        }
    }
    
    private func webMainContent(geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.white.opacity(0.1))
            .overlay(
                VStack(spacing: 20) {
                    switch viewMode {
                    case .overview:
                        webOverviewContent
                    case .step:
                        webStepContent
                    case .pads:
                        webPadsContent(geometry: geometry)
                    case .fmTest:
                        webFMContent
                    case .projects:
                        webProjectsContent
                    case .samples:
                        webSamplesContent
                    }
                }
                .padding(20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var webOverviewContent: some View {
        VStack(spacing: 16) {
            Text("Pattern Overview")
                .font(.title2)
                .foregroundColor(.white)
            
            // Pattern visualization
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { track in
                    HStack(spacing: 4) {
                        Text("T\(track + 1)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        
                        ForEach(0..<16, id: \.self) { step in
                            Rectangle()
                                .fill(step % 4 == 0 ? Color.cyan : Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
    }
    
    private var webStepContent: some View {
        VStack(spacing: 16) {
            Text("Step Editor")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("Track \(selectedTrack + 1) - Kick Pattern")
                .font(.headline)
                .foregroundColor(.cyan)
            
            // Step grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(0..<16, id: \.self) { step in
                    Rectangle()
                        .fill(step % 4 == 0 ? Color.green : Color.gray.opacity(0.3))
                        .frame(height: 40)
                        .cornerRadius(8)
                        .overlay(
                            Text("\(step + 1)")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }
    
    private func webPadsContent(geometry: GeometryProxy) -> some View {
        HStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Pad Grid")
                    .font(.title2)
                    .foregroundColor(.white)
                
                // 8x8 Pad grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 4) {
                    ForEach(0..<64, id: \.self) { pad in
                        Rectangle()
                            .fill(Color.orange.opacity(0.6))
                            .frame(height: 40)
                            .cornerRadius(8)
                            .overlay(
                                Text("\(pad + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                // Transport
                Button(action: {
                    isPlaying.toggle()
                }) {
                    Circle()
                        .fill(isPlaying ? Color.red : Color.green)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(isPlaying ? "⏹" : "▶")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
            }
            
            VStack(spacing: 16) {
                Text("Track \(selectedTrack + 1)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ForEach(0..<8, id: \.self) { track in
                        Button("Track \(track + 1)") {
                            selectedTrack = track
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTrack == track ? Color.cyan : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                Button("Sample Browser") {
                    // Open sample browser
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Button("Edit Sample") {
                    // Open sample editor
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var webFMContent: some View {
        VStack(spacing: 16) {
            Text("FM Synthesizer")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("🎛️ Professional FM synthesis engine")
                .font(.headline)
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Algorithm")
                    Spacer()
                    Text("1")
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Text("Operator 1")
                    Spacer()
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 100, height: 8)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("Operator 2")
                    Spacer()
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 100, height: 8)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("Filter Cutoff")
                    Spacer()
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 100, height: 8)
                        .cornerRadius(4)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
    }
    
    private var webProjectsContent: some View {
        VStack(spacing: 16) {
            Text("Project Browser")
                .font(.title2)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(["My Track 1", "Drum Loop", "Bass Line", "Melody"], id: \.self) { project in
                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(height: 60)
                            .cornerRadius(8)
                            .overlay(
                                Text("📁")
                                    .font(.title)
                            )
                        
                        Text(project)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private var webSamplesContent: some View {
        VStack(spacing: 16) {
            Text("Sample Browser")
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(["Kick_01.wav", "Snare_02.wav", "HiHat_03.wav", "Bass_01.wav"], id: \.self) { sample in
                    HStack {
                        Text("🎵")
                        Text(sample)
                            .foregroundColor(.white)
                        Spacer()
                        Button("▶") {
                            // Preview
                        }
                        .foregroundColor(.orange)
                        Button("📝") {
                            // Edit
                        }
                        .foregroundColor(.purple)
                        Button("↓") {
                            // Load
                        }
                        .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    WebPreviewContentView()
}
