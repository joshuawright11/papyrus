import Foundation

// Used for building a RawRequest.
public struct PartialRequest {
    public enum BodyContent {
        public static var defaultConverter: ContentConverter = JSONConverter()
        
        case fields([String: AnyEncodable])
        case value(AnyEncodable)
        case data(Data)
    }
    
    public enum QueryContent {
        public static var defaultConverter: URLFormConverter = URLFormConverter()
        
        case string(String)
        case fields([String: AnyEncodable])
    }
    
    // Data
    public var method: String
    public var path: String
    public var parameters: [String: String]
    public var headers: [String: String]
    public var query: QueryContent?
    public var body: BodyContent?
    
    // Converters
    private var _contentConverter: ContentConverter
    public var contentConverter: ContentConverter {
        get { _contentConverter.with(keyMapping: keyMapping) }
        set { _contentConverter = newValue }
    }
    private var _queryConverter: URLFormConverter
    public var queryConverter: URLFormConverter {
        get { _queryConverter.with(keyMapping: keyMapping) }
        set { _queryConverter = newValue }
    }
    public var keyMapping: KeyMapping
    
    init() {
        self.method = "GET"
        self.path = "/"
        self._contentConverter = BodyContent.defaultConverter
        self._queryConverter = URLFormConverter()
        self.body = nil
        self.query = nil
        self.headers = [:]
        self.parameters = [:]
        self.keyMapping = .useDefaultKeys
    }
    
    // MARK: Building
    
    public mutating func setBody<E: Encodable>(_ value: E) {
        if let body = body {
            preconditionFailure("Tried to set an endpoint body to type \(E.self), but it already had one: \(body).")
        }
        
        body = .value(AnyEncodable(value))
    }
    
    public mutating func addQuery<E: Encodable>(_ key: String, value: E) {
        var fields: [String: AnyEncodable] = [:]
        if case .fields(let existingFields) = query {
            fields = existingFields
        }
        
        fields[key] = AnyEncodable(value)
        query = .fields(fields)
    }
    
    public mutating func addField<E: Encodable>(_ key: String, value: E) {
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
    
    // MARK: Create
    
    public func create(baseURL: String) throws -> RawRequest {
        RawRequest(method: method, baseURL: baseURL, path: try replacedPath(), headers: headers, parameters: parameters, query: try queryString(), body: try bodyData(), queryConverter: queryConverter, contentConverter: contentConverter)
    }
    
    private func bodyData() throws -> Data? {
        guard let body = body else { return nil }
        switch body {
        case .value(let value):
            return try contentConverter.encode(value)
        case .fields(let fields):
            return try contentConverter.encode(fields)
        case .data(let data):
            return data
        }
    }
    
    private func replacedPath() throws -> String {
        try parameters.reduce(into: path) { newPath, component in
            guard newPath.contains(":\(component.key)") else {
                throw PapyrusError("Tried to set path component `\(component.key)` but did not find `:\(component.key)` in \(path).")
            }
            
            newPath = newPath.replacingOccurrences(of: ":\(component.key)", with: component.value)
        }
    }
    
    private func queryString() throws -> String {
        guard let query = query else { return "" }
        switch query {
        case .fields(let fields):
            return try queryConverter.encode(fields).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        case .string(let string):
            return string
        }
    }
}
