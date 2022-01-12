import Foundation

// Used for building a RawResponse.
public struct PartialResponse {
    // Data
    public let headers: [String: String]
    public var body: Data?
    
    // Converter
    public var preferredContentConverter: ContentConverter?
    private var _contentConverter: ContentConverter { preferredContentConverter ?? ConverterDefaults.content }
    public var contentConverter: ContentConverter { preferredKeyMapping.map { _contentConverter.with(keyMapping: $0) } ?? _contentConverter }
    
    public var preferredKeyMapping: KeyMapping?
    
    public init(headers: [String : String] = [:], body: Data? = nil) {
        self.headers = [:]
        self.body = body
        self.preferredContentConverter = nil
        self.preferredKeyMapping = nil
    }
    
    // MARK: Building
    
    public mutating func setBody<E: Encodable>(value: E) throws {
        self.body = try contentConverter.encode(value)
    }
    
    // MARK: Create
    
    public func create() -> RawResponse {
        var headers = headers
        headers["Content-Type"] = contentConverter.contentType
        headers["Content-Length"] = "\(body?.count ?? 0)"
        return RawResponse(headers: headers, body: body, contentConverter: contentConverter)
    }
}
