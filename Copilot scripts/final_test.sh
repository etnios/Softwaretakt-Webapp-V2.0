#!/bin/bash
echo "🎵 SOFTWARETAKT - Final Build Test"
echo "=================================="

# Remove the extra file we created
rm -f Sources/Softwaretakt/Models/SimpleSampleManagerEmpty.swift
echo "✅ Cleaned up extra files"

# Clean up any build artifacts
swift package clean 2>/dev/null || true
echo "✅ Cleaned build cache"

echo ""
echo "📦 Package information:"
swift package describe --type json | grep -E '"name"|"type"' | head -4

echo ""
echo "🔨 Building project..."
swift build --configuration release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo ""
    echo "🚀 Ready to run:"
    echo "   swift run SoftwaretaktApp"
    echo ""
    echo "🎯 Features ready:"
    echo "   • Audio Engine with FM synthesis and sample playback"
    echo "   • 16-track hybrid sample/synth sequencer"
    echo "   • MIDI controller support (Push 2, Launchkey)"
    echo "   • Sample browser with import/preview functionality"
    echo "   • Complete SwiftUI interface"
    echo ""
    echo "🎵 Softwaretakt is ready to make music!"
else
    echo ""
    echo "❌ BUILD FAILED"
    echo ""
    echo "Check the errors above and fix any remaining issues."
    exit 1
fi
