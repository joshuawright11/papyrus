@_exported import Foundation
@_exported import PapyrusCore

extension Provider {
    public convenience init(baseURL: String,
                            urlSession: URLSession = .shared,
                            modifiers: [RequestModifier] = [],
                            interceptors: [PapyrusCore.Interceptor] = []) {
        self.init(baseURL: baseURL, http: urlSession, modifiers: modifiers, interceptors: interceptors)
    }
}

extension URLSession : HTTPService {
    public func build(method: String, url: URL, headers: [String : String], body: Data?) -> PapyrusCore.Request {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.allHTTPHeaderFields = headers
        return AnyRequest(request: request)
    }
    
    public func request(_ req: PapyrusCore.Request) async -> PapyrusCore.Response {
        do {
            let (data, response) = try await data(for: req.urlRequest)
            return URLSessionDataResponse(data: data, response: response, error: nil)
        } catch {
            return URLSessionDataResponse(data: nil, response: nil, error: error)
        }
    }
    
    public func request(_ req: PapyrusCore.Request, completionHandler: @escaping (PapyrusCore.Response) -> Void) {
        let task = dataTask(with: req.urlRequest) { data, response, error in
            completionHandler(URLSessionDataResponse(data: data, response: response, error: error))
        }
        
        task.resume()
    }
}

struct URLSessionDataResponse : Response {
    let data: Data?
    let response: URLResponse?
    let error: Error?
    
    var body: Data? {
        data
    }
    
    var headers: [String : String]? {
        if let response = response as? HTTPURLResponse {
            let keysAndValues: [(String, String)] = response.allHeaderFields.compactMap { key, value in
                guard let key = key as? String, let value = value as? String else {
                    return nil
                }
                
                return (key, value)
            }

            return Dictionary(keysAndValues, uniquingKeysWith: { _, last in last })
        }
        
        return nil
    }
    
    var statusCode: Int? {
        if let response = response as? HTTPURLResponse {
            return response.statusCode
        }
        
        return nil
    }
}
