//
//  CreateCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct CreateCommand: Command {
        
    static func execute(_ name: String) {
        print("\n~$ touch \(name)")
        FileSystem.createFile(with: name)
        print("File successfully created")
    }
}
