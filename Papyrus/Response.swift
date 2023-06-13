import Alamofire
import Foundation

public protocol Response {
    var body: Data { get }
    var headers: [String: String]? { get }
    var statusCode: Int { get }
}

extension Response {
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
    public var body: Data { data ?? Data() }
    public var headers: [String : String]? { response?.headers.dictionary }
    public var statusCode: Int { response?.statusCode ?? 0 }
}
