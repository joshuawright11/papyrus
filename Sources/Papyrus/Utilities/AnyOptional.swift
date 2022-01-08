protocol AnyOptional {
    static var `nil`: Self { get }
}
extension Optional: AnyOptional {
    static var `nil`: Optional<Wrapped> { nil }
}
