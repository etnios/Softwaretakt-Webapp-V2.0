#!/bin/bash
echo "🏗️ Building Softwaretakt..."
echo "📁 Working directory: $(pwd)"
echo "📦 Package info:"
swift package describe --type json | grep -E '"name"|"type"' | head -4

echo ""
echo "🔨 Starting build..."
swift build --configuration release --verbose

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "🚀 Ready to run with: swift run SoftwaretaktApp"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
