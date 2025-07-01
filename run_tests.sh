#!/bin/bash

echo "🎵 SOFTWARETAKT - TEST RUNNER"
echo "============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

echo -e "${BLUE}📋 Checking project structure...${NC}"

# Check if critical files exist
critical_files=(
    "Sources/Softwaretakt/App/SoftwaretaktApp.swift"
    "Sources/Softwaretakt/App/ContentView.swift"  
    "Sources/Softwaretakt/Audio/AudioEngine.swift"
    "Sources/Softwaretakt/Models/Track.swift"
    "Sources/Softwaretakt/Models/Pattern.swift"
    "Tests/SoftwaretaktTests/SoftwaretaktTests.swift"
    "Package.swift"
)

all_files_exist=true
for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✅${NC} $file"
    else
        echo -e "  ${RED}❌${NC} $file (missing)"
        all_files_exist=false
    fi
done

if [ "$all_files_exist" = false ]; then
    echo -e "${RED}❌ Some critical files are missing. Cannot run tests.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🧪 Running Swift tests...${NC}"

# Clean first
swift package clean

# Try to run tests
echo "Building and running tests..."
swift test 2>&1 | tee test_output.log

test_result=$?

echo ""
echo "==================================="
if [ $test_result -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo ""
    echo "✅ Project is ready for development"
    echo "✅ Core Swift modules compile successfully"  
    echo "✅ Basic functionality tests pass"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "• Run: swift run SoftwaretaktApp"
    echo "• Open project in Xcode for iOS development"
    echo "• Add more comprehensive tests"
else
    echo -e "${RED}❌ TESTS FAILED${NC}"
    echo ""
    echo "Check test_output.log for detailed error information"
    echo ""
    echo -e "${YELLOW}Common issues:${NC}"
    echo "• Platform-specific code issues (iOS vs macOS)"
    echo "• Missing dependencies or imports"
    echo "• AudioKit integration problems"
    echo ""
    echo -e "${BLUE}To debug:${NC}"
    echo "• Check compilation errors in test_output.log"
    echo "• Verify all dependencies are properly imported"
    echo "• Make sure platform-specific code is properly guarded"
fi

echo "==================================="
exit $test_result
