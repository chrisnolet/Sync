//
//  AsyncPassthrough.swift
//  Sync
//
//  Created by Chris Nolet on 2/27/24.
//

import Foundation

public class AsyncPassthrough<Element> {
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]

    @MainActor
    public var values: AsyncStream<Element> {
        AsyncStream { [weak self] continuation in
            let id = UUID()

            self?.continuations[id] = continuation

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    deinit {
        for continuation in continuations.values {
            continuation.finish()
        }
    }

    @MainActor
    public func send(_ value: Element) {
        for continuation in continuations.values {
            continuation.yield(value)
        }
    }

    @MainActor
    public func finish() {
        for continuation in continuations.values {
            continuation.finish()
        }

        continuations.removeAll()
    }
}
