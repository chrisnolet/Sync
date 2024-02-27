//
//  Sync.swift
//  Sync
//
//  Created by Chris Nolet on 2/27/24.
//

import Combine
import SwiftUI

@propertyWrapper
public struct Sync<Value>: DynamicProperty where Value: Codable {
    private class Cache<T>: ObservableObject {
        var data: Data?
        var value: T?
    }

    @ObservedObject private var dataStore = DataStore.shared

    private let defaultValue: Value
    private let key: String?

    private var cache = Cache<Value>()

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

            set(newValue, key: key)
        }
    }

    public var projectedValue: Binding<Value> {
        return Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }

    public static subscript<T>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Sync>
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
        if let data = dataStore.values[key] {
            if data == cache.data {
                return cache.value ?? defaultValue
            }

            if let value = try? JSONDecoder().decode(Value.self, from: data) {
                cache.data = data
                cache.value = value

                return value
            }
        }

        return defaultValue
    }

    private func set(_ value: Value, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            dataStore.values[key] = data

            cache.data = data
            cache.value = value
        }
    }
}
