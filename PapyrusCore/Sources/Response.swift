import Foundation

public protocol Response {
    var body: Data? { get }
    var headers: [String: String]? { get }
    var statusCode: Int? { get }
    var error: Error? { get }
}

extension Response {
    @discardableResult
    public func validate() throws -> Self {
        if let statusCode {
            guard (200..<300).contains(statusCode) else {
                throw PapyrusError("Unsuccessful status code: \(statusCode).")
            }
        }
        
        guard let error else {
            return self
        }
        
        throw error
    }

    public func decode<D: Decodable>(_ type: D.Type = D.self, using decoder: ResponseDecoder) throws -> D {
        try validate()

        guard let data = body else {
            throw PapyrusError("Unable to decode `\(Self.self)` from a `Response`; body was nil.")
        }

        return try decoder.decode(type, from: data)
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
