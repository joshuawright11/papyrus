import Foundation

public protocol Response {
    var body: Data? { get }
    var headers: [String: String]? { get }
    var statusCode: Int? { get }
    var error: Error? { get }
}

extension Response {
    /// Validates the status code of a Response, as well as any transport errors that may have occurred.
    @discardableResult
    public func validate() throws -> Self {
        if let error { throw error }
        if let statusCode, !(200..<300).contains(statusCode) { throw PapyrusError("Unsuccessful status code: \(statusCode).") }
        return self
    }
    
    public func decode(_ type: Data?.Type = Data?.self, using decoder: ResponseDecoder) throws -> Data? {
        try validate().body
    }
    
    public func decode(_ type: Data.Type = Data.self, using decoder: ResponseDecoder) throws -> Data {
        guard let body = try decode(Data?.self, using: decoder) else {
            throw PapyrusError("Unable to return the body of a `Response`; the body was nil.")
        }
        
        return body
    }
    
    public func decode<D: Decodable>(_ type: D.Type = D.self, using decoder: ResponseDecoder) throws -> D {
        guard let body = try validate().body else {
            throw PapyrusError("Unable to decode `\(Self.self)` from a `Response`; body was nil.")
        }
        
        return try decoder.decode(type, from: body)
    }
}

extension Response where Self == ErrorResponse {
    public static func error(_ error: Error) -> Response {
        ErrorResponse(error)
    }
}

public struct ErrorResponse: Response {
    let _error: Error?

    public init(_ error: Error) {
        self._error = error
    }

    public var body: Data? { nil }
    public var headers: [String : String]? { nil }
    public var statusCode: Int? { nil }
    public var error: Error? { _error }
}
