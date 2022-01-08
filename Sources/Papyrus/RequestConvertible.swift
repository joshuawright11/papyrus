/// A type that can be the `Request` type of an `Endpoint`.
public protocol RequestConvertible: Codable {
    /// Initialize this request data from a `DecodableRequest`. Useful
    /// for loading expected request data from incoming requests on
    /// the provider of this `Endpoint`.
    ///
    /// - Parameter request: The request to initialize this type from.
    /// - Throws: Any error encountered while decoding this type from
    ///   the request.
    init(from request: RequestComponents, to endpoint: AnyEndpoint) throws
}

extension RequestConvertible {
    public init(from request: RequestComponents, to endpoint: AnyEndpoint) throws {
        try self.init(from: RequestDecoder(request: request, endpoint: endpoint))
    }
}
