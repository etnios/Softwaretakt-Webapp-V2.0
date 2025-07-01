import SwiftUI
#if os(iOS)
import UIKit
#endif

@available(macOS 13.3, iOS 15.0, *)
struct ContentView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var midiManager: MIDIManager
    @StateObject private var projectManager: ProjectManager
    @StateObject private var song = Song()
    @State private var selectedTrack: Int = 0
    @State private var isPlaying: Bool = false
    @State private var selectedBank: Int = 0 // 0 = tracks 1-8, 1 = tracks 9-16
    @State private var viewMode: ViewMode = .overview
    @State private var activeSheet: ActiveSheet?
    @State private var pulseAnimation: Bool = false
    @State private var glowIntensity: Double = 0.5
    @State private var showSplash: Bool = true
    
    enum ActiveSheet: Identifiable {
        case sampleBrowser
        case synthControls
        case projectBrowser
        case sampleEditor(SimpleSample)
        
        var id: Int {
            switch self {
            case .sampleBrowser: return 0
            case .synthControls: return 1
            case .projectBrowser: return 2
            case .sampleEditor: return 3
            }
        }
    }
    
    enum ViewMode {
        case overview  // PatternOverview - see all 16 tracks
        case step      // ElektronStepEditor - focused step editing
        case pads      // Original pad grid view
        case fmTest    // 🔥 FM synthesis test console!
        case projects  // 🗂️ Project management
        case samples   // 📂 Simple sample browser
        case web       // 🌐 Web version
    }
    
    init() {
        // Initialize project manager with audio engine reference
        let audioEngine = AudioEngine()
        self._projectManager = StateObject(wrappedValue: ProjectManager(audioEngine: audioEngine))
    }
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                mainAppView
                    .transition(.opacity)
            }
        }
        .onAppear {
            setupDefaultSong()
            startBackgroundAnimations()
            
            // Hide splash after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showSplash = false
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .sampleBrowser:
                SimpleSampleBrowserView()
                    .environmentObject(audioEngine)
                    .presentationBackground(.ultraThinMaterial)
            case .synthControls:
                SynthControlView(audioEngine: audioEngine)
                    .environmentObject(audioEngine)
                    .presentationBackground(.ultraThinMaterial)
            case .projectBrowser:
                ProjectBrowserView(projectManager: projectManager)
                    .environmentObject(projectManager)
                    .presentationBackground(.ultraThinMaterial)
            case .sampleEditor(let sample):
                SampleEditorView(sample: .constant(sample))
                    .environmentObject(audioEngine)
                    .presentationBackground(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - Main App View
    
    private var mainAppView: some View {
        GeometryReader { geometry in
            ZStack {
                // Enhanced background with animated gradient
                AnimatedBackground()
                
                VStack(spacing: 0) {
                    // Sleek top navigation
                    sleekNavigationBar
                    
                    // Main content with enhanced glassmorphism
                    mainContentView(geometry: geometry)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Splash Screen
    
    struct SplashView: View {
        @State private var logoScale: CGFloat = 0.3
        @State private var logoOpacity: Double = 0
        @State private var glowRadius: CGFloat = 0
        @State private var textOpacity: Double = 0
        @State private var circleRotation: Double = 0
        @State private var waveAnimation: Bool = false
        
        var body: some View {
            ZStack {
                // Animated background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.05, blue: 0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating particles
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.3),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 1,
                                endRadius: 20
                            )
                        )
                        .frame(width: CGFloat.random(in: 20...40))
                        .position(
                            x: CGFloat.random(in: 50...350),
                            y: CGFloat.random(in: 100...700)
                        )
                        .scaleEffect(waveAnimation ? 1.2 : 0.8)
                        .opacity(waveAnimation ? 0.8 : 0.3)
                        .animation(
                            .easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: waveAnimation
                        )
                }
                
                VStack(spacing: 30) {
                    // Animated logo with rotating circles
                    ZStack {
                        // Outer rotating circle
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan.opacity(0.6),
                                        Color.blue.opacity(0.4),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(circleRotation))
                            .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: circleRotation)
                        
                        // Inner glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan.opacity(0.2),
                                        Color.blue.opacity(0.1),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: glowRadius)
                        
                        // Central waveform icon
                        Image(systemName: "waveform")
                            .font(.system(size: 40, weight: .thin))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white,
                                        Color.cyan,
                                        Color.blue
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 10)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // App title
                    VStack(spacing: 8) {
                        Text("SOFTWARETAKT")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white,
                                        Color.cyan.opacity(0.9),
                                        Color.blue.opacity(0.7)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .cyan.opacity(0.4), radius: 8)
                        
                        Text("Music Production Studio")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.gray.opacity(0.8))
                            .tracking(2)
                    }
                    .opacity(textOpacity)
                    
                    // Loading indicator
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                Rectangle()
                                    .fill(Color.cyan.opacity(0.8))
                                    .frame(width: 4, height: 20)
                                    .scaleEffect(y: waveAnimation ? 1.5 : 0.3)
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.1),
                                        value: waveAnimation
                                    )
                            }
                        }
                        
                        Text("Loading...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray.opacity(0.6))
                            .opacity(textOpacity)
                    }
                }
            }
            .onAppear {
                startSplashAnimations()
            }
        }
        
        private func startSplashAnimations() {
            // Logo animations
            withAnimation(.easeOut(duration: 0.8)) {
                logoOpacity = 1.0
            }
            
            withAnimation(.spring(response: 1.2, dampingFraction: 0.6).delay(0.3)) {
                logoScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
                glowRadius = 15
            }
            
            withAnimation(.easeInOut(duration: 0.8).delay(0.8)) {
                textOpacity = 1.0
            }
            
            // Start continuous animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                circleRotation = 360
                waveAnimation = true
            }
        }
    }

    // MARK: - Enhanced Background Component
    
    struct AnimatedBackground: View {
        @State private var gradientRotation: Double = 0
        @State private var particleOffset: CGFloat = 0
        
        var body: some View {
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.05, blue: 0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animated overlay gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.cyan.opacity(0.03),
                        Color.blue.opacity(0.02),
                        Color.purple.opacity(0.03),
                        Color.clear
                    ]),
                    startPoint: UnitPoint(x: cos(gradientRotation * .pi / 180), 
                                        y: sin(gradientRotation * .pi / 180)),
                    endPoint: UnitPoint(x: cos((gradientRotation + 180) * .pi / 180), 
                                      y: sin((gradientRotation + 180) * .pi / 180))
                )
                .ignoresSafeArea()
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: gradientRotation)
                
                // Subtle particle effect
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.1),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 1,
                                endRadius: 20
                            )
                        )
                        .frame(width: CGFloat.random(in: 10...30))
                        .position(
                            x: CGFloat.random(in: 0...screenWidth()),
                            y: CGFloat.random(in: 0...screenHeight()) + particleOffset
                        )
                        .animation(
                            .linear(duration: Double.random(in: 8...15))
                            .repeatForever(autoreverses: false)
                            .delay(Double.random(in: 0...5)),
                            value: particleOffset
                        )
                }
            }
            .onAppear {
                gradientRotation = 360
                particleOffset = -screenHeight()
            }
        }
    }
    
    // MARK: - Sleek Navigation Bar
    
    private var sleekNavigationBar: some View {
        VStack(spacing: 12) {
            // Top status bar
            HStack {
                // App title with enhanced glow effect
                HStack(spacing: 8) {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan,
                                    Color.blue.opacity(0.8),
                                    Color.blue.opacity(0.3)
                                ]),
                                center: .center,
                                startRadius: 1,
                                endRadius: 8
                            )
                        )
                        .frame(width: 8, height: 8)
                        .shadow(color: .cyan, radius: pulseAnimation ? 6 : 3)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Text("SOFTWARETAKT")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.cyan.opacity(0.9),
                                    Color.blue.opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.3), radius: 2)
                }
                
                Spacer()
                
                // Enhanced status indicators
                HStack(spacing: 16) {
                    enhancedStatusIndicator(
                        isActive: audioEngine.isPlaying, 
                        icon: "waveform", 
                        color: .green,
                        label: "AUDIO"
                    )
                    enhancedStatusIndicator(
                        isActive: midiManager.isConnected, 
                        icon: "dot.radiowaves.left.and.right", 
                        color: .blue,
                        label: "MIDI"
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Enhanced mode selector cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    enhancedModeCard(.overview, icon: "grid.circle", title: "OVERVIEW", accentColor: .cyan)
                    enhancedModeCard(.step, icon: "waveform", title: "STEP EDIT", accentColor: .blue)
                    enhancedModeCard(.pads, icon: "grid.circle.fill", title: "PADS", accentColor: .purple)
                    enhancedModeCard(.fmTest, icon: "waveform.path.ecg", title: "FM SYNTH", accentColor: .orange)
                    enhancedModeCard(.projects, icon: "folder.fill", title: "PROJECTS", accentColor: .green)
                    enhancedModeCard(.samples, icon: "music.note.list", title: "SAMPLES", accentColor: .pink)
                    enhancedModeCard(.web, icon: "globe", title: "WEB VERSION", accentColor: .red)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(
            ZStack {
                // Base material
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.1),
                        Color.clear,
                        Color.black.opacity(0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Bottom edge highlight
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.3),
                                    Color.blue.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }
            }
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.8),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        )
    }
    
    // MARK: - Enhanced Mode Selection Card
    
    private func enhancedModeCard(_ mode: ViewMode, icon: String, title: String, accentColor: Color) -> some View {
        Button(action: { 
            hapticFeedback(.light)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                viewMode = mode 
            }
        }) {
            VStack(spacing: 6) {
                // Icon with glow effect when selected
                ZStack {
                    if viewMode == mode {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .blur(radius: 8)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(viewMode == mode ? accentColor : .gray)
                        .shadow(color: viewMode == mode ? accentColor.opacity(0.5) : .clear, radius: 4)
                }
                
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(viewMode == mode ? .white : .gray)
                    .shadow(color: viewMode == mode ? accentColor.opacity(0.3) : .clear, radius: 2)
            }
            .frame(width: 80, height: 56)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            viewMode == mode ? 
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(0.3),
                                    accentColor.opacity(0.1),
                                    Color.black.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.05),
                                    Color.black.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            viewMode == mode ? 
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(0.8),
                                    accentColor.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: viewMode == mode ? 1.5 : 0.5
                        )
                    
                    // Inner highlight
                    if viewMode == mode {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .center
                                ),
                                lineWidth: 0.5
                            )
                            .padding(1)
                    }
                }
            )
            .shadow(
                color: viewMode == mode ? accentColor.opacity(0.4) : .black.opacity(0.2), 
                radius: viewMode == mode ? 12 : 4,
                x: 0,
                y: viewMode == mode ? 4 : 2
            )
            .scaleEffect(viewMode == mode ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Enhanced Status Indicator
    
    private func enhancedStatusIndicator(isActive: Bool, icon: String, color: Color, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isActive ? color : .gray)
                    .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: 2)
                
                Circle()
                    .fill(isActive ? color : Color.gray)
                    .frame(width: 6, height: 6)
                    .shadow(color: isActive ? color : .clear, radius: isActive ? 4 : 0)
                    .scaleEffect(isActive ? (pulseAnimation ? 1.2 : 1.0) : 0.8)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
            }
            
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundColor(isActive ? color.opacity(0.8) : .gray.opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(isActive ? 0.1 : 0.03),
                            Color.black.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isActive ? color.opacity(0.3) : Color.white.opacity(0.05),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Enhanced Main Content View
    
    private func mainContentView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Enhanced content card with multi-layer glassmorphism
            ZStack {
                // Background blur layer
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03),
                                Color.black.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Content layer
                Group {
                    switch viewMode {
                    case .overview:
                        PatternOverview(song: song)
                    case .step:
                        if !song.patterns.isEmpty {
                            ElektronStepEditor(pattern: song.patterns[0], trackIndex: selectedTrack)
                        } else {
                            enhancedEmptyStateView
                        }
                    case .pads:
                        originalPadView(geometry: geometry)
                    case .fmTest:
                        FMTestConsole()
                            .environmentObject(audioEngine)
                    case .projects:
                        ProjectBrowserView(projectManager: projectManager)
                    case .samples:
                        SimpleSampleBrowserView()
                            .environmentObject(audioEngine)
                    case .web:
                        SoftwaretaktWebView()
                            .ignoresSafeArea()
                    }
                }
                .padding(20)
            }
            .overlay(
                // Enhanced border with multiple layers
                ZStack {
                    // Outer glow
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.1),
                                    Color.blue.opacity(0.05),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .blur(radius: 1)
                    
                    // Main border
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05),
                                    Color.cyan.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    
                    // Inner highlight
                    RoundedRectangle(cornerRadius: 23)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .center
                            ),
                            lineWidth: 0.5
                        )
                        .padding(1)
                }
            )
            .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 15)
            .shadow(color: .cyan.opacity(0.1), radius: 40, x: 0, y: 20)
        }
    }
    
    // MARK: - Enhanced Empty State
    
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 10)
                
                Image(systemName: "music.note")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.8),
                                Color.blue.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.3), radius: 8)
            }
            
            VStack(spacing: 8) {
                Text("No patterns available")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Create a new pattern to get started")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray.opacity(0.8))
            }
            
            Button(action: {
                // Add pattern creation logic here
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Pattern")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.3),
                                    Color.blue.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .shadow(color: .cyan.opacity(0.3), radius: 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - View Mode Selector
    
    private var viewModeSelector: some View {
        HStack(spacing: 0) {
            Button(action: { viewMode = .overview }) {
                HStack {
                    Image(systemName: "grid.circle")
                    Text("OVERVIEW")
                }
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewMode == .overview ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(viewMode == .overview ? .white : .gray)
            }
            
            Button(action: { viewMode = .step }) {
                HStack {
                    Image(systemName: "waveform")
                    Text("STEP EDIT")
                }
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewMode == .step ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(viewMode == .step ? .white : .gray)
            }
            
            Button(action: { viewMode = .pads }) {
                HStack {
                    Image(systemName: "grid.circle.fill")
                    Text("PADS")
                }
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewMode == .pads ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(viewMode == .pads ? .white : .gray)
            }
            
            Button(action: { viewMode = .fmTest }) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                    Text("FM TEST")
                }
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewMode == .fmTest ? Color.red : Color.gray.opacity(0.3))
                .foregroundColor(viewMode == .fmTest ? .white : .gray)
            }
            
            Button(action: { viewMode = .projects }) {
                HStack {
                    Image(systemName: "folder.fill")
                    Text("PROJECTS")
                }
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewMode == .projects ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(viewMode == .projects ? .white : .gray)
            }
            
            Button(action: { viewMode = .samples }) {
                HStack {
                    Image(systemName: "music.note.list")
                    Text("SAMPLES")
                }
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewMode == .samples ? Color.purple : Color.gray.opacity(0.3))
                .foregroundColor(viewMode == .samples ? .white : .gray)
            }
            
            Button(action: { viewMode = .web }) {
                HStack {
                    Image(systemName: "globe")
                    Text("WEB VERSION")
                }
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewMode == .web ? Color.red : Color.gray.opacity(0.3))
                .foregroundColor(viewMode == .web ? .white : .gray)
            }
            
            Spacer()
            
            // Pattern info when not in overview mode
            if viewMode != .overview && !song.patterns.isEmpty {
                Text("PATTERN 1 - \(song.patterns[0].name)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.trailing)
            }
        }
        .background(Color.black)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    // MARK: - Original Pad View (preserved for sample triggering)
    
    private func originalPadView(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Main area (left side)
            VStack(spacing: 10) {
                // Track selector with bank switching
                trackSelectorView
                
                // 8x8 Pad Grid
                PadGridView(selectedTrack: selectedTrack)
                    .environmentObject(audioEngine)
                
                // Transport controls
                transportControls
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.7)
            
            // Right panel - controls
            VStack(spacing: 20) {
                // Current track info
                currentTrackInfo
                
                // Engine Type and Controls
                engineControls
                
                // Browser buttons
                browserButtons
                
                // MIDI connection status
                midiStatus
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.3)
            .padding()
        }
    }
    
    private var trackSelectorView: some View {
        VStack(spacing: 10) {
            // Bank selector
            HStack {
                Button("Bank A (1-8)") {
                    selectedBank = 0
                    if selectedTrack >= 8 {
                        selectedTrack = 0
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedBank == 0 ? Color.orange : Color.gray.opacity(0.3))
                .foregroundColor(selectedBank == 0 ? .black : .white)
                .cornerRadius(8)
                
                Button("Bank B (9-16)") {
                    selectedBank = 1
                    if selectedTrack < 8 {
                        selectedTrack = 8
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedBank == 1 ? Color.orange : Color.gray.opacity(0.3))
                .foregroundColor(selectedBank == 1 ? .black : .white)
                .cornerRadius(8)
                
                Spacer()
            }
            
            // Track buttons for current bank
            HStack {
                let startTrack = selectedBank * 8
                let endTrack = startTrack + 8
                
                ForEach(startTrack..<endTrack, id: \.self) { track in
                    Button(action: {
                        selectedTrack = track
                    }) {
                        VStack(spacing: 2) {
                            Text("T\(track + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            // Show engine type indicator
                            Text(audioEngine.getEngineType(forTrack: track).rawValue)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .foregroundColor(selectedTrack == track ? .black : .white)
                        .frame(width: 50, height: 45)
                        .background(selectedTrack == track ? Color.cyan : 
                                  (audioEngine.getEngineType(forTrack: track) == .sample ? 
                                   Color.blue.opacity(0.3) : Color.orange.opacity(0.3)))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var currentTrackInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRACK \(selectedTrack + 1)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                Text("ENGINE:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(audioEngine.getEngineType(forTrack: selectedTrack).displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Spacer()
            }
            
            if audioEngine.getEngineType(forTrack: selectedTrack) == .sample {
                if let sample = audioEngine.getSample(for: selectedTrack) {
                    Text("Sample: \(sample.name)")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("No sample loaded")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var engineControls: some View {
        VStack(spacing: 12) {
            // Engine type quick selector
            HStack {
                Button("SMPL") {
                    audioEngine.setEngineType(.sample, forTrack: selectedTrack)
                }
                .buttonStyle(EngineButtonStyle(
                    isSelected: audioEngine.getEngineType(forTrack: selectedTrack) == .sample
                ))
                
                Button("DVCO") {
                    audioEngine.setEngineType(.dvco, forTrack: selectedTrack)
                }
                .buttonStyle(EngineButtonStyle(
                    isSelected: audioEngine.getEngineType(forTrack: selectedTrack) == .dvco
                ))
                
                Button("ANLG") {
                    audioEngine.setEngineType(.analog, forTrack: selectedTrack)
                }
                .buttonStyle(EngineButtonStyle(
                    isSelected: audioEngine.getEngineType(forTrack: selectedTrack) == .analog
                ))
                
                Button("FM") {
                    audioEngine.setEngineType(.fmOpal, forTrack: selectedTrack)
                }
                .buttonStyle(EngineButtonStyle(
                    isSelected: audioEngine.getEngineType(forTrack: selectedTrack) == .fmOpal
                ))
            }
            
            // Track controls
            TrackControlView(trackIndex: selectedTrack)
                .environmentObject(audioEngine)
        }
    }
    
    private var browserButtons: some View {
        VStack(spacing: 12) {
            if audioEngine.getEngineType(forTrack: selectedTrack) == .sample {
                Button("Sample Browser") {
                    activeSheet = .sampleBrowser
                }
                .buttonStyle(GlassmorphicButtonStyle(accentColor: .blue, isActive: true))
                
                // Sample Editor shortcut (if sample is loaded)
                if let currentSample = audioEngine.getSimpleSample(for: selectedTrack) {
                    Button("Edit Sample") {
                        activeSheet = .sampleEditor(currentSample)
                    }
                    .buttonStyle(GlassmorphicButtonStyle(accentColor: .purple, isActive: true))
                }
            } else {
                Button("Synth Controls") {
                    activeSheet = .synthControls
                }
                .buttonStyle(GlassmorphicButtonStyle(accentColor: .orange, isActive: true))
            }
            
            Button("TEST TRACK \(selectedTrack + 1)") {
                // Test current track
                audioEngine.triggerTrack(selectedTrack, note: 60, velocity: 1.0, padIndex: 0)
            }
            .buttonStyle(GlassmorphicButtonStyle(accentColor: .green, isActive: false))
        }
    }
    
    private var transportControls: some View {
        HStack {
            Spacer()
            
            Button(action: {
                hapticFeedback(.heavy)
                togglePlayback()
            }) {
                ZStack {
                    // Glow effect when playing
                    if isPlaying {
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .blur(radius: 15)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseAnimation)
                    }
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    isPlaying ? Color.red.opacity(0.9) : Color.green.opacity(0.9),
                                    isPlaying ? Color.red.opacity(0.7) : Color.green.opacity(0.7),
                                    isPlaying ? Color.red.opacity(0.5) : Color.green.opacity(0.5)
                                ]),
                                center: .center,
                                startRadius: 5,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .shadow(color: isPlaying ? .red.opacity(0.4) : .green.opacity(0.4), radius: 15)
            
            Spacer()
        }
        .padding()
    }
    
    private var midiStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MIDI Controllers")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Circle()
                    .fill(midiManager.isPush2Connected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text("Push 2")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Circle()
                    .fill(midiManager.isLaunchkeyConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text("Launchkey 25")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            audioEngine.startSequencer()
        } else {
            audioEngine.stopSequencer()
        }
    }
    
    // MARK: - Setup and Animation
    
    private func startBackgroundAnimations() {
        withAnimation(.linear(duration: 0.1)) {
            pulseAnimation = true
        }
        
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
    }
    
    private func setupDefaultSong() {
        if song.patterns.isEmpty {
            // Create default patterns for each track type
            let kickPattern = Pattern(length: 16, name: "Kick Pattern")
            kickPattern.toggleStep(0)
            kickPattern.toggleStep(4)
            kickPattern.toggleStep(8)
            kickPattern.toggleStep(12)
            
            let snarePattern = Pattern(length: 16, name: "Snare Pattern")
            snarePattern.toggleStep(4)
            snarePattern.toggleStep(12)
            
            let hihatPattern = Pattern(length: 16, name: "Hi-Hat Pattern")
            hihatPattern.toggleStep(2)
            hihatPattern.toggleStep(6)
            hihatPattern.toggleStep(10)
            hihatPattern.toggleStep(14)
            
            song.addPattern(kickPattern)
            song.addPattern(snarePattern)
            song.addPattern(hihatPattern)
            
            // Add to chain
            song.addToChain(patternId: kickPattern.id)
        }
    }
}

struct EngineButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            #if os(macOS)
            .font(.caption.weight(.bold))
            #else
            .fontWeight(.bold)
            #endif
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: isSelected ? [
                                    Color.orange.opacity(0.8),
                                    Color.orange.opacity(0.6)
                                ] : [
                                    Color.white.opacity(0.05),
                                    Color.black.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Capsule()
                        .stroke(
                            isSelected ? Color.orange.opacity(0.8) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                }
            )
            .foregroundColor(isSelected ? .black : .white)
            .shadow(color: isSelected ? .orange.opacity(0.4) : .clear, radius: 6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GlassmorphicButtonStyle: ButtonStyle {
    let accentColor: Color
    let isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(isActive ? 0.15 : 0.05),
                                    Color.black.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isActive ? accentColor.opacity(0.6) : Color.white.opacity(0.1),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: isActive ? accentColor.opacity(0.3) : .black.opacity(0.1), radius: 8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioEngine())
        .environmentObject(MIDIManager())
        .preferredColorScheme(.dark)
}
