import Foundation
import Papyrus


typealias ArrayRequest = [Foo]
extension ArrayRequest: TestableRequest, EndpointRequest {
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        let body = try contentConverter.encode(expected)
        return RawTestRequest(
            headers: [
                "Content-Type": contentConverter.contentType,
                "Content-Length": String(body.count)
            ], body: body)
    }
    
    static let expected: [Foo] = [
        Foo(string: "foo", int: 0),
        Foo(string: "bar", int: 1),
        Foo(string: "baz", int: 2),
        Foo(string: "tiz", int: 3),
    ]
}

struct Foo: Codable, Equatable {
    var string: String
    var int: Int
}
