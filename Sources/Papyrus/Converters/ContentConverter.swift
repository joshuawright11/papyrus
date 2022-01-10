import Foundation

public protocol ContentConverter {
    var contentType: String { get }
    func decode<D: Decodable>(_ type: D.Type, from: Data) throws -> D
    func encode<E: Encodable>(_ value: E) throws -> Data
    func with(keyMapping: KeyMapping) -> Self
}
