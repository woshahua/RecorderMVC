//
//  Store.swift
//  RecorderMVC
//
//  Created by Hang Gao on 2020/04/27.
//  Copyright © 2020 Hang Gao. All rights reserved.
//

import Foundation

final class Store {
    static let changedNotification = Notification.Name("storeChanged")
    // create file ?
    static private let documentDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    // share the file path
    static let shared = Store(url: documentDirectory)
    
    let baseURL: URL?
    var placeholder: URL?
    // this must exist ?
    private(set) var rootFolder: Folder
    
    init(url: URL?) {
        self.baseURL = url
        self.placeholder = nil
        
        // get path
        // path + save file location
        if let u = url,
            let data = try? Data(contentsOf: u.appendingPathComponent(.storeLocation)),
            let folder = try? JSONDecoder().decode(Folder.self, from: data)
            {
                self.rootFolder = folder
            } else {
            // if it's nil create one
            self.rootFolder = Folder(name: "", uuid: UUID())
        }
    }
    
    func fileURL(for recording: Recording) -> URL? {
        // exports is not hold by the file ?
        return baseURL?.appendingPathComponent(recording.uuid.uuidString + ".m4a") ?? placeholder
    }
    
    func save(_ notifying: Item, userInfo: [AnyHashable: Any]) {
        if let url = baseURL, let data = try? JSONEncoder().encode(rootFolder) {
            try! data.write(to: url.appendingPathComponent(.storeLocation))
            // error handling ommitted
        }
        // if file is saved send notification
        NotificationCenter.default.post(name: Store.changedNotification, object: notifying, userInfo: userInfo)
    }
    
    func item(atUUIDPath path: [UUID]) -> Item? {
        return rootFolder.item(atUUIDPath: path[0...])
    }
    
    // dont need remove folder ?
    func removeFile(for recording: Recording) {
        if let url = fileURL(for: recording), url != placeholder {
            _ = try? FileManager.default.removeItem(at: url)
        }
    }
}


// for the file path, cause it's only used inside here, so set to fileprivate
fileprivate extension String {
    static let storeLocation = "store.json"
}
