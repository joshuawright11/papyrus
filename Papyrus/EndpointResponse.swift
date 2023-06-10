/// A type that can be the `Response` of an `Endpoint`.
public protocol EndpointResponse: Codable {
    init(from response: RawResponse) throws
}

extension EndpointResponse {
    public init(from response: RawResponse) throws {
        self = try response.decodeContent(Self.self)
    }
}
