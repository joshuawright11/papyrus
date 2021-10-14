import Foundation

/// An erased `Path`.
protocol AnyPath {
    /// The value of this path parameter.
    var stringValue: String { get }
}

/// Represents a path component value on an endpoint. This value will
/// replace a path component with the name of the property this
/// wraps.
@propertyWrapper
public struct Path<P: PathAllowed>: Codable, AnyPath {
    /// The value of this path component.
    public var wrappedValue: P
    
    // MARK: AnyPath
    
    var stringValue: String {
        wrappedValue.pathString
    }
    
    /// Initialize with a path component value.
    ///
    /// - Parameter wrappedValue: The value of this path component.
    public init(wrappedValue: P) {
        self.wrappedValue = wrappedValue
    }

    // MARK: Decodable
    
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self.wrappedValue = try P(pathParameter: string)
            .unwrap(or: PapyrusError("Unable to convert parameter \(string) to a \(P.self)"))
    }
}

public protocol PathAllowed: Codable {
    var pathString: String { get }
    init?(pathParameter: String)
}

extension String: PathAllowed {
    public var pathString: String { self }
    
    public init?(pathParameter: String) {
        self = pathParameter
    }
}

extension UUID: PathAllowed {
    public var pathString: String { uuidString }
    
    public init?(pathParameter: String) {
        self.init(uuidString: pathParameter)
    }
}

extension Bool: PathAllowed {
    public var pathString: String {
        "\(self)"
    }
    
    public init?(pathParameter: String) {
        self.init(pathParameter)
    }
}

extension Double: PathAllowed {
    public var pathString: String {
        "\(self)"
    }
    
    public init?(pathParameter: String) {
        self.init(pathParameter)
    }
}

extension Int: PathAllowed {
    public var pathString: String {
        "\(self)"
    }
    
    public init?(pathParameter: String) {
        self.init(pathParameter)
    }
}
