import Foundation

public protocol PapyrusRequest: Sendable {
    var url: URL? { get set }
    var method: String { get set }
    var headers: [String: String] { get set }
    var body: Data? { get set }
}
