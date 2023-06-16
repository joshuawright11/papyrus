import Foundation

public protocol RequestEncoder: KeyMappable {
    var contentType: String { get }
    func encode<E: Encodable>(_ value: E) throws -> Data
}

extension RequestEncoder where Self == JSONEncoder {
    public static func json(_ encoder: JSONEncoder) -> Self {
        encoder
    }
}

extension RequestEncoder where Self == URLEncodedFormEncoder {
    public static func urlForm(_ encoder: URLEncodedFormEncoder) -> Self {
        encoder
    }
}

extension URLEncodedFormEncoder: RequestEncoder {
    public var contentType: String { "application/x-www-form-urlencoded" }

    public func encode<E: Encodable>(_ value: E) throws -> Data {
        let string: String = try encode(value)
        guard let data = string.data(using: .utf8) else {
            throw PapyrusError("URLEncoded string wasn't convertible to utf8 data.")
        }

        return data
    }

    public func with(keyMapping: KeyMapping) -> Self {
        var copy = self
        copy.keyMapping = keyMapping
        return copy
    }
}

extension JSONEncoder: RequestEncoder {
    public var contentType: String { "application/json" }

    public func with(keyMapping: KeyMapping) -> Self {
        let copy = copy()
        copy.keyEncodingStrategy = keyMapping.jsonEncodingStrategy
        return copy as! Self
    }
}

extension JSONEncoder {
    fileprivate func copy() -> JSONEncoder {
        let new = JSONEncoder()
        new.keyEncodingStrategy = keyEncodingStrategy
        new.userInfo = userInfo
        new.dataEncodingStrategy = dataEncodingStrategy
        new.dateEncodingStrategy = dateEncodingStrategy
        new.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        new.outputFormatting = outputFormatting
        return new
    }
}
