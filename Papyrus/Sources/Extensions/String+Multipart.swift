extension String {
    static func randomMultipartBoundary() -> String {
        let first = UInt32.random(in: UInt32.min...UInt32.max)
        let second = UInt32.random(in: UInt32.min...UInt32.max)
        return String(format: "papyrus.boundary.%08x%08x", first, second)
    }

    static let crlf = "\r\n"
}
