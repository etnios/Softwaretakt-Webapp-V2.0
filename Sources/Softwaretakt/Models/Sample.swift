import Foundation
import AVFoundation
import CryptoKit

struct Sample: Identifiable, Codable {
    var id = UUID()
    let url: URL
    let name: String
    let duration: TimeInterval
    let sampleRate: Double
    let channels: Int
    let createdAt: Date
    
    // File integrity and tracking
    let fileSize: Int
    let md5Hash: String?
    
    // Slicing information
    var slicePoints: [TimeInterval] = []
    var isSliced: Bool { return !slicePoints.isEmpty }
    
    init(url: URL) {
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.createdAt = Date()
        
        // Get file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            self.fileSize = attributes[.size] as? Int ?? 0
        } catch {
            self.fileSize = 0
        }
        
        // Calculate MD5 hash for integrity checking
        self.md5Hash = Self.calculateMD5(for: url)
        
        // Extract audio file information
        do {
            let audioFile = try AVAudioFile(forReading: url)
            self.duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
            self.sampleRate = audioFile.fileFormat.sampleRate
            self.channels = Int(audioFile.fileFormat.channelCount)
        } catch {
            print("❌ Failed to read audio file info: \(error)")
            self.duration = 0.0
            self.sampleRate = 44100.0
            self.channels = 2
        }
    }
    
    // Custom init for creating samples with slice information
    init(url: URL, name: String, duration: TimeInterval, sampleRate: Double, channels: Int, slicePoints: [TimeInterval] = []) {
        self.url = url
        self.name = name
        self.duration = duration
        self.sampleRate = sampleRate
        self.channels = channels
        self.slicePoints = slicePoints
        self.createdAt = Date()
        
        // Initialize new properties
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            self.fileSize = attributes[.size] as? Int ?? 0
        } catch {
            self.fileSize = 0
        }
        
        self.md5Hash = Self.calculateMD5(for: url)
    }
    
    // MARK: - Slicing Methods
    
    mutating func addSlicePoint(at time: TimeInterval) {
        guard time > 0 && time < duration else { return }
        
        // Insert slice point in sorted order
        if let insertIndex = slicePoints.firstIndex(where: { $0 > time }) {
            slicePoints.insert(time, at: insertIndex)
        } else {
            slicePoints.append(time)
        }
    }
    
    mutating func removeSlicePoint(at time: TimeInterval, tolerance: TimeInterval = 0.01) {
        slicePoints.removeAll { abs($0 - time) <= tolerance }
    }
    
    mutating func clearSlicePoints() {
        slicePoints.removeAll()
    }
    
    func getSlices() -> [SampleSlice] {
        guard !slicePoints.isEmpty else {
            return [SampleSlice(sample: self, startTime: 0, endTime: duration, index: 0)]
        }
        
        var slices: [SampleSlice] = []
        var previousTime: TimeInterval = 0
        
        for (index, slicePoint) in slicePoints.enumerated() {
            let slice = SampleSlice(
                sample: self,
                startTime: previousTime,
                endTime: slicePoint,
                index: index
            )
            slices.append(slice)
            previousTime = slicePoint
        }
        
        // Add final slice from last point to end
        let finalSlice = SampleSlice(
            sample: self,
            startTime: previousTime,
            endTime: duration,
            index: slicePoints.count
        )
        slices.append(finalSlice)
        
        return slices
    }
    
    // Auto-slice based on transients or beats
    mutating func autoSlice(method: AutoSliceMethod, sensitivity: Float = 0.5) {
        // This would analyze the audio file and create slice points
        // For now, create evenly spaced slices as placeholder
        
        let numSlices: Int
        
        switch method {
        case .beats(let bpm):
            let beatInterval = 60.0 / Double(bpm)
            numSlices = max(1, Int(duration / beatInterval))
        case .transients:
            // Would use audio analysis to detect transients
            numSlices = max(1, Int(duration * Double(sensitivity) * 4))
        case .even(let count):
            numSlices = count
        }
        
        clearSlicePoints()
        
        for i in 1..<numSlices {
            let sliceTime = duration * Double(i) / Double(numSlices)
            addSlicePoint(at: sliceTime)
        }
    }
    
    // MD5 hash calculation for file integrity
    private static func calculateMD5(for url: URL) -> String? {
        do {
            let data = try Data(contentsOf: url)
            let hash = Insecure.MD5.hash(data: data)
            return hash.map { String(format: "%02x", $0) }.joined()
        } catch {
            print("❌ Failed to calculate MD5 hash: \(error)")
            return nil
        }
    }
    
    // Verify file integrity
    func verifyIntegrity() -> Bool {
        guard let expectedHash = md5Hash else { return false }
        
        let currentHash = Self.calculateMD5(for: url)
        return currentHash == expectedHash
    }
    
    // Check if file exists
    var fileExists: Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
}

// Represents a slice of a sample
struct SampleSlice: Identifiable {
    let id = UUID()
    let sample: Sample
    let startTime: TimeInterval
    let endTime: TimeInterval
    let index: Int
    
    var duration: TimeInterval {
        return endTime - startTime
    }
    
    var name: String {
        return "\(sample.name) - Slice \(index + 1)"
    }
}

// Auto-slicing methods
enum AutoSliceMethod {
    case beats(bpm: Float)
    case transients
    case even(count: Int)
}

// Sample categories for organization
enum SampleCategory: String, CaseIterable, Codable {
    case drums = "Drums"
    case percussion = "Percussion"
    case bass = "Bass"
    case melody = "Melody"
    case vocal = "Vocal"
    case fx = "FX"
    case loop = "Loop"
    case other = "Other"
    
    var emoji: String {
        switch self {
        case .drums: return "🥁"
        case .percussion: return "🪘"
        case .bass: return "🎸"
        case .melody: return "🎹"
        case .vocal: return "🎤"
        case .fx: return "✨"
        case .loop: return "🔄"
        case .other: return "📁"
        }
    }
}
