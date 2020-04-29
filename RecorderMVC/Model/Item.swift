//
//  Item.swift
//  RecorderMVC
//
//  Created by Hang Gao on 2020/04/29.
//  Copyright © 2020 Hang Gao. All rights reserved.
//

import Foundation

class Item {
    let uuid: UUID
    private(set) var name: String
    weak var store: Store?
    weak var parent: Folder? {
        didSet {
            store = parent?.store
        }
    }
    
    init(name: String, uuid: UUID) {
        self.uuid = uuid
        self.name = name
        self.store = nil
    }
    
    func setName(_ newName: String) {
        self.name = newName
    }
    
    func deleted() {
        // this work for folder, but if its a file you need to acturally delete contents, so it's like a tree node
        // clear the reference
        parent = nil
    }
    
    var uuidPath: [UUID] {
        var path = parent?.uuidPath ?? []
        path.append(uuid)
        return path
    }
    
    // get yourself ?
    func item(atUUIDPath path: ArraySlice<UUID>) -> Item? {
        guard let first = path.first, first == uuid else { return nil }
        return self
    }
    
}

// why we needs these keys
extension Item {
   static let changeReasonKey = "reason"
   static let newValueKey = "newValue"
   static let oldValueKey = "oldValue"
   static let parentFolderKey = "parentFolder"
   static let renamed = "renamed"
   static let added = "added"
   static let removed = "removed"
}
