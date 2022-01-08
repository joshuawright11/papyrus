import Foundation

public protocol ContentConverter {
    func decode<D: Decodable>(_ type: D.Type, from: Data) throws -> D
    func encode<E: Encodable>(_ value: E) throws -> Data
    
    static var `default`: Self { get }
}
