import Foundation

public protocol PapyrusResponse {
    var request: PapyrusRequest? { get }
    var body: Data? { get }
    var headers: [String: String]? { get }
    var statusCode: Int? { get }
    var error: Error? { get }
}

extension PapyrusResponse {
    /// Validates the status code of a Response, as well as any transport errors that may have occurred.
    @discardableResult
    public func validate() throws -> Self {
        if let error { throw error }
        if let statusCode, !(200..<300).contains(statusCode) { throw makePapyrusError(with: "Unsuccessful status code: \(statusCode).") }
        return self
    }
    
    public func decode(_ type: Data?.Type = Data?.self, using decoder: HTTPBodyDecoder) throws -> Data? {
        try validate().body
    }
    
    public func decode(_ type: Data.Type = Data.self, using decoder: HTTPBodyDecoder) throws -> Data {
        guard let body = try decode(Data?.self, using: decoder) else {
            throw makePapyrusError(with: "Unable to return the body of a `Response`; the body was nil.")
        }
        
        return body
    }
    
    public func decode<D: Decodable>(_ type: D?.Type = D?.self, using decoder: HTTPBodyDecoder) throws -> D? {
        guard let body, !body.isEmpty else {
            return nil
        }
        
        return try decoder.decode(type, from: body)
    }
    
    public func decode<D: Decodable>(_ type: D.Type = D.self, using decoder: HTTPBodyDecoder) throws -> D {
        guard let body else {
            throw makePapyrusError(with: "Unable to decode `\(Self.self)` from a `Response`; body was nil.")
        }
        
        return try decoder.decode(type, from: body)
    }
    
    private func makePapyrusError(with message: String) -> PapyrusError {
        PapyrusError(message, request, self)
    }
}

extension PapyrusResponse where Self == ErrorResponse {
    public static func error(_ error: Error) -> PapyrusResponse {
        ErrorResponse(error)
    }
}

public struct ErrorResponse: PapyrusResponse {
    let _error: Error?

    public init(_ error: Error) {
        self._error = error
    }

    public var request: PapyrusRequest? { nil }
    public var body: Data? { nil }
    public var headers: [String : String]? { nil }
    public var statusCode: Int? { nil }
    public var error: Error? { _error }
}
