public protocol API {
    /// The base URL for the API.
    var baseURL: String { get }
    /// The key mapping strategy for the endpoint.
    var keyMapping: KeyMapping { get }
    /// The preferred converter
    var converter: ContentConverter { get }
    
    /// Any custom logic for each outgoing endpoint request.
    func adapt<Req: EndpointRequest, Res: EndpointResponse>(endpoint: inout Endpoint<Req, Res>)
}

extension API {
    public var keyMapping: KeyMapping { .useDefaultKeys }
    public var converter: ContentConverter { JSONConverter() }
    public func adapt<Req: EndpointRequest, Res: EndpointResponse>(endpoint: inout Endpoint<Req, Res>) {}
}

@dynamicMemberLookup
public struct Provider<Service: API> {
    private let api: Service
    public init(api: Service) { self.api = api }
    
    public subscript<Req: EndpointRequest, Res: EndpointResponse>(dynamicMember keyPath: KeyPath<Service, Endpoint<Req, Res>>) -> Endpoint<Req, Res> {
        var endpoint = api[keyPath: keyPath]
        endpoint.baseURL = api.baseURL
        endpoint.setConverter(api.converter)
        endpoint.setKeyMapping(api.keyMapping)
        api.adapt(endpoint: &endpoint)
        return endpoint
    }
}
