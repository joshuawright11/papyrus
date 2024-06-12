import XCTest
@testable import Papyrus

final class ResponseTests: XCTestCase {
    func testValidate() {
        enum TestError: Error {
            case test
        }

        let res: PapyrusResponse = .error(TestError.test)
        XCTAssertThrowsError(try res.validate())
    }
}
