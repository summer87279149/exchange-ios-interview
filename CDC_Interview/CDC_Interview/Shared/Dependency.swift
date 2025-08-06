
import Foundation

final class Dependency {
    static let shared = Dependency()
    private let lock = NSLock()
    private var registerMap: [ObjectIdentifier: (Dependency) -> Any] = [:]
    private var resolveMap: [ObjectIdentifier: Any] = [:]
    
    init() {}
    func register<T>(_ type: T.Type, block: @escaping (Dependency) -> T) {
        lock.lock()
        defer { lock.unlock() }
        registerMap[ObjectIdentifier(type)] = block
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        let key = ObjectIdentifier(type)
        // Looks up the instance generator for the given key
        guard let factory = registerMap[key] else {
            return nil
        }
        
        if resolveMap.keys.contains(key), let resolved = resolveMap[key] as? T {
            return resolved
        }
        // Attempts to create the instance
        guard let newService = factory(self) as? T else {
            return nil
        }
        
        // Stores the instance in our "resolveMap" map
        resolveMap[key] = newService
        // Returns the new service
        return newService
    }
}
