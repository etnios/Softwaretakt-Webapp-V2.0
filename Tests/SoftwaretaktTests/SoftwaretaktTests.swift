import XCTest
@testable import Softwaretakt

final class SoftwaretaktTests: XCTestCase {
    
    func testModuleLoads() {
        // Test that the module loads without crashing
        XCTAssertTrue(true, "Softwaretakt module loaded successfully")
    }
    
    func testBasicEnumerations() {
        // Test that enums work correctly
        let condition = TrigCondition.none
        XCTAssertEqual(condition.rawValue, "---")
        
        let paramType = ParameterLockType.volume
        XCTAssertEqual(paramType.rawValue, "Volume")
    }
    
    func testTrackCreation() {
        let track = Track(id: 1, name: "Test")
        XCTAssertEqual(track.name, "Test")
        XCTAssertEqual(track.id, 1)
    }
    
    func testStepStructure() {
        let step = Step()
        XCTAssertFalse(step.isActive)
        XCTAssertEqual(step.velocity, 1.0)
    }
}
