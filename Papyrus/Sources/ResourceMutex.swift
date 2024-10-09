//
//  ResourceMutex.swift
//  
//
//  Created by Kevin Pittevils on 11/07/2024.
//

import Foundation

// Note: Can be replaced with Synchronization framework starting with iOS 18.
public final class ResourceMutex<R>: @unchecked Sendable {
    private var resource: R
    private let mutex: UnsafeMutablePointer<pthread_mutex_t>

    public init(resource: R) {
        let mutexAttr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        pthread_mutexattr_init(mutexAttr)
        pthread_mutexattr_settype(mutexAttr, Int32(PTHREAD_MUTEX_RECURSIVE))
        mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        pthread_mutex_init(mutex, mutexAttr)
        pthread_mutexattr_destroy(mutexAttr)
        mutexAttr.deallocate()
        self.resource = resource
    }

    deinit {
        pthread_mutex_destroy(mutex)
        mutex.deallocate()
    }

    public func withLock<T>(method: (inout R) -> T) -> T {
        defer { unlock() }
        lock()
        return method(&resource)
    }

    public func withLock<T>(method: (inout R) throws -> T) throws -> T {
        defer { unlock() }
        lock()
        return try method(&resource)
    }

    public func withLock<T>(method: (inout R) async throws -> T) async throws -> T {
        defer { unlock() }
        lock()
        return try await method(&resource)
    }
}

private extension ResourceMutex {
    func lock() {
        pthread_mutex_lock(mutex)
    }

    func unlock() {
        pthread_mutex_unlock(mutex)
    }
}
