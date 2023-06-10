import Foundation

public struct RawResponse {
    public let headers: [String: String]
    public let body: Data?
    
    private let contentConverter: ContentConverter
    
    init(headers: [String : String], body: Data?, contentConverter: ContentConverter) {
        self.headers = headers
        self.body = body
        self.contentConverter = contentConverter
    }
    
    // MARK: Decoding
    
    public func decodeContent<D: Decodable>(_ type: D.Type = D.self) throws -> D {
        guard let body = body else {
            throw PapyrusError("Tried to decode content from a response but the body was empty.")
        }
        
        return try contentConverter.decode(type, from: body)
    }
}
