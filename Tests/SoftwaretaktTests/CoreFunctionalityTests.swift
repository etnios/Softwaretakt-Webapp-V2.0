import XCTest
@testable import Softwaretakt

final class CoreFunctionalityTests: XCTestCase {
    
    func testTrackCreation() throws {
        // Test basic track creation
        let track = Track(id: 1, name: "Test Track")
        XCTAssertEqual(track.id, 1)
        XCTAssertEqual(track.name, "Test Track")
        XCTAssertFalse(track.isMuted)
        XCTAssertFalse(track.isSoloed)
    }
    
    func testPatternCreation() throws {
        // Test pattern creation with steps
        let pattern = Pattern(id: 1, name: "Test Pattern")
        XCTAssertEqual(pattern.id, 1)
        XCTAssertEqual(pattern.name, "Test Pattern")
        XCTAssertEqual(pattern.length, 16) // Default pattern length
    }
    
    func testStepFunctionality() throws {
        // Test step creation and properties
        let step = Step()
        XCTAssertFalse(step.isActive)
        XCTAssertEqual(step.velocity, 1.0)
        
        // Test activating a step
        var activeStep = step
        activeStep.isActive = true
        XCTAssertTrue(activeStep.isActive)
    }
    
    func testBasicEnumerations() throws {
        // Test enums work correctly
        let condition = TrigCondition.none
        XCTAssertEqual(condition.rawValue, "---")
        
        let paramType = ParameterLockType.volume
        XCTAssertEqual(paramType.rawValue, "Volume")
    }
    
    func testSampleCreation() throws {
        // Test sample creation with a dummy URL
        let testURL = URL(fileURLWithPath: "/tmp/test.wav")
        let sample = Sample(url: testURL)
        
        XCTAssertEqual(sample.url, testURL)
        XCTAssertEqual(sample.name, "test")
        XCTAssertNotNil(sample.createdAt)
    }
}
