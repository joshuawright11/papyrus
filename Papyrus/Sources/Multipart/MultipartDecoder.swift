import Foundation

public struct MultipartDecoder: HTTPBodyDecoder {
    public let boundary: String

    public init(boundary: String? = nil) {
        self.boundary = boundary ?? .randomMultipartBoundary()
    }

    public func with(keyMapping: KeyMapping) -> MultipartDecoder {
        // KeyMapping isn't relevant since each part has already encoded data.
        self
    }

    public func decode<D>(_ type: D.Type, from: Data) throws -> D where D: Decodable {
        fatalError("multipart decoding isn't supported, yet")
    }
}
