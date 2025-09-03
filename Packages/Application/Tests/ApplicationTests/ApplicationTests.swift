@testable import Application
import Domain
import Testing

struct ApplicationTests {
    @Test("Application package version is accessible")
    func testApplicationVersion() {
        #expect(Application.version == "1.0.0")
    }

    @Test("Application can access Domain layer")
    func testDomainAccess() {
        #expect(Domain.version == "1.0.0")
    }
}
