import XCTest
@testable import Papyrus

final class RequestEncoderTests: XCTestCase {
    func testWithKeyMappingDoesntMutate() throws {
        let encoder = JSONEncoder()
        let snakeEncoder = encoder.with(keyMapping: .snakeCase)

        switch encoder.keyEncodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        switch snakeEncoder.keyEncodingStrategy {
        case .convertToSnakeCase: break
        default: XCTFail("Should be snake_case keys")
        }
    }
}
