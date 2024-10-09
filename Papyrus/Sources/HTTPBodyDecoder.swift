import Foundation

public protocol HTTPBodyDecoder: KeyMappable {
    func decode<D: Decodable>(_ type: D.Type, from: Data) throws -> D
}

// MARK: application/json

extension HTTPBodyDecoder where Self == JSONDecoder {
    public static func json(_ decoder: JSONDecoder = JSONDecoder()) -> Self {
        decoder
    }
}

extension JSONDecoder: HTTPBodyDecoder {
    public func with(keyMapping: KeyMapping) -> Self {
        let new = JSONDecoder()
        new.userInfo = userInfo
        new.dataDecodingStrategy = dataDecodingStrategy
        new.dateDecodingStrategy = dateDecodingStrategy
        new.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
#if os(Linux)
#else
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            new.assumesTopLevelDictionary = assumesTopLevelDictionary
            new.allowsJSON5 = allowsJSON5
        }
#endif
        new.keyDecodingStrategy = keyMapping.jsonDecodingStrategy
        return new as! Self
    }
}

// MARK: application/x-www-form-urlencoded

extension HTTPBodyDecoder where Self == URLEncodedFormDecoder {
    public static func urlForm(_ decoder: URLEncodedFormDecoder = URLEncodedFormDecoder()) -> Self {
        decoder
    }
}

extension URLEncodedFormDecoder: HTTPBodyDecoder {
    public func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D {
        let string = String(decoding: data, as: UTF8.self)
        return try decode(type, from: string)
    }

    public func with(keyMapping: KeyMapping) -> Self {
        var copy = self
        copy.keyMapping = keyMapping
        return copy
    }
}
