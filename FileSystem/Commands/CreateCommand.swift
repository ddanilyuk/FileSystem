//
//  CreateCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct CreateCommand: Command {
    
    typealias InputType = String
    
    static func execute(_ name: String) {
        
        print("\n~$ touch \(name)")
        let rootDirectory = FileSystemDriver.shared.rootDirectory
        FileSystemDriver.shared.createFile(with: name, in: rootDirectory)
        print("File successfully created")
    }
}
