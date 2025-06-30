import SwiftUI

@main
struct SoftwaretaktApp: App {
    @StateObject private var audioEngine = AudioEngine()
    @StateObject private var midiManager = MIDIManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioEngine)
                .environmentObject(midiManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        print("🎵 Softwaretakt starting up...")
        
        // Initialize audio engine
        audioEngine.start()
        
        // Initialize MIDI manager
        midiManager.setup()
        
        print("✅ Softwaretakt ready!")
    }
}
