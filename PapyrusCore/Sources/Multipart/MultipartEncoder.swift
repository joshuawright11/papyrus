import Foundation

public struct MultipartEncoder: RequestEncoder {
    public var contentType: String { "multipart/form-data; boundary=\(boundary)" }
    public let boundary: String
    private let crlf = "\r\n"

    public init(boundary: String? = nil) {
        self.boundary = boundary ?? MultipartEncoder.randomBoundary()
    }

    public func with(keyMapping: KeyMapping) -> MultipartEncoder {
        // KeyMapping isn't relevant since each part has already encoded data.
        self
    }

    public func encode(_ value: some Encodable) throws -> Data {
        guard let parts = value as? [String: Part] else {
            preconditionFailure("Can only encode `[String: Part]` with `MultipartEncoder`.")
        }

        let initialBoundary = Data("--\(boundary)\(crlf)".utf8)
        let middleBoundary = Data("\(crlf)--\(boundary)\(crlf)".utf8)
        let finalBoundary = Data("\(crlf)--\(boundary)--\(crlf)".utf8)

        var body = Data()
        for (key, part) in parts {
            body += body.isEmpty ? initialBoundary : middleBoundary
            body += partHeaderData(part, key: key)
            body += part.data
        }

        return body + finalBoundary
    }

    private func partHeaderData(_ part: Part, key: String) -> Data {
        var disposition = "form-data; name=\"\(part.name ?? key)\""
        if let fileName = part.fileName {
            disposition += "; filename=\"\(fileName)\""
        }

        var headers = ["Content-Disposition": disposition]
        if let mimeType = part.mimeType {
            headers["Content-Type"] = mimeType
        }

        let string = headers.map { "\($0): \($1)\(crlf)" }.joined() + crlf
        return Data(string.utf8)
    }

    private static func randomBoundary() -> String {
        let first = UInt32.random(in: UInt32.min...UInt32.max)
        let second = UInt32.random(in: UInt32.min...UInt32.max)

        return String(format: "papyrus.boundary.%08x%08x", first, second)
    }
}
