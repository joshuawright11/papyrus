@testable import PapyrusCore
import XCTest

final class ResponseTests: XCTestCase {
    func testValidate() {
        enum TestError: Error {
            case test
        }

        let res: Response = .error(TestError.test)
        XCTAssertThrowsError(try res.validate())
    }
}
