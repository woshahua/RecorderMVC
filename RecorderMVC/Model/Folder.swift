//
//  Folder.swift
//  RecorderMVC
//
//  Created by Hang Gao on 2020/04/29.
//  Copyright © 2020 Hang Gao. All rights reserved.
//

import Foundation

class Folder: Item, Codable {
    private(set) var contents: [Item]
    override weak var store: Store? {
        didSet {
            contents.forEach {
                $0.store = store
            }
        }
    }
    
    override init(name: String, uuid: UUID) {
        contents = []
        super.init(name: name, uuid: uuid)
    }
    
    required init(from decoder: Decoder) throws {
        // decode use folder key ?
        let c = try decoder.container(keyedBy: FolderKeys.self)
        
        // clear contents ?
        contents = [Item]()
        // unkeyed container ?
        var nested = try c.nestedUnkeyedContainer(forKey: .contents)
        while true {
            let wrapper = try nested.nestedContainer(keyedBy: FolderOrRecording.self)
            // this part is also ?
            if let f = try wrapper.decodeIfPresent(Folder.self, forKey: .folder) {
                contents.append(f)
            } else if let r = try wrapper.decodeIfPresent(Recording.self, forKey: .recording) {
                contents.append(r)
            } else {
                break
            }
        }
        
        // like file path
        let uuid = try c.decode(UUID.self, forKey: .uuid)
        // get file name
        let name = try c.decode(String.self, forKey: .name)
        super.init(name: name, uuid: uuid)
        
        for c in contents {
            c.parent = self
        }
    }
    
    // encode process
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: FolderKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(uuid, forKey: .uuid)
        var nested = c.nestedUnkeyedContainer(forKey: .contents)
        for c in contents {
            var wrapper = nested.nestedContainer(keyedBy: FolderOrRecording.self)
            switch c {
            case let f as Folder: try wrapper.encode(f, forKey: .folder)
            case let r as Recording: try wrapper.encode(r, forKey: .recording)
            default: break
            }
        }
        _ = nested.nestedContainer(keyedBy: FolderOrRecording.self)
    }
    
    // set these keys for ?
    // I think these are for encode
    enum FolderKeys: CodingKey { case name, uuid, contents }
    enum FolderOrRecording: CodingKey { case folder, recording }
    
    func add(_ item: Item) {
        // why you need this,
        assert(contents.contains { $0 === item } == false)
        contents.append(item)
        contents.sort(by: { $0.name < $1.name })
        let newIndex = contents.firstIndex { $0 === item }!
        item.parent = self
        store?.save(item, userInfo: [Item.changeReasonKey: Item.added, Item.newValueKey: newIndex, Item.parentFolderKey: self])
    }
    
    // sort the files when new item is added
    func reSort(changedItem: Item) -> (oldIndex: Int, newIndex: Int) {
        let oldIndex = contents.firstIndex { $0 === changedItem }!
        contents.sort(by: { $0.name < $1.name })
        let newIndex = contents.firstIndex { $0 === changedItem }!
        return (oldIndex, newIndex)
    }
    
    // a method to delete all items inside this one
    override func deleted() {
        for item in contents {
            remove(item)
        }
        super.deleted()
    }
    
    func remove(_ item: Item) {
        guard let index = contents.firstIndex(where: { $0 === item }) else { return }
        item.deleted()
        contents.remove(at: index)
        store?.save(item, userInfo: [
            Item.changeReasonKey: Item.removed,
            Item.oldValueKey: index,
            Item.parentFolderKey: self
        ])
    }
    
    // why dont write like getItem ?
    override func item(atUUIDPath path: ArraySlice<UUID>) -> Item? {
        // if path > 1 do some I dont know
        guard path.count > 1 else { return super.item(atUUIDPath: path) }
        guard path.first == uuid else { return nil }
        
        let subsequent = path.dropFirst()
        guard let second = subsequent.first else { return nil }
        // completely don't know this shit is doing what?
        return contents.first { $0.uuid == second }.flatMap { $0.item(atUUIDPath: subsequent) }
    }
    
}
