import Foundation
import AVFoundation

// MARK: - Simple Sample Categories
enum SimpleSampleCategory: String, CaseIterable, Codable {
    case bundled = "Bundled"    // Built into the app
    case user = "User"          // Imported by user
    case generated = "Generated" // Created by the app
    
    var displayName: String { rawValue }
}

// MARK: - Sample Edit Parameters
struct SampleEditParameters: Codable {
    // Envelope parameters
    var attack: Float = 0.01        // 0.001 to 2.0 seconds
    var decay: Float = 0.1          // 0.001 to 5.0 seconds
    var sustain: Float = 0.7        // 0.0 to 1.0
    var release: Float = 0.5        // 0.001 to 10.0 seconds
    
    // Pitch parameters
    var pitchCoarse: Float = 0.0    // -24 to +24 semitones
    var pitchFine: Float = 0.0      // -100 to +100 cents
    var autoTuneLock: Bool = false   // Lock to nearest semitone
    var autoTuneReference: Float = 440.0 // A4 reference frequency
    
    // Filter parameters
    var filterCutoff: Float = 1.0   // 0.0 to 1.0 (20Hz to 20kHz)
    var filterResonance: Float = 0.0 // 0.0 to 1.0
    var filterType: FilterType = .lowpass
    
    // Amplitude parameters
    var volume: Float = 0.8         // 0.0 to 1.0
    var pan: Float = 0.0            // -1.0 (left) to +1.0 (right)
    
    // Sample playback parameters
    var startPoint: Float = 0.0     // 0.0 to 1.0
    var endPoint: Float = 1.0       // 0.0 to 1.0
    var loopEnabled: Bool = false
    var loopStart: Float = 0.0      // 0.0 to 1.0
    var loopEnd: Float = 1.0        // 0.0 to 1.0
    var reverse: Bool = false
}

enum FilterType: String, CaseIterable, Codable {
    case lowpass = "Low Pass"
    case highpass = "High Pass"
    case bandpass = "Band Pass"
    case notch = "Notch"
}

// MARK: - Simple Sample Model
struct SimpleSample: Identifiable, Codable {
    let id: UUID
    let url: URL
    let name: String
    let category: SimpleSampleCategory
    let createdAt: Date
    
    // Basic audio info (not encoded/decoded)
    var duration: TimeInterval = 0.0
    var sampleRate: Double = 44100.0
    var channels: Int = 2
    
    // Sample edit parameters
    var editParameters: SampleEditParameters = SampleEditParameters()
    
    // Custom coding keys to exclude audio info from encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case id, url, name, category, createdAt, editParameters
    }
    
    init(url: URL, category: SimpleSampleCategory) {
        self.id = UUID()
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.category = category
        self.createdAt = Date()
        
        // Try to get basic audio info with better error handling
        do {
            // Check if file exists first
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("⚠️ Sample file does not exist: \(url.path)")
                return
            }
            
            let audioFile = try AVAudioFile(forReading: url)
            self.duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
            self.sampleRate = audioFile.fileFormat.sampleRate
            self.channels = Int(audioFile.fileFormat.channelCount)
            
            print("✅ Successfully loaded audio info for \(name): \(durationString), \(Int(sampleRate))Hz, \(channels)ch")
        } catch {
            // Use defaults if file can't be read
            print("⚠️ Could not read audio info for \(name): \(error.localizedDescription)")
            self.duration = 1.0  // Default duration
            self.sampleRate = 44100.0
            self.channels = 2
        }
    }
    
    var exists: Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    var durationString: String {
        return String(format: "%.1fs", duration)
    }
    
    var categoryEmoji: String {
        switch category {
        case .bundled: return "📦"
        case .user: return "👤"
        case .generated: return "🔧"
        }
    }
}

// MARK: - Simple Sample Manager
@MainActor
class SimpleSampleManager: ObservableObject {
    
    // MARK: - Simple Sample Loading
    
    @Published var availableSamples: [SimpleSample] = []
    @Published var isLoading = false
    
    private let supportedFormats = ["wav", "aiff", "mp3", "m4a", "caf"]
    
    init() {
        loadBundledSamples()
        loadUserSamples()
    }
    
    // MARK: - Load samples from app bundle (built-in samples)
    private func loadBundledSamples() {
        guard let bundlePath = Bundle.main.resourcePath else { return }
        let bundleURL = URL(fileURLWithPath: bundlePath)
        
        loadSamplesFromDirectory(bundleURL, category: .bundled)
    }
    
    // MARK: - Load samples from Documents directory (user imported)
    private func loadUserSamples() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let samplesDirectory = documentsPath.appendingPathComponent("Samples")
        
        // Create samples directory if it doesn't exist
        try? FileManager.default.createDirectory(at: samplesDirectory, withIntermediateDirectories: true)
        
        loadSamplesFromDirectory(samplesDirectory, category: .user)
    }
    
    // MARK: - Load samples from any directory
    private func loadSamplesFromDirectory(_ directory: URL, category: SimpleSampleCategory) {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            for file in files {
                let fileExtension = file.pathExtension.lowercased()
                if supportedFormats.contains(fileExtension) {
                    let sample = SimpleSample(url: file, category: category)
                    availableSamples.append(sample)
                    print("✅ Loaded sample: \(sample.name)")
                }
            }
        } catch {
            print("⚠️ Could not load samples from \(directory): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Import new sample
    func importSample(from url: URL) -> Bool {
        // Implementation for importing samples
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let samplesDirectory = documentsPath.appendingPathComponent("Samples")
        let destinationURL = samplesDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
            let sample = SimpleSample(url: destinationURL, category: .user)
            availableSamples.append(sample)
            print("✅ Imported sample: \(sample.name)")
            return true
        } catch {
            print("❌ Failed to import sample: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Refresh samples
    func refresh() {
        availableSamples.removeAll()
        loadBundledSamples()
        loadUserSamples()
    }
    
    // MARK: - Get samples by category
    func getSamples(category: SimpleSampleCategory? = nil) -> [SimpleSample] {
        if let category = category {
            return availableSamples.filter { $0.category == category }
        }
        return availableSamples
    }
    
    // MARK: - Create default samples (for development/testing)
    func createDefaultSamples() {
        // This method is called when no samples are found
        // In a real app, you might want to create some default/demo samples
        print("📂 No samples found - you can import samples using the import button")
    }
}
