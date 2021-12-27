//
//  UMountCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct UMountCommand: Command {
    
    static func execute(_ inputs: Void = ()) {
        print("\n\(Path.currentPath)$ umount")
        FileSystem.umount()
        print("Successfully unmounted")
    }
}
