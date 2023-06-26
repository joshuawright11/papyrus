import XCTest
@testable import Papyrus

final class ResponseDecoderTests: XCTestCase {
    func testWithKeyMappingDoesntMutate() throws {
        let decoder = JSONDecoder()

        switch decoder.keyDecodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        let snakeDecoder = decoder.with(keyMapping: .snakeCase)

        switch decoder.keyDecodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        switch snakeDecoder.keyDecodingStrategy {
        case .convertFromSnakeCase: break
        default: XCTFail("Should be snake_case keys")
        }
    }
}
