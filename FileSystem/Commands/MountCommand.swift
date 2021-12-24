//
//  MountCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct MountCommand: Command {
    
    static func execute(_ inputs: Void = ()) {
        
        print("\n~$ mount")
        FileSystemDriver.shared.mountFromMemory()
        print("Successfully mounted")
    }
}
