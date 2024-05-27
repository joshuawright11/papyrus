import XCTest
@testable import Papyrus

final class KeyMappingTests: XCTestCase {
    private let pairs = [
        "fooBar": "foo_bar",
        "foo1": "foo1",
        "fooBarBaz": "foo_bar_baz",
        "_bar_": "_bar_"
    ]

    func testCustom() {
        let custom = KeyMapping.custom(to: { $0 + "_" }, from: { "_" + $0 })
        for (one, two) in pairs {
            XCTAssertEqual(custom.encode(one), one + "_")
            XCTAssertEqual(custom.encode(two), two + "_")
            XCTAssertEqual(custom.decode(one), "_" + one)
            XCTAssertEqual(custom.decode(two), "_" + two)
        }
    }

    func testSnakeCase() {
        let snake = KeyMapping.snakeCase
        for (one, two) in pairs {
            XCTAssertEqual(snake.encode(one), two)
            XCTAssertEqual(snake.decode(two), one)
        }

        XCTAssertEqual(snake.encode("testJSON"), "test_json")
    }

    func testDefault() {
        let `default` = KeyMapping.useDefaultKeys
        for (one, two) in pairs {
            XCTAssertEqual(`default`.encode(one), one)
            XCTAssertEqual(`default`.encode(two), two)
            XCTAssertEqual(`default`.decode(one), one)
            XCTAssertEqual(`default`.decode(two), two)
        }
    }
}
