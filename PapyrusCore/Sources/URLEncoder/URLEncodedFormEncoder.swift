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

/// The wrapper struct for encoding Codable classes to URL encoded form data
public struct URLEncodedFormEncoder {
    /// The strategy to use for encoding `Date` values.
    public enum DateEncodingStrategy {
        /// Defer to `Date` for encoding. This is the default strategy.
        case deferredToDate

        /// Encode the `Date` as a UNIX timestamp from a JSON number.
        case secondsSince1970

        /// Encode the `Date` as UNIX millisecond timestamp from a JSON number.
        case millisecondsSince1970

        /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601

        /// Encode the `Date` as a string parsed by the given formatter.
        case formatted(DateFormatter)

        /// Encode the `Date` as a custom value encoded by the given closure.
        case custom((Date, Encoder) throws -> Void)
    }

    /// The strategy to use in Encoding dates. Defaults to `.deferredToDate`.
    public var dateEncodingStrategy: DateEncodingStrategy

    /// Custom mapping of key names
    public var keyMapping: KeyMapping

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: Any]

    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    fileprivate struct _Options {
        let dateEncodingStrategy: DateEncodingStrategy
        let keyMapping: KeyMapping
        let userInfo: [CodingUserInfoKey: Any]
    }

    /// The options set on the top-level encoder.
    fileprivate var options: _Options {
        return _Options(
            dateEncodingStrategy: dateEncodingStrategy,
            keyMapping: keyMapping,
            userInfo: userInfo
        )
    }

    /// Create URLEncodedFormEncoder
    /// - Parameters:
    ///   - dateEncodingStrategy: date encoding strategy
    ///   - userInfo: user info to supply to encoder
    public init(
        dateEncodingStrategy: URLEncodedFormEncoder.DateEncodingStrategy = .deferredToDate,
        keyMapping: KeyMapping = .useDefaultKeys,
        userInfo: [CodingUserInfoKey: Any] = [:]
    ) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.userInfo = userInfo
        self.keyMapping = keyMapping
    }

    /// Encode object into URL encoded form data
    /// - Parameters:
    ///   - value: Value to encode
    /// - Returns: URL encoded form data
    public func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = _URLEncodedFormEncoder(options: options)
        try value.encode(to: encoder)
        guard let result = encoder.result else {
            throw EncodingError.invalidValue(value, .init(codingPath: [], debugDescription: "URLEncodedFormEncoder cannot be used to encode arrays"))
        }
        return result.description
    }
}

/// Internal QueryEncoder class. Does all the heavy lifting
private class _URLEncodedFormEncoder: Encoder {
    var codingPath: [CodingKey]

    /// the encoder's storage
    var storage: URLEncodedFormEncoderStorage

    /// options
    var options: URLEncodedFormEncoder._Options

    /// resultant url encoded array
    var result: URLEncodedFormNode?

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: Any] {
        return options.userInfo
    }

    /// Initialization
    /// - Parameters:
    ///   - options: options
    ///   - containerCodingMapType: Container encoding for the top level object
    init(options: URLEncodedFormEncoder._Options) {
        storage = URLEncodedFormEncoderStorage(keyMapping: options.keyMapping)
        self.options = options
        codingPath = []
        result = nil
    }

    func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let keyedContainer = storage.pushKeyedContainer()
        if result == nil {
            result = .map(keyedContainer)
        }
        return KeyedEncodingContainer(KEC(referencing: self, container: keyedContainer))
    }

    struct KEC<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var codingPath: [CodingKey] { return encoder.codingPath }
        let container: URLEncodedFormNode.Map
        let encoder: _URLEncodedFormEncoder

        /// Initialization
        /// - Parameter referencing: encoder that created this
        init(referencing: _URLEncodedFormEncoder, container: URLEncodedFormNode.Map) {
            encoder = referencing
            self.container = container
        }

        mutating func encode(_ value: URLEncodedFormNode, key: Key) {
            container.addChild(key: key, value: value)
        }

        mutating func encode(_ value: LosslessStringConvertible, key: Key) {
            encode(.leaf(.init(value)), key: key)
        }

        mutating func encodeNil(forKey key: Key) throws { encode("", key: key) }
        mutating func encode(_ value: Bool, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: String, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: Double, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: Float, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: Int, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: Int8, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: Int16, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: Int32, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: Int64, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: UInt, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: UInt8, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: UInt16, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: UInt32, forKey key: Key) throws { encode(value, key: key) }
        mutating func encode(_ value: UInt64, forKey key: Key) throws { encode(value, key: key) }

        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let childContainer = try encoder.box(value)
            container.addChild(key: key, value: childContainer)
        }

        mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let keyedContainer = URLEncodedFormNode.Map(keyMapping: encoder.options.keyMapping)
            container.addChild(key: key, value: .map(keyedContainer))

            let kec = KEC<NestedKey>(referencing: encoder, container: keyedContainer)
            return KeyedEncodingContainer(kec)
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }

            let unkeyedContainer = URLEncodedFormNode.Array()
            container.addChild(key: key, value: .array(unkeyedContainer))

            return UKEC(referencing: encoder, container: unkeyedContainer)
        }

        mutating func superEncoder() -> Encoder {
            return encoder
        }

        mutating func superEncoder(forKey _: Key) -> Encoder {
            return encoder
        }
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = storage.pushUnkeyedContainer()
        return UKEC(referencing: self, container: container)
    }

    struct UKEC: UnkeyedEncodingContainer {
        var codingPath: [CodingKey] { return encoder.codingPath }
        let container: URLEncodedFormNode.Array
        let encoder: _URLEncodedFormEncoder
        var count: Int

        init(referencing: _URLEncodedFormEncoder, container: URLEncodedFormNode.Array) {
            encoder = referencing
            self.container = container
            count = 0
        }

        mutating func encodeResult(_ value: URLEncodedFormNode) {
            count += 1
            container.addChild(value: value)
        }

        mutating func encodeResult(_ value: LosslessStringConvertible) {
            encodeResult(.leaf(.init(value)))
        }

        mutating func encodeNil() throws { encodeResult("") }
        mutating func encode(_ value: Bool) throws { encodeResult(value) }
        mutating func encode(_ value: String) throws { encodeResult(value) }
        mutating func encode(_ value: Double) throws { encodeResult(value) }
        mutating func encode(_ value: Float) throws { encodeResult(value) }
        mutating func encode(_ value: Int) throws { encodeResult(value) }
        mutating func encode(_ value: Int8) throws { encodeResult(value) }
        mutating func encode(_ value: Int16) throws { encodeResult(value) }
        mutating func encode(_ value: Int32) throws { encodeResult(value) }
        mutating func encode(_ value: Int64) throws { encodeResult(value) }
        mutating func encode(_ value: UInt) throws { encodeResult(value) }
        mutating func encode(_ value: UInt8) throws { encodeResult(value) }
        mutating func encode(_ value: UInt16) throws { encodeResult(value) }
        mutating func encode(_ value: UInt32) throws { encodeResult(value) }
        mutating func encode(_ value: UInt64) throws { encodeResult(value) }

        mutating func encode<T: Encodable>(_ value: T) throws {
            count += 1

            encoder.codingPath.append(URLEncodedForm.Key(index: count))
            defer { self.encoder.codingPath.removeLast() }

            let childContainer = try encoder.box(value)
            container.addChild(value: childContainer)
        }

        mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            count += 1

            encoder.codingPath.append(URLEncodedForm.Key(index: count))
            defer { self.encoder.codingPath.removeLast() }

            let keyedContainer = URLEncodedFormNode.Map(keyMapping: encoder.options.keyMapping)
            container.addChild(value: .map(keyedContainer))

            let kec = KEC<NestedKey>(referencing: encoder, container: keyedContainer)
            return KeyedEncodingContainer(kec)
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            count += 1

            let unkeyedContainer = URLEncodedFormNode.Array()
            container.addChild(value: .array(unkeyedContainer))

            return UKEC(referencing: encoder, container: unkeyedContainer)
        }

        mutating func superEncoder() -> Encoder {
            return encoder
        }
    }
}

extension _URLEncodedFormEncoder: SingleValueEncodingContainer {
    func encodeResult(_ value: URLEncodedFormNode) {
        storage.push(container: value)
    }

    func encodeResult(_ value: LosslessStringConvertible) {
        storage.push(container: .leaf(.init(value)))
    }

    func encodeNil() throws {
        storage.push(container: .leaf(nil))
    }

    func encode(_ value: Bool) throws { encodeResult(value) }
    func encode(_ value: String) throws { encodeResult(value) }
    func encode(_ value: Double) throws { encodeResult(value) }
    func encode(_ value: Float) throws { encodeResult(value) }
    func encode(_ value: Int) throws { encodeResult(value) }
    func encode(_ value: Int8) throws { encodeResult(value) }
    func encode(_ value: Int16) throws { encodeResult(value) }
    func encode(_ value: Int32) throws { encodeResult(value) }
    func encode(_ value: Int64) throws { encodeResult(value) }
    func encode(_ value: UInt) throws { encodeResult(value) }
    func encode(_ value: UInt8) throws { encodeResult(value) }
    func encode(_ value: UInt16) throws { encodeResult(value) }
    func encode(_ value: UInt32) throws { encodeResult(value) }
    func encode(_ value: UInt64) throws { encodeResult(value) }

    func encode<T: Encodable>(_ value: T) throws {
        try value.encode(to: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

extension _URLEncodedFormEncoder {
    func box(_ date: Date) throws -> URLEncodedFormNode {
        switch options.dateEncodingStrategy {
        case .deferredToDate:
            try date.encode(to: self)
        case .millisecondsSince1970:
            try encode(Double(date.timeIntervalSince1970 * 1000).description)
        case .secondsSince1970:
            try encode(Double(date.timeIntervalSince1970).description)
        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                try encode(URLEncodedForm.iso8601Formatter.string(from: date))
            } else {
                preconditionFailure("ISO8601DateFormatter is unavailable on this platform")
            }
        case let .formatted(formatter):
            try encode(formatter.string(from: date))
        case let .custom(closure):
            try closure(date, self)
        }
        return storage.popContainer()
    }

    func box(_ data: Data) throws -> URLEncodedFormNode {
        try encode(data.base64EncodedString())
        return storage.popContainer()
    }

    func box(_ value: Encodable) throws -> URLEncodedFormNode {
        let type = Swift.type(of: value)
        if type == Data.self {
            return try box(value as! Data)
        } else if type == Date.self {
            return try box(value as! Date)
        } else {
            try value.encode(to: self)
            return storage.popContainer()
        }
    }
}

/// storage for Query Encoder. Stores a stack of QueryEncoder containers, plus leaf objects
private struct URLEncodedFormEncoderStorage {
    /// the container stack
    private var containers: [URLEncodedFormNode] = []
    private let keyMapping: KeyMapping

    /// initializes self with no containers
    init(keyMapping: KeyMapping) {
        self.keyMapping = keyMapping
        // containers.append(.map(.init()))
    }

    /// push a new container onto the storage
    mutating func pushKeyedContainer() -> URLEncodedFormNode.Map {
        let map = URLEncodedFormNode.Map(keyMapping: keyMapping)
        containers.append(.map(map))
        return map
    }

    /// push a new container onto the storage
    mutating func pushUnkeyedContainer() -> URLEncodedFormNode.Array {
        let array = URLEncodedFormNode.Array()
        containers.append(.array(array))
        return array
    }

    mutating func push(container: URLEncodedFormNode) {
        containers.append(container)
    }

    /// pop a container from the storage
    @discardableResult mutating func popContainer() -> URLEncodedFormNode {
        return containers.removeLast()
    }
}

private protocol StringKeyedDict {}
extension Dictionary: StringKeyedDict where Key == String {}
