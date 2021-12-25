//
//  CloseCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 25.12.2021.
//

import Foundation

struct CloseCommand: Command {
    
    typealias InputType = Int
    
    static func execute(_ inputs: Int) {
        
        print("\n~$ close \(inputs)")
        FileSystemDriver.shared.closeFile(with: inputs)
        print("File with id: \(inputs) closed")
    }
}
