//
//  UMountCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct UMountCommand: Command {
    
    static func execute(_ inputs: Void = ()) {
        
        print("\n~$ umount")
        FileSystemDriver.shared.umount()
        print("Successfully unmounted")
    }
}
