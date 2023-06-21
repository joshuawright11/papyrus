struct PapyrusPluginError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
