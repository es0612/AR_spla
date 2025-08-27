import Testing
@testable import Infrastructure
import Domain
import Application

struct InfrastructureTests {
    @Test("Infrastructure package version is accessible")
    func testInfrastructureVersion() {
        #expect(Infrastructure.version == "1.0.0")
    }
    
    @Test("Infrastructure can access Domain layer")
    func testDomainAccess() {
        #expect(Domain.version == "1.0.0")
    }
    
    @Test("Infrastructure can access Application layer")
    func testApplicationAccess() {
        #expect(Application.version == "1.0.0")
    }
}