//
//  SharePlayActivity.swift
//  Sync
//
//  Created by Chris Nolet on 2/27/24.
//

import Foundation
import GroupActivities

struct SharePlayActivity: GroupActivity {
    let title: String?

    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()

        metadata.type = .generic
        metadata.title = title

        return metadata
    }
}
