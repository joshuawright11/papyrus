import Foundation

public struct Part: Codable {
    public let data: Data
    public let name: String?
    public let fileName: String?
    public let mimeType: String?

    public init(data: Data, name: String? = nil, fileName: String? = nil, mimeType: String? = nil) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
