import Testing
@testable import TestSupport
import Domain

struct TestSupportTests {
    @Test("TestSupport package version is accessible")
    func testTestSupportVersion() {
        #expect(TestSupport.version == "1.0.0")
    }
    
    @Test("TestSupport can access all layers")
    func testLayerAccess() {
        #expect(Domain.version == "1.0.0")
        // Additional layer access tests can be added here
    }
}