//
//  DataStore.swift
//  Sync
//
//  Created by Chris Nolet on 2/27/24.
//

import Combine
import Foundation

public class DataStore: ObservableObject {
    public typealias Values = [String: Data]

    public static let shared = DataStore()

    @MainActor
    @Published public var values: Values = [:] {
        didSet {
            guard !isUpdating else { return }

            let delta = delta(from: oldValue, to: values)

            if !delta.isEmpty {
                valuesPassthrough.send(delta)
            }
        }
    }

    @MainActor
    public var valuesStream: AsyncStream<Values> { valuesPassthrough.values }

    private let valuesPassthrough = AsyncPassthrough<Values>()
    private var isUpdating = false

    @MainActor
    public func merge(_ values: Values) {
        isUpdating = true

        self.values.merge(values) { previousValue, value in
            return value
        }

        isUpdating = false
    }

    private func delta(from previousValues: Values, to values: Values) -> Values {
        var results: Values = [:]

        for (key, value) in values {
            if let previousValue = previousValues[key] {
                if value == previousValue {
                    continue
                }
            }

            results[key] = value
        }

        for key in previousValues.keys {
            if values[key] == nil {
                results[key] = Data()
            }
        }

        return results
    }
}
