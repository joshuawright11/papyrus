import Foundation

/// `Endpoint` is an abstraction around making REST requests. It
/// includes a `Request` type, representing the data needed to
/// make the request, and a `Response` type, representing the
/// expected response from the server.
///
/// `Endpoint`s are defined via property wrapped (@GET, @POST, etc...)
/// properties on an `EndpointGroup`.
///
/// `Endpoint`s are intended to be used on either client or server for
/// requesting external endpoints or on server for providing and
/// validating endpoints. There are partner libraries
/// (`PapyrusAlamofire` and `Alchemy`) for requesting or
/// validating endpoints on client or server platforms.
public struct Endpoint<Request: RequestConvertible, Response: Codable> {
    /// The method, or verb, of this endpoint.
    public let method: String
    
    /// The path of this endpoint, relative to `self.baseURL`
    public var path: String
    
    /// The `baseURL` of this endpoint.
    public var baseURL: String = ""
    
    /// Any `KeyMapping` of this endpoint.
    public var keyMapping: KeyMapping = .useDefaultKeys
    
    /// Used for encoding any JSON body of this endpoint's request.
    public var jsonEncoder: JSONEncoder = JSONEncoder()
    
    /// Used for decoding and JSON body of this endpoint's response.
    public var jsonDecoder: JSONDecoder = JSONDecoder()
    
    /// Any `EndpointGroup` level changes to make to the request.
    public var interceptor: ((inout HTTPComponents) -> Void)?
    
    /// Creates a copy of this `Endpoint` with the provided `baseURL`.
    ///
    /// - Parameter group: The EndpointGroup this `Endpoint` is apart
    ///   of.
    /// - Returns: A copy of this `Endpoint` configured for the
    ///   `EndpointGroup`.
    public func with(group: EndpointGroup) -> Self {
        var copy = self
        copy.baseURL = group.baseURL
        let keyMapping = group.keyMapping
        copy.keyMapping = keyMapping
        
        let encoder = group.jsonEncoder
        encoder.keyEncodingStrategy = keyMapping.jsonEncodingStrategy
        copy.jsonEncoder = encoder
        
        let decoder = group.jsonDecoder
        decoder.keyDecodingStrategy = keyMapping.jsonDecodingStrategy
        copy.jsonDecoder = decoder
        
        copy.interceptor = group.intercept
        return copy
    }
}

/// Indicates the type of a request's body. The content type affects
/// how and where the content is encoded.
public enum ContentEncoding {
    /// The content of this request is encoded to its body as JSON.
    case json
    /// The content of this request is encoded to its URL.
    case url
}

/// A type that can be the `Request` type of an `Endpoint`.
public protocol RequestConvertible: Codable {
    /// The method of encoding for the request body. Defaults to
    /// `.json`.
    static var contentEncoding: ContentEncoding { get }
    
    /// Initialize this request data from a `DecodableRequest`. Useful
    /// for loading expected request data from incoming requests on
    /// the provider of this `Endpoint`.
    ///
    /// - Parameter request: The request to initialize this type from.
    /// - Throws: Any error encountered while decoding this type from
    ///   the request.
    init(from request: DecodableRequest) throws
}

extension RequestConvertible {
    public static var contentEncoding: ContentEncoding { .json }
}

public protocol RequestBody: RequestConvertible, AnyBody {}

extension RequestBody {
    public var content: AnyEncodable { .init(self) }
    
    public init(from request: DecodableRequest) throws {
        self = try request.decodeContent(type: Self.contentEncoding)
    }
}

public protocol RequestComponents: RequestConvertible {}

extension RequestComponents {
    public init(from request: DecodableRequest) throws {
        try self.init(from: RequestDecoder(request: request))
    }
}

extension DecodableRequest {
    /// Decodes the given `RequestComponents` type from this request.
    ///
    /// - Parameter requestType: The type to decode. Defaults to
    ///   `E.self`.
    /// - Throws: An error encountered while decoding the type.
    /// - Returns: An instance of `E` decoded from this request.
    public func decodeRequest<E: RequestConvertible>(_ requestType: E.Type = E.self) throws -> E {
        try E(from: self)
    }
}
