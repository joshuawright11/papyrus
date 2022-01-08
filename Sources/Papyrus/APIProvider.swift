public protocol API {
    init()
}

@dynamicMemberLookup
public protocol APIProvider {
    associatedtype Service: API
    
    /// The base URL for the API.
    var baseURL: String { get }
    /// The key mapping strategy for the endpoint.
    var keyMapping: KeyMapping { get }
    
    /// Any custom logic for each outgoing endpoint request.
    func adapt<Req: EndpointRequest, Res: EndpointResponse>(endpoint: inout Endpoint<Req, Res>)
}

extension APIProvider {
    public func adapt<Req: EndpointRequest, Res: EndpointResponse>(endpoint: inout Endpoint<Req, Res>) {}
    
    public subscript<Req: EndpointRequest, Res: EndpointResponse>(dynamicMember keyPath: KeyPath<Service, Endpoint<Req, Res>>) -> Endpoint<Req, Res> {
        var endpoint = Service()[keyPath: keyPath]
        endpoint.baseURL = baseURL
        endpoint.setKeyMapping(keyMapping)
        adapt(endpoint: &endpoint)
        return endpoint
    }
}
