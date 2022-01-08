import Foundation

public enum EndpointContent {
    public static var defaultConverter: ContentConverter = JSONConverter()
    
    case fields([String: AnyEncodable])
    case codable(AnyEncodable)
}

/// Erased Endpoint
public protocol AnyEndpoint {
    var method: String { get set }
    var baseURL: String { get set }
    var path: String { get set }
    var headers: [String: String] { get set }
    var parameters: [String: String] { get set }
    var queries: [String: AnyEncodable] { get set }
    var body: EndpointContent? { get set }
    
    var converter: ContentConverter { get set }
    var queryConverter: URLFormConverter { get set }
    var keyMapping: KeyMapping? { get set }
}

extension AnyEndpoint {
    mutating func setBody<E: Encodable>(_ value: E) {
        if let body = body {
            preconditionFailure("Tried to set an endpoint body to type \(E.self), but it already had one: \(body).")
        }
        
        body = .codable(AnyEncodable(value))
    }
    
    mutating func addField<E: Encodable>(_ key: String, value: E) {
        var fields: [String: AnyEncodable] = [:]
        if let body = body {
            guard case .fields(let existingFields) = body else {
                preconditionFailure("Tried to add a field, \(key): \(E.self), to an endpoint, but it already had a body, \(body). @Body and @Field are mutually exclusive.")
            }
            
            fields = existingFields
        }
        
        fields[key] = AnyEncodable(value)
        body = .fields(fields)
    }
}

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
public struct Endpoint<Request: EndpointRequest, Response: Codable>: AnyEndpoint {
    struct Payload {
        let method: String
        let url: String
        let headers: [String: String]
        let body: Data?
    }
    
    /// The method, or verb, of this endpoint.
    public var method: String = ""
    /// The `baseURL` of this endpoint.
    public var baseURL: String = ""
    /// The path of this endpoint, relative to `self.baseURL`
    public var path: String = ""
    /// Endpoint headers
    public var headers: [String: String] = [:]
    /// Path parameters
    public var parameters: [String: String] = [:]
    /// Endpoint queries
    public var queries: [String: AnyEncodable] = [:]
    /// Body content
    public var body: EndpointContent?
    
    /// Converter for this endpoints data fields.
    public var converter: ContentConverter {
        get { keyMapping.map { _converter.with(keyMapping: $0) } ?? _converter }
        set { _converter = newValue }
    }
    
    private var _converter: ContentConverter = EndpointContent.defaultConverter
    
    /// Converter for this endpoints data fields.
    public var queryConverter: URLFormConverter {
        get { keyMapping.map { _queryConverter.with(keyMapping: $0) } ?? _queryConverter }
        set { _queryConverter = newValue }
    }
    
    public var _queryConverter = URLFormConverter()
    
    /// Any `KeyMapping` of this endpoint, applied to body and query fields.
    public var keyMapping: KeyMapping?
    
    func payload(with req: Request) throws -> Payload {
        try applying(req)._payload()
    }
    
    private func applying<R: EndpointRequest>(_ value: R) -> Endpoint<Request, Response> {
        let properties: [(label: String, value: Any)] = Mirror(reflecting: value).children.compactMap {
            guard let label = $0.label else { return nil }
            return (label, $0.value)
        }
        
        let modifierProperties: [(String, RequestModifier)] = properties.compactMap { child in
            guard let modifier = child.value as? RequestModifier else { return nil }
            return (child.label, modifier)
        }
        
        let otherProperties: [(String, Any)] = properties.compactMap { child in
            guard !(child.value is RequestModifier) else { return nil }
            return (child.label, child.value)
        }

        var result: Endpoint<Request, Response> = self
        if !modifierProperties.isEmpty && otherProperties.isEmpty {
            for (label, property) in modifierProperties {
                // Remove _ from property wrappers.
                let cleanedLabel = String(label.dropFirst())
                property.modify(endpoint: &result, for: cleanedLabel)
            }
        } else if modifierProperties.isEmpty && !otherProperties.isEmpty {
            result.setBody(value)
        } else if !modifierProperties.isEmpty && !otherProperties.isEmpty {
            preconditionFailure("For now, can't have both `RequestModifers` and other properties on RequestConvertible type \(R.self).")
        }
        
        return result
    }
    
    private func _payload() throws -> Payload {
        Payload(
            method: method,
            url: try baseURL + pathWithQueryString(),
            headers: headers,
            body: try bodyData())
    }
    
    private func pathWithQueryString() throws -> String {
        let replacedPath = try replacedPath(path)
        var queryPrefix = replacedPath.contains("?") ? "&" : "?"
        if replacedPath.last == "?" { queryPrefix = "" }
        return try replacedPath + queryPrefix + queryString()
    }
    
    private func replacedPath(_ basePath: String) throws -> String {
        try parameters.reduce(into: basePath) { newPath, component in
            guard newPath.contains(":\(component.key)") else {
                throw PapyrusError("Tried to encode path component `\(component.key)` but did not find any instance of `:\(component.key)` in \(basePath).")
            }
            
            newPath = newPath.replacingOccurrences(of: ":\(component.key)", with: component.value)
        }
    }
    
    private func queryString() throws -> String {
        try queryConverter.encoder.encode(queries).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
    private func bodyData() throws -> Data? {
        guard let body = body else { return nil }
        switch body {
        case .codable(let value):
            return try converter.encode(value)
        case .fields(let fields):
            return try converter.encode(fields)
        }
    }
}

extension Endpoint {
    /// Decodes the given `RequestComponents` type from this request.
    ///
    /// - Parameter requestType: The type to decode. Defaults to
    ///   `E.self`.
    /// - Throws: An error encountered while decoding the type.
    /// - Returns: An instance of `E` decoded from this request.
    public func decodeRequest(components: RequestComponents) throws -> Request {
        try Request(from: components, to: self)
    }
}
