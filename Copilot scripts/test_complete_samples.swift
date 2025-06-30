#!/usr/bin/env swift

import Foundation
import AVFoundation

// Mimic the SimpleSampleManager functionality for testing
print("🎵 Testing Complete Sample Loading System...")

let supportedFormats = ["wav", "aiff", "mp3", "m4a", "caf"]

// Test 1: Bundled samples (from app resources)
print("\n📦 Testing Bundled Samples:")
let bundlePath = "Sources/Softwaretakt/Resources"
let bundleURL = URL(fileURLWithPath: bundlePath)

do {
    let files = try FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
    
    for file in files {
        let fileExtension = file.pathExtension.lowercased()
        if supportedFormats.contains(fileExtension) {
            print("✅ Found bundled sample: \(file.lastPathComponent)")
            
            do {
                let audioFile = try AVAudioFile(forReading: file)
                let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
                print("   📊 \(String(format: "%.2f", duration))s, \(Int(audioFile.fileFormat.sampleRate))Hz")
            } catch {
                print("   ⚠️ Could not read audio info: \(error)")
            }
        }
    }
} catch {
    print("❌ Could not load bundled samples: \(error)")
}

// Test 2: User samples (from Documents directory)
print("\n👤 Testing User Samples:")
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let userSamplesDirectory = documentsPath.appendingPathComponent("Softwaretakt/Samples")

if FileManager.default.fileExists(atPath: userSamplesDirectory.path) {
    do {
        let files = try FileManager.default.contentsOfDirectory(at: userSamplesDirectory, includingPropertiesForKeys: nil)
        
        for file in files {
            let fileExtension = file.pathExtension.lowercased()
            if supportedFormats.contains(fileExtension) {
                print("✅ Found user sample: \(file.lastPathComponent)")
                
                do {
                    let audioFile = try AVAudioFile(forReading: file)
                    let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
                    print("   📊 \(String(format: "%.2f", duration))s, \(Int(audioFile.fileFormat.sampleRate))Hz")
                } catch {
                    print("   ⚠️ Could not read audio info: \(error)")
                }
            }
        }
    } catch {
        print("❌ Could not load user samples: \(error)")
    }
} else {
    print("📁 User samples directory doesn't exist yet")
}

// Test 3: Sample import simulation
print("\n📥 Testing Sample Import:")
let testSamplePath = ".build/checkouts/AudioKit/Tests/AudioKitTests/TestResources/chromaticScale-1.aiff"
let testSampleURL = URL(fileURLWithPath: testSamplePath)

if FileManager.default.fileExists(atPath: testSampleURL.path) {
    // Simulate importing this sample
    let samplesDirectory = documentsPath.appendingPathComponent("Samples")
    let destinationURL = samplesDirectory.appendingPathComponent(testSampleURL.lastPathComponent)
    
    do {
        // Create directory if needed
        try FileManager.default.createDirectory(at: samplesDirectory, withIntermediateDirectories: true)
        
        // Copy file (remove existing if present)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: testSampleURL, to: destinationURL)
        
        print("✅ Successfully imported: \(testSampleURL.lastPathComponent)")
        
        // Verify the imported sample
        let audioFile = try AVAudioFile(forReading: destinationURL)
        let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
        print("   📊 \(String(format: "%.2f", duration))s, \(Int(audioFile.fileFormat.sampleRate))Hz")
        
    } catch {
        print("❌ Failed to import sample: \(error)")
    }
} else {
    print("❌ Test sample not found")
}

print("\n🎛️ Sample loading system test complete!")
print("✨ Ready to load real samples in the app!")
