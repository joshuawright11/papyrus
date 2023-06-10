protocol AnyOptional {
    static var `nil`: Self { get }
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    static var `nil`: Optional<Wrapped> { nil }
    var isNil: Bool { self == nil }
}
