import Foundation

public struct RequestBuilder {
    public enum BodyContent {
        case fields([String: AnyEncodable])
        case value(AnyEncodable)
    }

    public static var defaultQueryEncoder: URLEncodedFormEncoder = URLEncodedFormEncoder()
    public static var defaultRequestEncoder: RequestEncoder = JSONEncoder()
    public static var defaultResponseDecoder: ResponseDecoder = JSONDecoder()

    // MARK: Data

    public var method: String
    public var path: String
    public var parameters: [String: String]
    public var headers: [String: String]
    public var query: [String: AnyEncodable]
    public var body: BodyContent?

    // MARK: Configuration

    public var keyMapping: KeyMapping?

    public var queryEncoder: URLEncodedFormEncoder {
        set { _queryEncoder = newValue }
        get { _queryEncoder.with(keyMapping: keyMapping) }
    }

    public var requestEncoder: RequestEncoder {
        set { _requestEncoder = newValue }
        get { _requestEncoder.with(keyMapping: keyMapping) }
    }

    public var responseDecoder: ResponseDecoder {
        set { _responseDecoder = newValue }
        get { _responseDecoder.with(keyMapping: keyMapping) }
    }

    private var _queryEncoder: URLEncodedFormEncoder = defaultQueryEncoder
    private var _requestEncoder: RequestEncoder = defaultRequestEncoder
    private var _responseDecoder: ResponseDecoder = defaultResponseDecoder

    public init(method: String, path: String) {
        self.method = method
        self.path = path
        self.parameters = [:]
        self.headers = [:]
        self.query = [:]
        self.body = nil
    }
    
    // MARK: Building

    public mutating func addHeaders(_ headerDict: [String: String]) {
        for (key, value) in headerDict {
            addHeader(key, value: value, convertToHeaderCase: false)
        }
    }

    public mutating func addHeader<L: LosslessStringConvertible>(_ key: String, value: L, convertToHeaderCase: Bool = true) {
        let key = convertToHeaderCase ? key.httpHeaderCase() : key
        headers[key] = value.description
    }

    public mutating func addAuthorization(_ header: AuthorizationHeader) {
        headers["Authorization"] = header.value
    }

    public mutating func addParameter<L: LosslessStringConvertible>(_ key: String, value: L) {
        parameters[key] = value.description
    }

    public mutating func setBody<E: Encodable>(_ value: E) {
        if let body = body {
            preconditionFailure("Tried to set a request @Body to type \(E.self), but it already had one: \(body).")
        }
        
        body = .value(AnyEncodable(value))
    }
    
    public mutating func addQuery<E: Encodable>(_ key: String, value: E) {
        query[key] = AnyEncodable(value)
    }
    
    public mutating func addField<E: Encodable>(_ key: String, value: E) {
        var fields: [String: AnyEncodable] = [:]
        if let body = body {
            guard case .fields(let existingFields) = body else {
                preconditionFailure("Tried to add a @Field, \(key): \(E.self), to a request, but it already had a @Body, \(body). @Body and @Field are mutually exclusive.")
            }
            
            fields = existingFields
        }
        
        fields[key] = AnyEncodable(value)
        body = .fields(fields)
    }
    
    // MARK: Creating Request Parts

    public func fullURL(baseURL: String) throws -> String {
        try baseURL + parameterizedPath() + queryString()
    }

    public func bodyAndHeaders() throws -> (Data?, [String: String]) {
        let body = try bodyData()
        var headers = headers
        headers["Content-Type"] = requestEncoder.contentType
        headers["Content-Length"] = "\(body?.count ?? 0)"
        return (body, headers)
    }

    private func parameterizedPath() throws -> String {
        try parameters.reduce(into: path) { newPath, component in
            guard newPath.contains(":\(component.key)") else {
                throw PapyrusError("Tried to set path component `\(component.key)` but did not find `:\(component.key)` in \(path).")
            }

            newPath = newPath.replacingOccurrences(of: ":\(component.key)", with: component.value)
        }
    }

    private func bodyData() throws -> Data? {
        switch body {
        case .none:
            return nil
        case .value(let value):
            return try requestEncoder.encode(value)
        case .fields(let fields):
            if requestEncoder is JSONEncoder, let keyMapping {
                // JSONEncoder doesn't map dict keys with the preferred key
                // mapping when encoding. We'll need to manually do it.
                let mappedFields = Dictionary(uniqueKeysWithValues: fields.map { (keyMapping.mapTo(input: $0), $1) })
                return try requestEncoder.encode(mappedFields)
            } else {
                return try requestEncoder.encode(fields)
            }
        }
    }
    
    private func queryString() throws -> String {
        guard !query.isEmpty else {
            return ""
        }

        var prefix = path.contains("?") ? "&" : "?"
        if path.last == "?" {
            prefix = ""
        }

        return try prefix + queryEncoder.encode(query)
    }
}

extension KeyMappable {
    fileprivate func with(keyMapping: KeyMapping?) -> Self {
        guard let keyMapping else {
            return self
        }

        return with(keyMapping: keyMapping)
    }
}

extension String {
    /// Converts a `camelCase` String to `Http-Header-Case`.
    fileprivate func httpHeaderCase() -> String {
        let snakeCase = KeyMapping.snakeCase.mapTo(input: self)
        let kebabCase = snakeCase
            .components(separatedBy: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: "-")
        return kebabCase
    }
}
