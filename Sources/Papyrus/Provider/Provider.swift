public struct Provider<Service: API>: APIProvider {
    /// The base URL for the API.
    public let baseURL: String
    /// The key mapping strategy for the endpoint.
    public let keyMapping: KeyMapping
    
    public init(_ baseUrl: String, keyMapping: KeyMapping = .useDefaultKeys) {
        self.baseURL = baseUrl
        self.keyMapping = keyMapping
    }
    
    public func adapt<Req: EndpointRequest, Res: Codable>(endpoint: inout Endpoint<Req, Res>) {}
}
