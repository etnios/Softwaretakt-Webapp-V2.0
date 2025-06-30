#!/usr/bin/env swift

import Foundation
import AVFoundation

// Simple test to verify sample loading works
print("🎵 Testing Sample Loading...")

// Test the basic audio file paths we copied
let testFiles = [
    "Sources/Softwaretakt/Resources/drumloop.wav",
    "Sources/Softwaretakt/Resources/dish.wav", 
    "Sources/Softwaretakt/Resources/saw220.wav"
]

for file in testFiles {
    let url = URL(fileURLWithPath: file)
    
    if FileManager.default.fileExists(atPath: url.path) {
        print("✅ Found: \(url.lastPathComponent)")
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
            let sampleRate = audioFile.fileFormat.sampleRate
            let channels = audioFile.fileFormat.channelCount
            
            print("   📊 Duration: \(String(format: "%.2f", duration))s, Rate: \(Int(sampleRate))Hz, Channels: \(channels)")
        } catch {
            print("   ❌ Could not read audio info: \(error)")
        }
    } else {
        print("❌ Missing: \(url.lastPathComponent)")
    }
}

print("\n🎛️ Sample loading test complete!")
