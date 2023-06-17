import Foundation

public struct RequestBuilder {
    public enum FieldKey: Hashable, ExpressibleByStringLiteral {
        /// The key was explicitly defined by the user, i.e.
        /// `@Path("explicit-key") key: String`. It won't
        /// be affected by custom KeyMapping.
        case explicit(String)
        /// The key was implied defined by the parameter label, i.e.
        /// `@Path implicitKey: String`. It will be affected by
        /// custom `KeyMapping`.
        case implicit(String)

        public init(stringLiteral value: String) {
            self = .explicit(value)
        }

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .explicit(let value):
                hasher.combine(value)
            case .implicit(let value):
                hasher.combine(value)
            }
        }

        fileprivate func mapped(_ keyMapping: KeyMapping?) -> String {
            switch self {
            case .explicit(let value):
                return value
            case .implicit(let value):
                guard let keyMapping else {
                    return value
                }

                return keyMapping.mapTo(input: value)
            }
        }
    }

    public enum Content {
        case fields([FieldKey: AnyEncodable])
        case value(AnyEncodable)
    }

    public static var defaultQueryEncoder: URLEncodedFormEncoder = URLEncodedFormEncoder()
    public static var defaultRequestEncoder: RequestEncoder = JSONEncoder()
    public static var defaultResponseDecoder: ResponseDecoder = JSONDecoder()

    // MARK: Data

    public var baseURL: String
    public var method: String
    public var path: String
    public var parameters: [String: String]
    public var headers: [String: String]
    public var queries: [FieldKey: AnyEncodable]
    public var body: Content?

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

    public init(baseURL: String, method: String, path: String) {
        self.baseURL = baseURL
        self.method = method
        self.path = path
        self.parameters = [:]
        self.headers = [:]
        self.queries = [:]
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
    
    public mutating func addQuery<E: Encodable>(_ key: String, value: E, mapKey: Bool = true) {
        let key: FieldKey = mapKey ? .implicit(key) : .explicit(key)
        queries[key] = AnyEncodable(value)
    }
    
    public mutating func addField<E: Encodable>(_ key: String, value: E, mapKey: Bool = true) {
        var fields: [FieldKey: AnyEncodable] = [:]
        if let body = body {
            guard case .fields(let existingFields) = body else {
                preconditionFailure("Tried to add a @Field, \(key): \(E.self), to a request, but it already had a @Body, \(body). @Body and @Field are mutually exclusive.")
            }
            
            fields = existingFields
        }

        let key: FieldKey = mapKey ? .implicit(key) : .explicit(key)
        fields[key] = AnyEncodable(value)
        body = .fields(fields)
    }
    
    // MARK: Creating Request Parts

    public func fullURL() throws -> URL {
        let urlString = try baseURL + parameterizedPath() + queryString()
        guard let url = URL(string: urlString) else {
            throw PapyrusError("Invalid URL: \(urlString)")
        }

        return url
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
            var dict: [String: AnyEncodable] = [:]
            for (key, value) in fields {
                dict[key.mapped(keyMapping)] = value
            }

            return try requestEncoder.encode(dict)
        }
    }
    
    private func queryString() throws -> String {
        guard !queries.isEmpty else {
            return ""
        }

        var prefix = path.contains("?") ? "&" : "?"
        if path.last == "?" {
            prefix = ""
        }

        var dict: [String: AnyEncodable] = [:]
        for (key, value) in queries {
            dict[key.mapped(keyMapping)] = value
        }

        return try prefix + queryEncoder.encode(dict)
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
