//
//  SharePlayManager.swift
//  Sync
//
//  Created by Chris Nolet on 2/27/24.
//

import Combine
import Foundation
import GroupActivities

public class SharePlayManager {
    public static let shared = SharePlayManager()

    private var session: GroupSession<SharePlayActivity>?
    private var messenger: GroupSessionMessenger?
    private var tasks: Set<AnyCancellable> = []

    private init() {
        let sessions = SharePlayActivity.sessions()

        Task { @MainActor [weak self] in
            for await session in sessions {
                guard let self else { return }

                let messenger = GroupSessionMessenger(session: session, deliveryMode: .reliable)

                tasks = []

                Task { @MainActor [weak self] in
                    for await state in session.$state.values {
                        if case .invalidated(_) = state {
                            self?.session = nil
                        }
                    }
                }
                .store(in: &tasks)

                Task { @MainActor in
                    for await (message, _) in messenger.messages(of: DataStore.Values.self) {
                        DataStore.shared.merge(message)
                    }
                }
                .store(in: &tasks)

                Task { @MainActor in
                    for await values in DataStore.shared.valuesStream {
                        do {
                            try await messenger.send(values)
                        }
                        catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                .store(in: &tasks)

                session.join()

                self.session = session
                self.messenger = messenger
            }
        }
    }

    public func start() {
        let title = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        let activity = SharePlayActivity(title: title)

        Task {
            do {
                _ = try await activity.activate()
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }

    @MainActor
    public func stop() {
        session?.leave()
    }
}

extension Task: Cancellable {}
