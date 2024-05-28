import Foundation

public struct RequestBuilder {
    public struct AuthorizationHeader {
        public let value: String

        public init(value: String) {
            self.value = value
        }

        public static func bearer(_ token: String) -> AuthorizationHeader {
            AuthorizationHeader(value: "Bearer \(token)")
        }

        public static func basic(username: String, password: String) -> AuthorizationHeader {
            let unencoded = username + ":" + password
            let base64Encoded = Data(unencoded.utf8).base64EncodedString()
            return AuthorizationHeader(value: "Basic \(base64Encoded)")
        }
    }

    public enum ContentKey: Hashable, ExpressibleByStringLiteral {
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
                guard let keyMapping else { return value }
                return keyMapping.encode(value)
            }
        }
    }

    public struct ContentValue: Encodable {
        private let _encode: (Encoder) throws -> Void

        public init<T: Encodable>(_ wrapped: T) {
            _encode = wrapped.encode
        }

        // MARK: Encodable

        public func encode(to encoder: Encoder) throws {
            try _encode(encoder)
        }
    }

    public enum Content {
        case value(ContentValue)
        case fields([ContentKey: ContentValue])
        case multipart([ContentKey: Part])
    }

    // MARK: Data

    public var baseURL: String
    public var method: String
    public var path: String
    public var parameters: [String: String]
    public var headers: [String: String]
    public var queries: [ContentKey: ContentValue]
    public var body: Content?

    // MARK: Configuration

    public var keyMapping: KeyMapping?

    public var queryEncoder: URLEncodedFormEncoder {
        set { _queryEncoder = newValue }
        get { _queryEncoder.with(keyMapping: keyMapping) }
    }

    public var requestBodyEncoder: HTTPBodyEncoder {
        set { _requestBodyEncoder = newValue }
        get { _requestBodyEncoder.with(keyMapping: keyMapping) }
    }

    public var responseBodyDecoder: HTTPBodyDecoder {
        set { _responseBodyDecoder = newValue }
        get { _responseBodyDecoder.with(keyMapping: keyMapping) }
    }

    private var _queryEncoder: URLEncodedFormEncoder = Coders.defaultQueryEncoder
    private var _requestBodyEncoder: HTTPBodyEncoder = Coders.defaultHTTPBodyEncoder
    private var _responseBodyDecoder: HTTPBodyDecoder = Coders.defaultHTTPBodyDecoder

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

    public mutating func addParameter<L: LosslessStringConvertible>(_ key: String, value: L) {
        parameters[key] = value.description
    }

    public mutating func addParameter<L: LosslessStringConvertible, R: RawRepresentable<L>>(_ key: String, value: R) {
        parameters[key] = value.rawValue.description
    }

    public mutating func addQuery<E: Encodable>(_ key: String, value: E?, mapKey: Bool = true) {
        guard let value else { return }
        let key: ContentKey = mapKey ? .implicit(key) : .explicit(key)
        queries[key] = ContentValue(value)
    }

    public mutating func addHeaders(_ headerDict: [String: String]) {
        for (key, value) in headerDict {
            addHeader(key, value: value, convertToHeaderCase: false)
        }
    }

    public mutating func addHeader<L: LosslessStringConvertible>(_ key: String, value: L?, convertToHeaderCase: Bool = true) {
        guard let value else { return }
        let key = convertToHeaderCase ? key.httpHeaderCase() : key
        headers[key] = value.description
    }

    public mutating func addAuthorization(_ header: AuthorizationHeader) {
        headers["Authorization"] = header.value
    }

    public mutating func setBody<E: Encodable>(_ value: E) {
        if let body = body {
            preconditionFailure("Tried to set a request @Body to type \(E.self), but it already had one: \(body).")
        }

        body = .value(ContentValue(value))
    }

    public mutating func addField(_ key: String, value: Part, mapKey: Bool = true) {
        var parts: [ContentKey: Part] = [:]
        if let body = body {
            guard case .multipart(let existingParts) = body else {
                preconditionFailure("Tried to add a multipart Part, \(key), to a request but it already had non multipart fields added to it. If you use @Multipart, all fields on the request must be of type Part.")
            }

            parts = existingParts
        }

        let key: ContentKey = mapKey ? .implicit(key) : .explicit(key)
        parts[key] = value
        body = .multipart(parts)
    }

    public mutating func addField<E: Encodable>(_ key: String, value: E, mapKey: Bool = true) {
        var fields: [ContentKey: ContentValue] = [:]
        if let body = body {
            guard case .fields(let existingFields) = body else {
                preconditionFailure("Tried to add a Field, \(key): \(E.self), to a request, but it already had Body or Multipart parameters, \(body). Body, Field, and Multipart are mutually exclusive.")
            }
            
            fields = existingFields
        }

        let key: ContentKey = mapKey ? .implicit(key) : .explicit(key)
        fields[key] = ContentValue(value)
        body = .fields(fields)
    }
    
    // MARK: Creating Request Parts

    public func fullURL() throws -> URL {
        let trailingSlash = baseURL.last == "/" ? "" : "/"
        let urlString = try baseURL + trailingSlash + parameterizedPath() + queryString()
        guard let url = URL(string: urlString) else {
            throw PapyrusError("Invalid URL: \(urlString)")
        }

        return url
    }

    public func bodyAndHeaders() throws -> (Data?, [String: String]) {
        let body = try bodyData()
        var headers = headers
        headers["Content-Type"] = requestBodyEncoder.contentType
        headers["Content-Length"] = "\(body?.count ?? 0)"
        return (body, headers)
    }

    private func parameterizedPath() throws -> String {
        var pathComponents = path.split(separator: "/")
        var staticQuery: Substring? = nil

        if let lastComponent = pathComponents.last, let startOfQuery = lastComponent.lastIndex(of: "?") {
            pathComponents.removeLast()
            staticQuery = lastComponent.suffix(from: startOfQuery)
            pathComponents.append(lastComponent.prefix(upTo: startOfQuery))
        }

        return try parameters.reduce(into: pathComponents) { newPath, component in
            let colonEscapedIndex = newPath.firstIndex(of: ":\(component.key)")
            let curlyEscapedIndex = newPath.firstIndex(of: "{\(component.key)}")
            guard let index = colonEscapedIndex ?? curlyEscapedIndex else {
                throw PapyrusError("Tried to set path parameter `\(component.key)` but did not find `:\(component.key)` or `{\(component)}` in path `\(path)`.")
            }

            newPath[index] = component.value[...]
        }.joined(separator: "/") + (staticQuery ?? "")
    }

    private func bodyData() throws -> Data? {
        switch body {
        case .none:
            return nil
        case .value(let value):
            return try requestBodyEncoder.encode(value)
        case .multipart(let fields):
            let pairs = fields.map { ($0.mapped(keyMapping), $1) }
            let dict = Dictionary(uniqueKeysWithValues: pairs)
            return try requestBodyEncoder.encode(dict)
        case .fields(let fields):
            let pairs = fields.map { ($0.mapped(keyMapping), $1) }
            let dict = Dictionary(uniqueKeysWithValues: pairs)
            return try requestBodyEncoder.encode(dict)
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

        let pairs = queries.map { ($0.mapped(keyMapping), $1) }
        let dict = Dictionary(uniqueKeysWithValues: pairs)
        return try prefix + queryEncoder.encode(dict)
    }
}

extension String {
    /// Converts a `camelCase` String to `Http-Header-Case`.
    fileprivate func httpHeaderCase() -> String {
        let snakeCase = KeyMapping.snakeCase.encode(self)
        let kebabCase = snakeCase
            .components(separatedBy: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: "-")
        return kebabCase
    }
}
