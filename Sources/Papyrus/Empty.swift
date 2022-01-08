/// Represents an Empty request or response on an `Endpoint`.
///
/// A workaround for not being able to conform `Void` to `Codable`.
public struct Empty: EndpointRequest, EndpointResponse {
    /// Static `Empty` instance used for all `Empty` responses and
    /// requests.
    public static let value = Empty()
    
    public init() {}
    public init(from request: RawRequest) throws {}
    public init(from raw: RawResponse) throws {}
}
