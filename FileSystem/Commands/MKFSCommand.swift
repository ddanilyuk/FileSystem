//
//  MKFSCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct MKFSCommand: Command {
    
    typealias InputType = Int
    
    static func execute(_ inputs: InputType) {
        
        FileSystemDriver.shared.generateDescriptors(inputs)
        print("Descriptors generated")
    }
}
