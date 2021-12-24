//
//  OpenCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct OpenCommand: Command {
    
    typealias InputType = String
    
    static func execute(_ inputs: String) -> Int {
        
        print("\n~$ open")
        let result = FileSystemDriver.shared.openFile(with: inputs)
        print("File opened with id: \(result)")
        print("")
        return result
    }
}
