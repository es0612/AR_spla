import Testing
@testable import Domain

struct DomainTests {
    @Test("Domain package version is accessible")
    func testDomainVersion() {
        #expect(Domain.version == "1.0.0")
    }
}