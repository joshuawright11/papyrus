import Alamofire
import Foundation

public protocol Response {
    var body: Data? { get }
    var headers: [String: String]? { get }
    var statusCode: Int? { get }
    var error: Error? { get }
}

extension Response {
    public func validate() throws {
        if let error = error {
            throw error
        }
    }

    public var response: HTTPURLResponse? {
        alamofire.response
    }

    public var request: URLRequest? {
        alamofire.request
    }

    public var alamofire: DataResponse<Data, AFError> {
        self as! DataResponse<Data, AFError>
    }
}

extension DataResponse: Response {
    public var body: Data? { data }
    public var headers: [String : String]? { response?.headers.dictionary }
    public var statusCode: Int? { response?.statusCode }
    public var error: Error? {
        guard case .failure(let error) = result else { return nil }
        return error
    }
}
