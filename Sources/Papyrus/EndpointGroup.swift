import Foundation

public protocol API {
    init()
}

@dynamicMemberLookup
public protocol APIProvider {
    associatedtype Service: API
    
    func adapt<Req: RequestConvertible, Res: Codable>(endpoint: inout Endpoint<Req, Res>)
}

extension APIProvider {
    public func adapt<Req: RequestConvertible, Res: Codable>(endpoint: inout Endpoint<Req, Res>) {}
    
    public subscript<Req: RequestConvertible, Res: Codable>(dynamicMember keyPath: KeyPath<Service, Endpoint<Req, Res>>) -> Endpoint<Req, Res> {
        var endpoint = Service()[keyPath: keyPath]
        adapt(endpoint: &endpoint)
        return endpoint
    }
}

struct Provider<Service: API>: APIProvider {
    /// The base URL for the API.
    let baseURL: String
    /// The key mapping strategy for the endpoint.
    let keyMapping: KeyMapping
    
    init(_ baseUrl: String, keyMapping: KeyMapping = .useDefaultKeys) {
        self.baseURL = baseUrl
        self.keyMapping = keyMapping
    }
    
    func adapt<Req, Res>(endpoint: inout Endpoint<Req, Res>) where Req : RequestConvertible, Res : Decodable, Res : Encodable {
        endpoint.baseURL = baseURL
        endpoint.keyMapping = keyMapping
    }
}
