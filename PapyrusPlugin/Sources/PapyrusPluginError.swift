public struct PapyrusPluginError: Error, CustomStringConvertible {
    public let message: String

    init(_ message: String) {
        self.message = message
    }

    public var description: String {
        message
    }
}
