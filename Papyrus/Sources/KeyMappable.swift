import Foundation

public protocol KeyMappable {
    func with(keyMapping: KeyMapping) -> Self
}

extension KeyMappable {
    func with(keyMapping: KeyMapping?) -> Self {
        guard let keyMapping else { return self }
        return with(keyMapping: keyMapping)
    }
}
