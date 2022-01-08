import Foundation

public struct RawRequest {
    public let method: String
    public let baseURL: String
    public let path: String
    public let headers: [String: String]
    public let parameters: [String: String]
    public let query: String
    public let body: Data?
    
    private let queryConverter: URLFormConverter
    private let contentConverter: ContentConverter
    
    init(method: String, baseURL: String, path: String, headers: [String : String], parameters: [String : String], query: String, body: Data?, queryConverter: URLFormConverter, contentConverter: ContentConverter) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.headers = headers
        self.parameters = parameters
        self.query = query
        self.body = body
        self.queryConverter = queryConverter
        self.contentConverter = contentConverter
    }
    
    // MARK: URL
    
    public func fullURL(base baseURL: String) throws -> String {
        var queryPrefix = path.contains("?") ? "&" : "?"
        if path.last == "?" { queryPrefix = "" }
        return baseURL + path + queryPrefix + query
    }
    
    // MARK: Decoding
    
    public func decodeContent<D: Decodable>(_ type: D.Type = D.self) throws -> D {
        guard let body = body else { throw PapyrusError("Tried to decode content from a request but the body was empty.") }
        return try contentConverter.decode(type, from: body)
    }
    
    public func decodeQuery<D: Decodable>(_ type: D.Type = D.self) throws -> D {
        try queryConverter.decode(type, from: query)
    }
}
