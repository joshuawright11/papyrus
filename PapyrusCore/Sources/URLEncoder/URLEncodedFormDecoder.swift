//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2021-2021 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

/// The wrapper struct for decoding URL encoded form data to Codable classes
public struct URLEncodedFormDecoder {
    /// The strategy to use for decoding `Date` values.
    public enum DateDecodingStrategy {
        /// Defer to `Date` for decoding. This is the default strategy.
        case deferredToDate

        /// Decode the `Date` as a UNIX timestamp from a JSON number.
        case secondsSince1970

        /// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
        case millisecondsSince1970

        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601

        /// Decode the `Date` as a string parsed by the given formatter.
        case formatted(DateFormatter)

        /// Decode the `Date` as a custom value encoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Date)
    }

    /// The strategy to use in Encoding dates. Defaults to `.deferredToDate`.
    public var dateDecodingStrategy: DateDecodingStrategy

    /// Custom mapping of key names
    public var keyMapping: KeyMapping

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: Any]

    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    fileprivate struct _Options {
        let dateDecodingStrategy: DateDecodingStrategy
        let keyMapping: KeyMapping
        let userInfo: [CodingUserInfoKey: Any]
    }

    /// The options set on the top-level encoder.
    fileprivate var options: _Options {
        return _Options(
            dateDecodingStrategy: dateDecodingStrategy,
            keyMapping: keyMapping,
            userInfo: userInfo
        )
    }

    /// Create URLEncodedFormDecoder
    /// - Parameters:
    ///   - dateDecodingStrategy: date decoding strategy
    ///   - userInfo: user info to supply to decoder
    public init(
        dateDecodingStrategy: URLEncodedFormDecoder.DateDecodingStrategy = .deferredToDate,
        keyMapping: KeyMapping = .useDefaultKeys,
        userInfo: [CodingUserInfoKey: Any] = [:]
    ) {
        self.dateDecodingStrategy = dateDecodingStrategy
        self.keyMapping = keyMapping
        self.userInfo = userInfo
    }

    /// Decode from URL encoded form data to type
    /// - Parameters:
    ///   - type: Type to decode to
    ///   - string: URL encoded form data
    public func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        let decoder = _URLEncodedFormDecoder(options: options)
        let node = try URLEncodedFormNode(from: string, keyMapping: options.keyMapping)
        let value = try decoder.unbox(node, as: type)
        return value
    }
}

private class _URLEncodedFormDecoder: Decoder {
    // MARK: Properties

    /// The decoder's storage.
    fileprivate var storage: URLEncodedFormDecodingStorage

    /// Options set on the top-level decoder.
    fileprivate let options: URLEncodedFormDecoder._Options

    /// The path to the current point in encoding.
    public fileprivate(set) var codingPath: [CodingKey]

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: Any] {
        return options.userInfo
    }

    // MARK: - Initialization

    /// Initializes `self` with the given top-level container and options.
    fileprivate init(at codingPath: [CodingKey] = [], options: URLEncodedFormDecoder._Options) {
        self.codingPath = codingPath
        self.options = options
        storage = .init()
    }

    func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        guard case let .map(map) = storage.topContainer else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected a dictionary"))
        }
        return KeyedDecodingContainer(KDC(container: map, decoder: self))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case let .array(array) = storage.topContainer else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected an array"))
        }
        return UKDC(container: array, decoder: self)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }

    struct KDC<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var codingPath: [CodingKey] { decoder.codingPath }
        let decoder: _URLEncodedFormDecoder
        let container: URLEncodedFormNode.Map

        let allKeys: [Key]

        init(container: URLEncodedFormNode.Map, decoder: _URLEncodedFormDecoder) {
            self.decoder = decoder
            self.container = container
            allKeys = container.values.keys.compactMap { Key(stringValue: $0) }
        }

        func contains(_ key: Key) -> Bool {
            return container.values[key.stringValue] != nil
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            guard let node = container.values[key.stringValue] else { return true }
            return try decoder.unboxNil(node)
        }

        func decode(_: Bool.Type, forKey key: Key) throws -> Bool {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: Bool.self)
        }

        func decode(_: String.Type, forKey key: Key) throws -> String {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: String.self)
        }

        func decode(_: Double.Type, forKey key: Key) throws -> Double {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: Double.self)
        }

        func decode(_: Float.Type, forKey key: Key) throws -> Float {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: Float.self)
        }

        func decode(_: Int.Type, forKey key: Key) throws -> Int {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: Int.self)
        }

        func decode(_: Int8.Type, forKey key: Key) throws -> Int8 {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: Int8.self)
        }

        func decode(_: Int16.Type, forKey key: Key) throws -> Int16 {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: Int16.self)
        }

        func decode(_: Int32.Type, forKey key: Key) throws -> Int32 {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: Int32.self)
        }

        func decode(_: Int64.Type, forKey key: Key) throws -> Int64 {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: Int64.self)
        }

        func decode(_: UInt.Type, forKey key: Key) throws -> UInt {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: UInt.self)
        }

        func decode(_: UInt8.Type, forKey key: Key) throws -> UInt8 {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: UInt8.self)
        }

        func decode(_: UInt16.Type, forKey key: Key) throws -> UInt16 {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: UInt16.self)
        }

        func decode(_: UInt32.Type, forKey key: Key) throws -> UInt32 {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: UInt32.self)
        }

        func decode(_: UInt64.Type, forKey key: Key) throws -> UInt64 {
            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            return try decoder.unbox(node, as: UInt64.self)
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
            decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }

            guard let node = container.values[key.stringValue] else {
                if let t = type as? AnyOptional.Type { return t.nil as! T }
                throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: ""))
            }
            return try decoder.unbox(node, as: T.self)
        }

        func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }

            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            guard case let .map(map) = node else {
                throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected a dictionary"))
            }
            let container = KDC<NestedKey>(container: map, decoder: decoder)
            return KeyedDecodingContainer(container)
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            decoder.codingPath.append(key)
            defer { self.decoder.codingPath.removeLast() }

            guard let node = container.values[key.stringValue] else { throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "")) }
            guard case let .array(array) = node else {
                throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected a dictionary"))
            }
            return UKDC(container: array, decoder: decoder)
        }

        func superDecoder() throws -> Decoder {
            fatalError()
        }

        func superDecoder(forKey _: Key) throws -> Decoder {
            fatalError()
        }
    }

    struct UKDC: UnkeyedDecodingContainer {
        let container: URLEncodedFormNode.Array
        let decoder: _URLEncodedFormDecoder
        var codingPath: [CodingKey] { decoder.codingPath }
        let count: Int?
        var isAtEnd: Bool { currentIndex == count }
        var currentIndex: Int

        init(container: URLEncodedFormNode.Array, decoder: _URLEncodedFormDecoder) {
            self.container = container
            self.decoder = decoder
            count = container.values.count
            currentIndex = 0
        }

        mutating func decodeNil() throws -> Bool {
            let node = container.values[currentIndex]
            return try decoder.unboxNil(node)
        }

        mutating func decode(_: Bool.Type) throws -> Bool {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: Bool.self)
        }

        mutating func decode(_: String.Type) throws -> String {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: String.self)
        }

        mutating func decode(_: Double.Type) throws -> Double {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: Double.self)
        }

        mutating func decode(_: Float.Type) throws -> Float {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: Float.self)
        }

        mutating func decode(_: Int.Type) throws -> Int {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: Int.self)
        }

        mutating func decode(_: Int8.Type) throws -> Int8 {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: Int8.self)
        }

        mutating func decode(_: Int16.Type) throws -> Int16 {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: Int16.self)
        }

        mutating func decode(_: Int32.Type) throws -> Int32 {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: Int32.self)
        }

        mutating func decode(_: Int64.Type) throws -> Int64 {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: Int64.self)
        }

        mutating func decode(_: UInt.Type) throws -> UInt {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: UInt.self)
        }

        mutating func decode(_: UInt8.Type) throws -> UInt8 {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: UInt8.self)
        }

        mutating func decode(_: UInt16.Type) throws -> UInt16 {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: UInt16.self)
        }

        mutating func decode(_: UInt32.Type) throws -> UInt32 {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: UInt32.self)
        }

        mutating func decode(_: UInt64.Type) throws -> UInt64 {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: UInt64.self)
        }

        mutating func decode<T>(_: T.Type) throws -> T where T: Decodable {
            let node = container.values[currentIndex]
            currentIndex += 1
            return try decoder.unbox(node, as: T.self)
        }

        mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            let node = container.values[currentIndex]
            currentIndex += 1
            guard case let .map(map) = node else {
                throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected a dictionary"))
            }
            let container = KDC<NestedKey>(container: map, decoder: decoder)
            return KeyedDecodingContainer(container)
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            let node = container.values[currentIndex]
            currentIndex += 1
            guard case let .array(array) = node else {
                throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected a dictionary"))
            }
            return UKDC(container: array, decoder: decoder)
        }

        mutating func superDecoder() throws -> Decoder {
            fatalError()
        }
    }
}

extension _URLEncodedFormDecoder: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        (try? unboxNil(storage.topContainer)) ?? false
    }

    func decode(_: Bool.Type) throws -> Bool {
        try unbox(storage.topContainer, as: Bool.self)
    }

    func decode(_: String.Type) throws -> String {
        try unbox(storage.topContainer, as: String.self)
    }

    func decode(_: Double.Type) throws -> Double {
        try unbox(storage.topContainer, as: Double.self)
    }

    func decode(_: Float.Type) throws -> Float {
        try unbox(storage.topContainer, as: Float.self)
    }

    func decode(_: Int.Type) throws -> Int {
        try unbox(storage.topContainer, as: Int.self)
    }

    func decode(_: Int8.Type) throws -> Int8 {
        try unbox(storage.topContainer, as: Int8.self)
    }

    func decode(_: Int16.Type) throws -> Int16 {
        try unbox(storage.topContainer, as: Int16.self)
    }

    func decode(_: Int32.Type) throws -> Int32 {
        try unbox(storage.topContainer, as: Int32.self)
    }

    func decode(_: Int64.Type) throws -> Int64 {
        try unbox(storage.topContainer, as: Int64.self)
    }

    func decode(_: UInt.Type) throws -> UInt {
        try unbox(storage.topContainer, as: UInt.self)
    }

    func decode(_: UInt8.Type) throws -> UInt8 {
        try unbox(storage.topContainer, as: UInt8.self)
    }

    func decode(_: UInt16.Type) throws -> UInt16 {
        try unbox(storage.topContainer, as: UInt16.self)
    }

    func decode(_: UInt32.Type) throws -> UInt32 {
        try unbox(storage.topContainer, as: UInt32.self)
    }

    func decode(_: UInt64.Type) throws -> UInt64 {
        try unbox(storage.topContainer, as: UInt64.self)
    }

    func decode<T>(_: T.Type) throws -> T where T: Decodable {
        try unbox(storage.topContainer, as: T.self)
    }
}

extension _URLEncodedFormDecoder {
    func unboxNil(_ node: URLEncodedFormNode) throws -> Bool {
        guard case let .leaf(value) = node else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expect value not array or dictionary"))
        }
        return value == nil
    }

    func unbox(_ node: URLEncodedFormNode, as _: Bool.Type) throws -> Bool {
        guard case let .leaf(value) = node else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expect value not array or dictionary"))
        }
        if let value2 = value {
            if let unboxValue = Bool(value2.value) {
                return unboxValue
            } else {
                throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected Bool"))
            }
        } else {
            return false
        }
    }

    func unbox(_ node: URLEncodedFormNode, as _: String.Type) throws -> String {
        guard case let .leaf(value) = node else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expect value not array or dictionary"))
        }
        guard let value2 = value else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected value not empty string"))
        }
        return value2.value
    }

    func unbox(_ node: URLEncodedFormNode, as _: Double.Type) throws -> Double {
        guard let unboxValue = try Double(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected Double"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: Float.Type) throws -> Float {
        guard let unboxValue = try Float(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected Float"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: Int.Type) throws -> Int {
        guard let unboxValue = try Int(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected Int"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: Int8.Type) throws -> Int8 {
        guard let unboxValue = try Int8(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected Int8"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: Int16.Type) throws -> Int16 {
        guard let unboxValue = try Int16(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected Int16"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: Int32.Type) throws -> Int32 {
        guard let unboxValue = try Int32(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected Int32"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: Int64.Type) throws -> Int64 {
        guard let unboxValue = try Int64(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected Int64"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: UInt.Type) throws -> UInt {
        guard let unboxValue = try UInt(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected UInt"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: UInt8.Type) throws -> UInt8 {
        guard let unboxValue = try UInt8(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected UInt8"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: UInt16.Type) throws -> UInt16 {
        guard let unboxValue = try UInt16(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected UInt16"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: UInt32.Type) throws -> UInt32 {
        guard let unboxValue = try UInt32(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected UInt32"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: UInt64.Type) throws -> UInt64 {
        guard let unboxValue = try UInt64(unbox(node, as: String.self)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Expected UInt64"))
        }
        return unboxValue
    }

    func unbox(_ node: URLEncodedFormNode, as _: Date.Type) throws -> Date {
        switch options.dateDecodingStrategy {
        case .deferredToDate:
            storage.push(container: node)
            defer { self.storage.popContainer() }
            return try .init(from: self)
        case .millisecondsSince1970:
            let milliseconds = try unbox(node, as: Double.self)
            return Date(timeIntervalSince1970: milliseconds / 1000)
        case .secondsSince1970:
            let seconds = try unbox(node, as: Double.self)
            return Date(timeIntervalSince1970: seconds)
        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                let dateString = try unbox(node, as: String.self)
                guard let date = URLEncodedForm.iso8601Formatter.date(from: dateString) else {
                    throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Invalid date format"))
                }
                return date
            } else {
                preconditionFailure("ISO8601DateFormatter is unavailable on this platform")
            }
        case let .formatted(formatter):
            let dateString = try unbox(node, as: String.self)
            guard let date = formatter.date(from: dateString) else {
                throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Invalid date format"))
            }
            return date
        case let .custom(closure):
            storage.push(container: node)
            defer { self.storage.popContainer() }
            return try closure(self)
        }
    }

    func unbox(_ node: URLEncodedFormNode, as _: Data.Type) throws -> Data {
        let string = try unbox(node, as: String.self)
        guard let data = Data(base64Encoded: string) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Encountered Data is not valid Base64."))
        }
        return data
    }

    func unbox<T>(_ node: URLEncodedFormNode, as _: T.Type) throws -> T where T: Decodable {
        return try unbox_(node, as: T.self) as! T
    }

    func unbox_(_ node: URLEncodedFormNode, as type: Decodable.Type) throws -> Any {
        if type == Data.self {
            return try unbox(node, as: Data.self)
        } else if type == Date.self {
            return try unbox(node, as: Date.self)
        } else {
            storage.push(container: node)
            defer { self.storage.popContainer() }
            return try type.init(from: self)
        }
    }
}

private struct URLEncodedFormDecodingStorage {
    /// the container stack
    private var containers: [URLEncodedFormNode] = []

    /// initializes self with no containers
    init() {}

    /// return the container at the top of the storage
    var topContainer: URLEncodedFormNode { return containers.last! }

    /// push a new container onto the storage
    mutating func push(container: URLEncodedFormNode) { containers.append(container) }

    /// pop a container from the storage
    @discardableResult mutating func popContainer() -> URLEncodedFormNode { containers.removeLast() }
}

protocol AnyOptional {
    static var `nil`: Self { get }
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    static var `nil`: Wrapped? { nil }
    var isNil: Bool { self == nil }
}
