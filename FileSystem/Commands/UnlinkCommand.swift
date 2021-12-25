//
//  UnlinkCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 25.12.2021.
//

import Foundation

struct UnlinkCommand: Command {
    
    typealias InputType = String
    
    static func execute(_ name: InputType) {
        
        print("\n~$ unlink \(name)")
        FileSystemDriver.shared.unlink(name: name)
        print("File with name \(name) unlinked")
    }
}
