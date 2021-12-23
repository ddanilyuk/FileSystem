//
//  main.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

print("Hello, World!")


MountCommand().execute(inputs: MountCommand.Input(name: "Hi every "))

FileSystemDriver.shared.mountFromMemory()
FileSystemDriver.shared.generateDescriptors(10)
FileSystemDriver.shared.createFile(
    with: "Test file",
    in: FileSystemDriver.shared.rootDirectory
)

let ls = FileSystemDriver.shared.ls()
Logger.shared.logLSCommand(ls)



extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


extension String {
    
    func padding(_ length: Int) -> String {
        return padding(toLength: length, withPad: " ", startingAt: 0)
    }
}
