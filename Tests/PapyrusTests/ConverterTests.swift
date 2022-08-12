import XCTest
@testable import Papyrus

final class ConverterTests: XCTestCase {
    func testWithKeyMappingDoesntMutate() throws {
        let defaultConverter = JSONConverter()
        switch defaultConverter.encoder.keyEncodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        switch defaultConverter.decoder.keyDecodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        let snakeConverter = defaultConverter.with(keyMapping: .snakeCase)
        switch defaultConverter.encoder.keyEncodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        switch defaultConverter.decoder.keyDecodingStrategy {
        case .useDefaultKeys: break
        default: XCTFail("Should be default keys")
        }

        switch snakeConverter.encoder.keyEncodingStrategy {
        case .convertToSnakeCase: break
        default: XCTFail("Should be snake_case keys")
        }

        switch snakeConverter.decoder.keyDecodingStrategy {
        case .convertFromSnakeCase: break
        default: XCTFail("Should be snake_case keys")
        }
    }
}
