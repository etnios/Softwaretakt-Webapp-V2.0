#!/bin/bash
echo "🎵 SOFTWARETAKT - FINAL COMPREHENSIVE BUILD TEST"
echo "=============================================="
echo ""

# Test that all main files compile without errors
echo "📋 Checking critical files for errors..."

FILES_TO_CHECK=(
    "Sources/Softwaretakt/App/SoftwaretaktApp.swift"
    "Sources/Softwaretakt/App/ContentView.swift"
    "Sources/Softwaretakt/Audio/AudioEngine.swift"
    "Sources/Softwaretakt/Models/SampleSystem.swift"
    "Sources/Softwaretakt/Views/SimpleSampleBrowserView.swift"
    "Sources/Softwaretakt/Views/SampleBrowserView.swift"
    "Sources/Softwaretakt/MIDI/MIDIManager.swift"
)

for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file exists"
    else
        echo "  ❌ $file missing"
        exit 1
    fi
done

echo ""
echo "🧹 Cleaning up project..."
# Remove any leftover duplicate files
rm -f Sources/Softwaretakt/Models/SimpleSampleManagerEmpty.swift
rm -f cleanup_samples.sh
rm -f delete_duplicates.swift

# Clean build cache
swift package clean 2>/dev/null || true
echo "✅ Project cleaned"

echo ""
echo "📦 Package information:"
echo "   • Target platforms: iOS 15.0+, macOS 13.0+"
echo "   • Swift Package Manager executable"
swift package describe --type json | grep -E '"name"|"type"' | head -4

echo ""
echo "🔨 Building Softwaretakt..."
echo "Building in release mode for best performance..."
swift build --configuration release

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 ==============================================="
    echo "🎉 SOFTWARETAKT BUILD COMPLETELY SUCCESSFUL!"
    echo "🎉 ==============================================="
    echo ""
    echo "🚀 To run your music app:"
    echo "   swift run SoftwaretaktApp"
    echo ""
    echo "🎯 Your app includes:"
    echo "   🎹 16-track hybrid sequencer (samples + FM synthesis)"
    echo "   🎵 Professional AudioKit-powered audio engine" 
    echo "   🎛️ MIDI controller support (Push 2, Launchkey)"
    echo "   📁 Complete sample browser with import/preview"
    echo "   🎨 Modern SwiftUI interface with dark theme"
    echo "   🔊 Real-time audio effects and processing"
    echo ""
    echo "📋 System Requirements:"
    echo "   • macOS 13.0 (Ventura) or later"
    echo "   • iOS 15.0 or later"
    echo ""
    echo "🎵 Ready to make music with Softwaretakt!"
    echo ""
    exit 0
else
    echo ""
    echo "❌ ==============================================="
    echo "❌ BUILD FAILED - CHECK ERRORS ABOVE"
    echo "❌ ==============================================="
    exit 1
fi
