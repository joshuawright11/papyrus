import Foundation

// Used for building a RawResponse.
public struct PartialResponse {
    // Data
    public let headers: [String: String]
    public var body: Data?
    
    // Converter
    private var _contentConverter: ContentConverter
    public var contentConverter: ContentConverter {
        get { _contentConverter.with(keyMapping: keyMapping) }
        set { _contentConverter = newValue }
    }
    public var keyMapping: KeyMapping
    
    public init(headers: [String : String] = [:], body: Data? = nil) {
        self.headers = [:]
        self.body = body
        self._contentConverter = PartialRequest.defaultContentConverter
        self.keyMapping = .useDefaultKeys
    }
    
    // MARK: Building
    
    public mutating func setBody<E: Encodable>(value: E) throws {
        self.body = try contentConverter.encode(value)
    }
    
    // MARK: Create
    
    public func create() -> RawResponse {
        RawResponse(headers: headers, body: body, contentConverter: contentConverter)
    }
}
