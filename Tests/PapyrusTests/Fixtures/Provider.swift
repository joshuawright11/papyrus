import Papyrus

struct Provider<Service: API>: APIProvider {
    let baseURL: String
    var keyMapping: KeyMapping = .useDefaultKeys
}
