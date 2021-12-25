//
//  CloseCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 25.12.2021.
//

import Foundation

struct CloseCommand: Command {
        
    static func execute(_ numericOpenedFileDescriptor: Int) {
        print("\n~$ close \(numericOpenedFileDescriptor)")
        FileSystemDriver.shared.closeFile(with: numericOpenedFileDescriptor)
        print("File with id: \(numericOpenedFileDescriptor) closed")
    }
}
