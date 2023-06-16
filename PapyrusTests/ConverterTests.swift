import XCTest
@testable import Papyrus

final class ConverterTests: XCTestCase {
    func testWithKeyMappingDoesntMutate() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        switch encoder.keyEncodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        switch decoder.keyDecodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        let snakeEncoder = encoder.with(keyMapping: .snakeCase)
        let snakeDecoder = decoder.with(keyMapping: .snakeCase)

        switch encoder.keyEncodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        switch decoder.keyDecodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        switch snakeEncoder.keyEncodingStrategy {
        case .convertToSnakeCase: break
        default: XCTFail("Should be snake_case keys")
        }

        switch snakeDecoder.keyDecodingStrategy {
        case .convertFromSnakeCase: break
        default: XCTFail("Should be snake_case keys")
        }
    }
}
