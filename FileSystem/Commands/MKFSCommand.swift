//
//  MKFSCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct MKFSCommand: Command {
        
    static func execute(_ numberOfDescriptors: Int) {
        print("\n~$ mkfs \(numberOfDescriptors)")
        FileSystemDriver.shared.generateDescriptors(numberOfDescriptors)
        print("\(numberOfDescriptors) descriptors generated")
    }
}
