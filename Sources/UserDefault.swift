//
//  UserDefault.swift
//  Sync
//
//  Created by Chris Nolet on 2/27/24.
//

import Combine
import SwiftUI

@propertyWrapper
public struct UserDefault<Value>: DynamicProperty where Value: Codable {
    private class Cache<T>: ObservableObject {
        var value: T?
    }

    @ObservedObject private var cache = Cache<Value>()

    private let defaultValue: Value
    private let key: String?

    public init(wrappedValue: Value, _ key: String? = nil) {
        self.defaultValue = wrappedValue
        self.key = key
    }

    public var wrappedValue: Value {
        get {
            guard let key else { fatalError() }

            return get(key: key)
        }

        nonmutating set {
            guard let key else { fatalError() }

            cache.objectWillChange.send()
            set(newValue, key: key)
        }
    }

    public var projectedValue: Binding<Value> {
        return Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }

    public static subscript<T>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, UserDefault>
    ) -> Value {
        get {
            let storage = instance[keyPath: storageKeyPath]
            let key = storage.key ?? String(reflecting: wrappedKeyPath)

            return storage.get(key: key)
        }

        set {
            if let instance = instance as? any ObservableObject {
                let objectWillChange = instance.objectWillChange as any Publisher

                if let objectWillChange = objectWillChange as? ObservableObjectPublisher {
                    objectWillChange.send()
                }
            }

            let storage = instance[keyPath: storageKeyPath]
            let key = storage.key ?? String(reflecting: wrappedKeyPath)

            storage.set(newValue, key: key)
        }
    }

    private func get(key: String) -> Value {
        if let value = cache.value {
            return value
        }

        if let jsonString = UserDefaults.standard.string(forKey: key) {
            if let jsonData = jsonString.data(using: .utf8) {
                if let result = try? JSONDecoder().decode(Value.self, from: jsonData) {
                    cache.value = result

                    return result
                }
            }
        }

        return defaultValue
    }

    private func set(_ value: Value, key: String) {
        cache.value = value

        if let jsonData = try? JSONEncoder().encode(value) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: key)
            }
        }
    }
}
